// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/client_services/client_services.dart';
import 'package:huts_web/core/services/fares/job_fare_service.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/widgets/general/date_time_picker.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/company.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/requests/data/models/event_model.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/display/screens/widgets/admin/request_historical.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/services/employee_services/employee_availability_service.dart';
import '../../../../../../core/services/employee_services/employee_services.dart';
import '../../../../../../core/services/navigation_service.dart';
import '../../../../../../core/utils/ui/ui_methods.dart';
import '../../../../../../core/utils/ui/widgets/employees/employee_selection/dialog.dart';
import '../../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../employees/domain/entities/employee_entity.dart';
import '../../../../../general_info/display/providers/general_info_provider.dart';
import '../../../../domain/entities/event_entity.dart';
import '../../../providers/create_event_provider.dart';

class AdminRequestAction {
  static Future<void> showActionDialog({
    required String type,
    required requestIndex,
    required GetRequestsProvider provider,
  }) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    GetRequestsProvider requestsProvider =
        Provider.of<GetRequestsProvider>(globalContext, listen: false);
    Request request = (requestsProvider.adminRequestsType == "by-event")
        ? requestsProvider.filteredRequests[requestIndex]
        : requestsProvider.adminFilteredRequests[requestIndex];
    await requestsProvider.getActiveEvents(
      request.clientInfo.id,
      globalContext,
    );
    //When the request events is already finished//
    if (requestsProvider.activeClientEvents.isEmpty ||
        requestsProvider.activeClientEvents
            .every((element) => element.id != request.eventId)) {
      //TODO: Move this DB Query to a optimal place
      DocumentSnapshot doc = await FirebaseServices.db
          .collection("events")
          .doc(request.eventId)
          .get();

      requestsProvider.activeClientEvents.add(
        EventModel.fromMap(doc.data() as Map<String, dynamic>),
      );
    }

    showDialog(
        context: globalContext,
        barrierDismissible: false,
        builder: (_) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              scrollable: false,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(15),
                ),
              ),
              titlePadding: const EdgeInsets.all(0),
              title: _DialogContent(
                actionType: type,
                requestIndex: requestIndex,
                requestsProvider: provider,
              ),
            ),
          );
        });
  }
}

class _DialogContent extends StatefulWidget {
  final String actionType;
  final GetRequestsProvider requestsProvider;
  final int requestIndex;
  const _DialogContent({
    required this.actionType,
    Key? key,
    required this.requestsProvider,
    required this.requestIndex,
  }) : super(key: key);
  @override
  State<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<_DialogContent> {
  late GeneralInfoProvider generalInfoProvider;
  late EmployeesProvider employeesProvider;
  late GetRequestsProvider requestsProvider;
  late ScreenSize screenSize;
  late Request request;
  TextEditingController employeeSearchController = TextEditingController();
  bool isWidgetLoaded = false;
  bool firstBuild = false;
  int selectedEmployeeIndex = -1;
  RequestEmployeeInfo selectedEmployee =
      RequestEmployeeInfo("", "", "", "", "", "", "");

  List<Map<String, dynamic>> systemJobs = [];
  List<Map<String, dynamic>> employeeJobs = [];

  List<Map<String, dynamic>> requestsStatus = [
    {"name": "Pendiente", "value": 0},
    {"name": "Asignada", "value": 1},
    {"name": "Aceptada", "value": 2},
    {"name": "Activa", "value": 3},
    {"name": "Finalizada", "value": 4},
    {"name": "Cancelada", "value": 5},
    {"name": "Rechazada", "value": 6},
  ];

  Map<String, dynamic> selectedStatus = {};
  Map<String, dynamic> selectedEventMap = {};
  Map<String, dynamic> selectedJobMap = {};

  DateTime selectedStartDate = DateTime.now();
  DateTime selectedEndDate = DateTime.now();

  bool useClientFare = true;

  TextEditingController clientFareController = TextEditingController();
  TextEditingController clientNightSurchargeController =
      TextEditingController();
  TextEditingController employeeNightSurchargeController =
      TextEditingController();
  TextEditingController employeeFareController = TextEditingController();
  TextEditingController indicactionsController = TextEditingController();
  TextEditingController referencesController = TextEditingController();
  TextEditingController newEventNameController = TextEditingController();

  Event? selectedEvent;
  double totalHours = 0;
  double totalClientPays = 0;
  double totalToPayEmployee = 0;
  JobRequest? newJobRequest;

  bool isEventSelected = true;

  Timer? _debounceTimer;
  @override
  void initState() {
    super.initState();
    clientFareController.addListener(_printLatestValue);
    employeeFareController.addListener(_printLatestValue);
  }

  @override
  void dispose() {
    clientFareController.dispose();
    employeeFareController.dispose();
    super.dispose();
  }

  _printLatestValue() async {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(
      const Duration(milliseconds: 1300),
      () async {
        // print("Second text field: ${clientFareController.text}");
        if ((employeeFareController.text !=
                    "${CodeUtils.getRequestFarePerHour(request: request, isClient: false, hours: totalHours)}" ||
                clientFareController.text !=
                    "${CodeUtils.getRequestFarePerHour(request: request, isClient: true, hours: totalHours)}") &&
            !useClientFare) {
          await _getNewFare();

          clientFareController.text = ((newJobRequest!.totalToPayClient -
                      newJobRequest!.totalClientNightSurcharge) /
                  totalHours)
              .toStringAsFixed(0);

          employeeFareController.text = ((newJobRequest!.totalToPayEmployee -
                      newJobRequest!.totalEmployeeNightSurcharge) /
                  totalHours)
              .toStringAsFixed(0);

          employeeNightSurchargeController.text =
              newJobRequest!.totalEmployeeNightSurcharge.toStringAsFixed(0);

          clientNightSurchargeController.text =
              newJobRequest!.totalClientNightSurcharge.toStringAsFixed(0);

          totalClientPays =
              (newJobRequest!.totalToPayClient).round().toDouble();
          totalToPayEmployee =
              (newJobRequest!.totalToPayEmployee).round().toDouble();
          setState(() {});
        }
      },
    );
  }

  @override
  void didChangeDependencies() async {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    employeesProvider = Provider.of<EmployeesProvider>(context);
    requestsProvider = Provider.of<GetRequestsProvider>(context);

    systemJobs = List<Map<String, dynamic>>.from(
      generalInfoProvider.generalInfo.countryInfo.jobsFares.values
          .map(
            (item) => {
              "name": item["name"],
              "value": item["value"],
            },
          )
          .toList(),
    );

    // selectedJobMap = systemJobs.first;

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted && selectedEmployee.id.isNotEmpty) {
      employeeJobs =
          await EmployeeServices.getJobs(selectedEmployee.id, context);
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    _setInitialValues();
    return Container(
      width: widget.actionType == "history"
          ? screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.85
              : screenSize.blockWidth
          : screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.65
              : screenSize.blockWidth * 0.8,
      height: screenSize.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
            ),
            height: screenSize.height * 0.75,
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: Container(
                margin: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: screenSize.height * 0.09,
                ),
                child: _buildBody(),
              ),
            ),
          ),
          _buildHeader(context),
          _buildFooter(),
        ],
      ),
    );
  }

  Column _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.actionType == "edit")
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildJobInfo(),
              const SizedBox(height: 30),
              _buildEmployeeSelection(),
              const SizedBox(height: 30),
              _buildDates(),
              if (context
                  .read<AuthProvider>()
                  .webUser
                  .clientAssociationInfo
                  .isEmpty)
                _buildFare(),
              const SizedBox(height: 30),
              _buildOtherInfo(),
              const SizedBox(height: 30),
            ],
          ),
        if (widget.actionType == "history")
          RequestHistorical(requestId: request.id)
      ],
    );
  }

  Column _buildOtherInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTotalFareInfo(),
        const SizedBox(height: 20),
        Text(
          "Otra información",
          style: TextStyle(fontSize: screenSize.blockWidth >= 920 ? 17 : 14),
        ),
        const SizedBox(height: 20),
        _buildIndicationsField(),
        const SizedBox(height: 20),
        Text(
          "Mover solicitud",
          style: TextStyle(
            fontSize: screenSize.blockWidth >= 920 ? 17 : 14,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            ChoiceChip(
              onSelected: (bool newValue) {
                setState(() {
                  isEventSelected = newValue;
                });
              },
              backgroundColor: Colors.white,
              label: Text(
                "Elegir evento",
                style: TextStyle(
                  color: isEventSelected ? Colors.white : Colors.black,
                  fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                      ? 14
                      : 11,
                ),
              ),
              selected: isEventSelected,
              elevation: 2,
              selectedColor: UiVariables.primaryColor,
            ),
            const SizedBox(width: 30),
            ChoiceChip(
              onSelected: (bool newValue) {
                setState(() {
                  isEventSelected = !newValue;
                });
              },
              backgroundColor: Colors.white,
              label: Text(
                "Nuevo Evento",
                style: TextStyle(
                  color: !isEventSelected ? Colors.white : Colors.black,
                  fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                      ? 14
                      : 11,
                ),
              ),
              selected: !isEventSelected,
              elevation: 2,
              selectedColor: UiVariables.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (!isEventSelected) _buildNameNewEvent(),
        if (isEventSelected) _buildEventSelection(),
      ],
    );
  }

  Widget _buildTotalFareInfo() {
    return OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      overflowSpacing: 10,
      overflowAlignment: OverflowBarAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Total horas",
              style: TextStyle(
                color: Colors.grey,
                fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 14, left: 10),
              margin: const EdgeInsets.only(top: 8),
              width: screenSize.blockWidth >= 920
                  ? screenSize.blockWidth * 0.15
                  : screenSize.blockWidth,
              height: screenSize.height * 0.056,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 2,
                      color: Colors.black26,
                      offset: Offset(2, 2))
                ],
              ),
              child: Text(
                "$totalHours",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                ),
              ),
            )
          ],
        ),
        if (context.read<AuthProvider>().webUser.clientAssociationInfo.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total cliente",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 14, left: 10),
                margin: const EdgeInsets.only(top: 8),
                width: screenSize.blockWidth >= 920
                    ? screenSize.blockWidth * 0.15
                    : screenSize.blockWidth,
                height: screenSize.height * 0.056,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        blurRadius: 2,
                        color: Colors.black26,
                        offset: Offset(2, 2))
                  ],
                ),
                child: Text(
                  totalClientPays.toStringAsFixed(0),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                  ),
                ),
              )
            ],
          ),
        if (context.read<AuthProvider>().webUser.clientAssociationInfo.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total colaborador",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 14, left: 10),
                margin: const EdgeInsets.only(top: 8),
                width: screenSize.blockWidth >= 920
                    ? screenSize.blockWidth * 0.15
                    : screenSize.blockWidth,
                height: screenSize.height * 0.056,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        blurRadius: 2,
                        color: Colors.black26,
                        offset: Offset(2, 2))
                  ],
                ),
                child: Text(
                  "$totalToPayEmployee",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                  ),
                ),
              )
            ],
          ),
      ],
    );
  }

  Column _buildNameNewEvent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Nombre del evento",
          style: TextStyle(
            color: Colors.grey,
            fontSize:
                generalInfoProvider.screenSize.blockWidth >= 920 ? 14 : 11,
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          height: screenSize.height * 0.056,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  blurRadius: 2, color: Colors.black26, offset: Offset(2, 2))
            ],
          ),
          child: TextField(
            style: TextStyle(
              color: Colors.black87,
              fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
            ),
            cursorColor: UiVariables.primaryColor,
            controller: newEventNameController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Column _buildEventSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Evento",
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 5, left: 10),
          margin: const EdgeInsets.only(top: 10),
          width:
              // screenSize.blockWidth >= 920
              // ? screenSize.blockWidth * 0.2
              // :
              double.infinity,
          height: generalInfoProvider.screenSize.height * 0.07,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  blurRadius: 2, color: Colors.black26, offset: Offset(2, 2))
            ],
          ),
          child: DropdownSearch<Map<String, dynamic>>(
            mode: Mode.MENU,
            items: getEventsItems(),
            selectedItem: selectedEventMap,
            maxHeight: 200,
            itemAsString: (item) => item == null ? '' : item.values.first,
            onChanged: (Map<String, dynamic>? newValue) {
              if (newValue == null) return;
              selectedEventMap = newValue;

              selectedEvent =
                  widget.requestsProvider.activeClientEvents.firstWhere(
                (element) => element.id == selectedEventMap.keys.first,
              );

              setState(() {});
            },
            emptyBuilder: (context, searchEntry) => const Center(
              child: Text('No se encontraron eventos'),
            ),
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              cursorColor: UiVariables.primaryColor,
            ),
            dropdownSearchDecoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Seleccione evento',
              hintStyle: TextStyle(
                color: Colors.black54,
                fontSize:
                    generalInfoProvider.screenSize.blockWidth >= 920 ? 12 : 9,
              ),
            ),
          ),
        )
      ],
    );
  }

  Column _buildIndicationsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Indicaciones",
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          width:
              //  screenSize.blockWidth >= 920
              // ? screenSize.blockWidth * 0.23
              // :
              screenSize.blockWidth,
          height: screenSize.height * 0.056,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  blurRadius: 2, color: Colors.black26, offset: Offset(2, 2))
            ],
          ),
          child: TextField(
            style: TextStyle(
              color: Colors.black87,
              fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
            ),
            cursorColor: UiVariables.primaryColor,
            controller: indicactionsController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              border: InputBorder.none,
            ),
          ),
        )
      ],
    );
  }

  Column _buildFare() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.start,
          overflowSpacing: 10,
          children: [
            Text(
              "Tarifa de la solicitud: ${request.details.fare.type}",
              style:
                  TextStyle(fontSize: screenSize.blockWidth >= 920 ? 17 : 14),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Asignar tarifa manual",
                  style: TextStyle(
                      fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.65,
                  child: CupertinoSwitch(
                    activeColor: UiVariables.primaryColor,
                    value: !useClientFare,
                    onChanged: (bool newValue) {
                      setState(
                        () {
                          useClientFare = !newValue;
                          if (useClientFare) {
                            double newClientFare =
                                CodeUtils.getRequestFarePerHour(
                              request: request,
                              isClient: true,
                            );
                            clientFareController.text = "$newClientFare";
                            double newEmployeeFare =
                                CodeUtils.getRequestFarePerHour(
                              request: request,
                              isClient: false,
                            );
                            clientNightSurchargeController.text =
                                '${request.details.fare.totalClientNightSurcharge}';
                            employeeNightSurchargeController.text =
                                '${request.details.fare.totalEmployeeNightSurcharge}';
                            employeeFareController.text = "$newEmployeeFare";
                            totalToPayEmployee = newEmployeeFare * totalHours;
                            totalClientPays = newClientFare * totalHours;
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.start,
          overflowSpacing: 10,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tarifa cliente",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: screenSize.blockWidth >= 920
                      ? screenSize.blockWidth * 0.12
                      : screenSize.blockWidth,
                  height: screenSize.height * 0.056,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          blurRadius: 2,
                          color: Colors.black26,
                          offset: Offset(2, 2))
                    ],
                  ),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                      color: (!useClientFare) ? Colors.black : Colors.grey,
                    ),
                    enabled: !useClientFare,
                    cursorColor: UiVariables.primaryColor,
                    controller: clientFareController,
                    // onChanged: (String newValue) {
                    //   if (newValue.isEmpty) return;
                    //   setState(
                    //     () {
                    //       totalClientPays = double.parse(
                    //           (double.parse(newValue) * totalHours)
                    //               .toStringAsFixed(0));
                    //     },
                    //   );
                    // },
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      border: InputBorder.none,
                    ),
                  ),
                )
              ],
            ),
            _buildClientNightSurcharge(),
            _buildEmployeeFare(),
            _buildEmployeeNightSurcharge(),
          ],
        )
      ],
    );
  }

  Column _buildEmployeeFare() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tarifa colaborador",
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.12
              : screenSize.blockWidth,
          height: screenSize.height * 0.056,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  blurRadius: 2, color: Colors.black26, offset: Offset(2, 2))
            ],
          ),
          child: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
                fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                color: (!useClientFare) ? Colors.black : Colors.grey),
            enabled: !useClientFare,
            cursorColor: UiVariables.primaryColor,
            controller: employeeFareController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              border: InputBorder.none,
            ),
            // onChanged: (String newValue) {
            //   if (newValue.isEmpty) return;

            //   setState(() {
            //     totalToPayEmployee = double.parse(newValue) * totalHours;
            //   });
            // },
          ),
        )
      ],
    );
  }

  Column _buildDates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fechas de la solicitud",
          style: TextStyle(fontSize: screenSize.blockWidth >= 920 ? 17 : 14),
        ),
        const SizedBox(height: 20),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.start,
          overflowSpacing: 10,
          children: [
            _buildStartDate(),
            _buildEndDate(),
          ],
        )
      ],
    );
  }

  Column _buildStartDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Inicio",
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
          ),
        ),
        InkWell(
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            width: screenSize.blockWidth >= 920
                ? screenSize.blockWidth * 0.25
                : screenSize.blockWidth,
            height: screenSize.height * 0.056,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    blurRadius: 2, color: Colors.black26, offset: Offset(2, 2))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  CodeUtils.formatDate(selectedStartDate),
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                  ),
                ),
              ),
            ),
          ),
          onTap: () async {
            DateTime? startDateResp = await DateTimePickerDialog.show(
              screenSize,
              true,
              selectedStartDate, // null,
              null,
            );
            if (startDateResp == null) return;

            if (selectedEndDate.isBefore(startDateResp)) {
              LocalNotificationService.showSnackBar(
                type: "fail",
                message: "La fecha de inicio debe ser menor a la de fin",
                icon: Icons.error_outline_outlined,
              );
              return;
            }

            if (selectedEndDate.difference(startDateResp).inHours > 24) {
              LocalNotificationService.showSnackBar(
                type: "fail",
                message: "El turno debe durar máximo 24 horas",
                icon: Icons.error_outline_outlined,
              );
              return;
            }

            selectedStartDate = DateTime(
              startDateResp.year,
              startDateResp.month,
              startDateResp.day,
              startDateResp.hour,
              startDateResp.minute,
            );
            totalHours = CodeUtils.minutesToHours(
                selectedEndDate.difference(selectedStartDate).inMinutes);

            // if (useClientFare) {

            await _getNewFare();
            clientFareController.text = ((newJobRequest!.totalToPayClient -
                        newJobRequest!.totalClientNightSurcharge) /
                    totalHours)
                .toStringAsFixed(0);

            employeeFareController.text = ((newJobRequest!.totalToPayEmployee -
                        newJobRequest!.totalEmployeeNightSurcharge) /
                    totalHours)
                .toStringAsFixed(0);

            employeeNightSurchargeController.text =
                newJobRequest!.totalEmployeeNightSurcharge.toStringAsFixed(0);

            clientNightSurchargeController.text =
                newJobRequest!.totalClientNightSurcharge.toStringAsFixed(0);
            // }

            totalClientPays = newJobRequest!.totalToPayClient;
            //double.parse(clientFareController.text) * totalHours;
            totalToPayEmployee = newJobRequest!.totalToPayEmployee;
            //   double.parse(employeeFareController.text) * totalHours;

            setState(() {});
          },
        ),
      ],
    );
  }

  Column _buildEndDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fin",
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
          ),
        ),
        InkWell(
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            width: screenSize.blockWidth >= 920
                ? screenSize.blockWidth * 0.25
                : screenSize.blockWidth,
            height: screenSize.height * 0.056,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    blurRadius: 2, color: Colors.black26, offset: Offset(2, 2))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  CodeUtils.formatDate(selectedEndDate),
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                  ),
                ),
              ),
            ),
          ),
          onTap: () async {
            DateTime? endDateResp = await DateTimePickerDialog.show(
              screenSize,
              true,
              selectedEndDate, // null,
              null,
            );
            if (endDateResp == null) return;

            if (endDateResp.isBefore(selectedStartDate)) {
              LocalNotificationService.showSnackBar(
                type: "fail",
                message: "La fecha de fin debe ser mayor a la de inicio",
                icon: Icons.error_outline_outlined,
              );
              return;
            }

            selectedEndDate = DateTime(
              endDateResp.year,
              endDateResp.month,
              endDateResp.day,
              endDateResp.hour,
              endDateResp.minute,
            );
            totalHours = CodeUtils.minutesToHours(
              selectedEndDate.difference(selectedStartDate).inMinutes,
            );

            // if (useClientFare) {
            await _getNewFare();
            clientFareController.text = ((newJobRequest!.totalToPayClient -
                        newJobRequest!.totalClientNightSurcharge) /
                    totalHours)
                .toStringAsFixed(0);
            employeeFareController.text = ((newJobRequest!.totalToPayEmployee -
                        newJobRequest!.totalEmployeeNightSurcharge) /
                    totalHours)
                .toStringAsFixed(0);

            employeeNightSurchargeController.text =
                newJobRequest!.totalEmployeeNightSurcharge.toStringAsFixed(0);

            clientNightSurchargeController.text =
                newJobRequest!.totalClientNightSurcharge.toStringAsFixed(0);
            // }

            totalClientPays = newJobRequest!.totalToPayClient;
            //   double.parse(clientFareController.text) * totalHours;
            totalToPayEmployee = newJobRequest!.totalToPayEmployee;
            //  double.parse(employeeFareController.text) * totalHours;
            setState(() {});
          },
        ),
      ],
    );
  }

  Column _buildEmployeeSelection() {
    String employeeNames = "";
    String employeeLastNames = "";

    if (selectedEmployee.names == "") {
      employeeNames = "Aún no se ha asignado un colaborador";
      employeeLastNames = "para esta solicitud";
    } else {
      employeeNames = selectedEmployee.names;
      employeeLastNames = selectedEmployee.lastNames;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Colaborador asignado",
          style: TextStyle(fontSize: screenSize.blockWidth >= 920 ? 17 : 14),
        ),
        const SizedBox(height: 20),
        OverflowBar(
          alignment: MainAxisAlignment.center,
          overflowSpacing: 10,
          overflowAlignment: OverflowBarAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 20),
                  width: screenSize.blockWidth * 0.06,
                  height: screenSize.blockWidth * 0.06,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: (selectedEmployee.imageUrl.isEmpty)
                      ? Icon(
                          Icons.hide_image_outlined,
                          size: screenSize.blockWidth * 0.06,
                          color: Colors.grey,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            selectedEmployee.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeNames,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: Colors.grey,
                        fontSize: screenSize.blockWidth >= 920 ? 16 : 11.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      employeeLastNames,
                      style: TextStyle(
                          fontSize: screenSize.blockWidth >= 920 ? 16 : 11.5,
                          color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            InkWell(
              onTap: () async {
                if (request.details.status == 5) {
                  return;
                }

                UiMethods().showLoadingDialog(context: context);
                List<Employee>? gottenEmployees =
                    await EmployeeServices.getClientEmployees(
                  request.clientInfo.id,
                  requestData: {
                    "start_date": request.details.startDate,
                    "end_date": request.details.endDate,
                  },
                );

                if (mounted) UiMethods().hideLoadingDialog(context: context);

                if (gottenEmployees == null) return;

                if (request.employeeInfo.id != "") {
                  gottenEmployees.removeWhere(
                      (element) => element.id == request.employeeInfo.id);
                }

                List<Employee> requestJobEmployees = gottenEmployees
                    .where(
                      (Employee gottenEmployee) => gottenEmployee.jobs.contains(
                        selectedJobMap["value"],
                      ),
                    )
                    .toList();

                List<Employee?> selectedDialogEmployees =
                    await EmployeeSelectionDialog.show(
                  employees: requestJobEmployees,
                  indexesList: employeesProvider.locksOrFavsToEditIndexes,
                  isAddFavOrLocks: false,
                );

                if (selectedDialogEmployees.isEmpty) return;

                selectedEmployee = RequestEmployeeInfo(
                  selectedDialogEmployees.first!.profileInfo.docType,
                  selectedDialogEmployees.first!.profileInfo.docNumber,
                  selectedDialogEmployees.first!.profileInfo.image,
                  selectedDialogEmployees.first!.profileInfo.names,
                  selectedDialogEmployees.first!.profileInfo.lastNames,
                  selectedDialogEmployees.first!.profileInfo.phone,
                  selectedDialogEmployees.first!.id,
                );
                setState(() {});
              },
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  height: screenSize.blockWidth >= 920
                      ? screenSize.height * 0.04
                      : screenSize.height * 0.05,
                  width: screenSize.blockWidth >= 920
                      ? screenSize.blockWidth * 0.12
                      : screenSize.blockWidth,
                  decoration: BoxDecoration(
                    color:
                        //  (request.details.status < 3)
                        // ?
                        UiVariables.primaryColor,
                    // : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      (selectedEmployee.names == "")
                          ? "Agregar Colaborador"
                          : "Cambiar colaborador",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: screenSize.blockWidth >= 920 ? 16 : 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Container _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: screenSize.blockWidth >= 920 ? 60 : 50,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                if (widget.actionType == "history") {
                  widget.requestsProvider.selectedRequestChanges.clear();
                }
                widget.requestsProvider.activeClientEvents.clear();
              },
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: screenSize.width * 0.02,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Editar solicitud: ${request.employeeInfo.names}",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: screenSize.blockWidth >= 920 ? 18 : 14),
                ),
                // const SizedBox(width: 5),
                // Text(
                //   "Id: ${request.id}",
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontSize: screenSize.blockWidth >= 920 ? 12 : 10,
                //   ),
                // )
              ],
            )
          ],
        ),
      ),
    );
  }

  Column _buildJobInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cargo y estado de la solicitud",
          style: TextStyle(fontSize: screenSize.blockWidth >= 920 ? 17 : 14),
        ),
        const SizedBox(height: 20),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.start,
          overflowSpacing: 10,
          children: [
            _buildJobSelection(),
            _buildStatusSelection(),
          ],
        ),
      ],
    );
  }

  Column _buildStatusSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Estado",
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          margin: const EdgeInsets.only(top: 10, right: 10),
          width: screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.25
              : screenSize.blockWidth,
          height: screenSize.height * 0.07,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                offset: Offset(0, 2),
                color: Colors.black26,
                blurRadius: 2,
              )
            ],
          ),
          child: DropdownButton<int>(
            onTap: () => FocusScope.of(context).unfocus(),
            underline: const SizedBox(),
            value: selectedStatus["value"],
            isExpanded: true,
            menuMaxHeight: 400,
            items: requestsStatus.map<DropdownMenuItem<int>>(
              (Map<String, dynamic> job) {
                return DropdownMenuItem(
                  value: job["value"],
                  child: Text(
                    job["name"],
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                    ),
                  ),
                );
              },
            ).toList(),
            onChanged: (int? newValue) {
              selectedStatus = requestsStatus.firstWhere(
                (element) => element["value"] == newValue,
              );
              if (selectedStatus["value"] == 0) {
                selectedEmployee =
                    RequestEmployeeInfo("", "", "", "", "", "", "");
              }
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Column _buildJobSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cargo",
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          margin: const EdgeInsets.only(top: 10, right: 10),
          width: screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.25
              : screenSize.blockWidth,
          height: screenSize.height * 0.07,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                offset: Offset(0, 2),
                color: Colors.black26,
                blurRadius: 2,
              )
            ],
          ),
          child: DropdownSearch<Map<String, dynamic>>(
            mode: Mode.MENU,
            items: getJobsItems(),
            selectedItem: selectedJobMap,
            itemAsString: (item) => item == null ? '' : item['name'],
            maxHeight: 200,
            onChanged: (Map<String, dynamic>? newValue) async {
              if (newValue == null) return;
              selectedJobMap = newValue;
              // selectedJob = systemJobs.firstWhere(
              //   (element) => element["value"] == newValue,
              // );

              if (!employeeJobs.contains(selectedJobMap)) {
                selectedEmployee =
                    RequestEmployeeInfo("", "", "", "", "", "", "");
              }

              if (useClientFare) {
                await _getNewFare();
                clientFareController.text = ((newJobRequest!.totalToPayClient -
                            newJobRequest!.totalClientNightSurcharge) /
                        totalHours)
                    .toStringAsFixed(0);

                employeeFareController.text =
                    ((newJobRequest!.totalToPayEmployee -
                                newJobRequest!.totalEmployeeNightSurcharge) /
                            totalHours)
                        .toStringAsFixed(0);
                employeeNightSurchargeController.text = newJobRequest!
                    .totalEmployeeNightSurcharge
                    .toStringAsFixed(0);

                clientNightSurchargeController.text =
                    newJobRequest!.totalClientNightSurcharge.toStringAsFixed(0);
              }

              totalClientPays = newJobRequest!.totalToPayClient;
              totalToPayEmployee = newJobRequest!.totalToPayEmployee;
              setState(() {});
            },
            showSearchBox: true,
            emptyBuilder: (context, searchEntry) => const Center(
              child: Text('No se encontraron cargos'),
            ),
            searchFieldProps: TextFieldProps(
              cursorColor: UiVariables.primaryColor,
            ),
            dropdownSearchDecoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Seleccione cargo',
              hintStyle: TextStyle(
                color: Colors.black54,
                fontSize:
                    generalInfoProvider.screenSize.blockWidth >= 920 ? 12 : 9,
              ),
            ),
          ),

          // DropdownButton<String>(
          //    onTap: () => FocusScope.of(context).unfocus(),
          //   underline: const SizedBox(),
          //   value: selectedJob["value"],
          //   isExpanded: true,
          //   menuMaxHeight: 400,
          //   items: systemJobs.map<DropdownMenuItem<String>>(
          //     (Map<String, dynamic> job) {
          //       return DropdownMenuItem(
          //         value: job["value"],
          //         child: Text(
          //           job["name"],
          //           style: TextStyle(
          //             color: Colors.black87,
          //             fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
          //           ),
          //         ),
          //       );
          //     },
          //   ).toList(),
          //   onChanged: (String? newValue) async {
          //     selectedJob = systemJobs.firstWhere(
          //       (element) => element["value"] == newValue,
          //     );

          //     if (!employeeJobs.contains(selectedJob)) {
          //       selectedEmployee =
          //           RequestEmployeeInfo("", "", "", "", "", "", "");
          //     }

          //     if (useClientFare) {
          //       await _getNewFare();
          //     }

          //     setState(() {});
          //   },
          // ),
        ),
      ],
    );
  }

  void _setInitialValues() {
    screenSize = generalInfoProvider.screenSize;
    request = (widget.requestsProvider.adminRequestsType == "by-event")
        ? widget.requestsProvider.filteredRequests[widget.requestIndex]
        : widget.requestsProvider.adminFilteredRequests[widget.requestIndex];
    selectedEvent ??= widget.requestsProvider.activeClientEvents.firstWhere(
      (element) => element.id == request.eventId,
    );
    selectedEventMap = {
      selectedEvent!.id:
          '${selectedEvent!.eventName}: ${CodeUtils.formatDate(selectedEvent!.details.startDate)}'
    };
    if (!firstBuild) {
      firstBuild = true;
      clientNightSurchargeController.text =
          CodeUtils.getRequestNightSurcharge(request: request, isClient: true)
              .toStringAsFixed(0);
      employeeNightSurchargeController.text =
          CodeUtils.getRequestNightSurcharge(request: request, isClient: false)
              .toStringAsFixed(0);
      totalHours = request.details.totalHours;
      selectedJobMap = request.details.job;
      selectedStatus = requestsStatus
          .where((element) => element["value"] == request.details.status)
          .toList()
          .first;
      selectedStartDate = request.details.startDate;
      selectedEndDate = request.details.endDate;
      employeeSearchController.text = "";
      clientFareController.text =
          "${CodeUtils.getRequestFarePerHour(request: request, isClient: true, hours: totalHours)}";
      employeeFareController.text =
          "${CodeUtils.getRequestFarePerHour(request: request, isClient: false, hours: totalHours)}";
      indicactionsController.text = request.details.indications;
      totalToPayEmployee =
          request.details.fare.totalToPayEmployee.roundToDouble();
      totalClientPays = request.details.fare.totalClientPays.roundToDouble();
      if (request.employeeInfo.names.isNotEmpty) {
        selectedEmployee = request.employeeInfo;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Positioned _buildFooter() {
    return Positioned(
      bottom: 20,
      right: 30,
      child: (widget.actionType == "edit") ? _buildSaveBtn() : const SizedBox(),
    );
  }

  InkWell _buildSaveBtn() {
    return InkWell(
      onTap: () async {
        if (!_validateEditFields()) return;

        Map<String, dynamic> updateMap = {"new_data": {}};
        updateMap["previous_request"] = request;
        double decrementTotalHours = 0;
        double decrementTotalClientPays = 0;
        double decrementTotalToPayEmployees = 0;

        updateMap["new_event"] = selectedEvent;

        updateMap["new_data"]["employee_info"] = (selectedEmployee.id != "")
            ? {
                "doc_number": selectedEmployee.docNumber,
                "doc_type": selectedEmployee.docType,
                "id": selectedEmployee.id,
                "last_names": selectedEmployee.lastNames,
                "names": selectedEmployee.names,
                "phone": selectedEmployee.phone,
                "image": selectedEmployee.imageUrl,
                "exp_date": DateTime.now().add(const Duration(hours: 2)),
              }
            : {};

        bool availableEmployee = true;

        if (updateMap["new_data"]["employee_info"].isNotEmpty &&
            updateMap["new_data"]["employee_info"]["id"] !=
                request.employeeInfo.id) {
          (bool, double)? isAvailable = await EmployeeAvailabilityService.get(
            selectedStartDate,
            selectedEndDate,
            selectedEmployee.id,
          );

          if (isAvailable == null || !isAvailable.$1) availableEmployee = false;
        }

        if (!availableEmployee) {
          LocalNotificationService.showSnackBar(
            type: "fail",
            message:
                "Una de las solicitudes del colaborador seleccionado se cruza con la actual.",
            icon: Icons.error_outline,
            duration: 7,
          );
          return;
        }

        updateMap["new_data"]["details.job"] = selectedJobMap;
        updateMap["new_data"]["details.status"] =
            (selectedStatus["value"] == 0 && selectedEmployee.id != "")
                ? 1
                : selectedStatus["value"];
        updateMap["new_data"]["details.start_date"] = selectedStartDate;
        updateMap["new_data"]["details.end_date"] = selectedEndDate;
        if (selectedStatus["value"] == 4) {
          updateMap["new_data"]["details.departed_date"] = DateTime.now();
          if (request.details.status < 3) {
            updateMap["new_data"]["details.arrived_date"] = DateTime.now();
          }
        }

        if (selectedStatus["value"] == 3) {
          updateMap["new_data"]["details.arrived_date"] = DateTime.now();
        }
        if (selectedStatus["value"] == 5 || selectedStatus["value"] == 6) {
          updateMap["new_data"]["details.departed_date"] = DateTime.now();
          updateMap["new_data"]["details.arrived_date"] = DateTime.now();
        }
        updateMap["new_data"]["details.indications"] =
            indicactionsController.text;
        updateMap["new_data"]["details.total_hours"] = totalHours;
        updateMap["new_data"]["year"] = selectedStartDate.year;
        updateMap["new_data"]["month"] = selectedStartDate.month;
        updateMap["new_data"]["week_start"] =
            _getWeekDateFormat(selectedStartDate);
        updateMap["new_data"]["week_end"] = _getWeekDateFormat(selectedEndDate);

        updateMap["new_data"]["event_id"] = selectedEvent!.id;
        updateMap["new_data"]["event_number"] = selectedEvent!.eventName;

        if (newJobRequest != null) {
          updateMap["new_data"]["details.fare"] = {
            "client_fare": {
              "dynamic": newJobRequest!.clientFare.dynamicFare,
              "normal": newJobRequest!.clientFare.normalFare,
              "holiday": newJobRequest!.clientFare.holidayFare,
            },
            "employee_fare": {
              "dynamic": newJobRequest!.employeeFare.dynamicFare,
              "normal": newJobRequest!.employeeFare.normalFare,
              "holiday": newJobRequest!.employeeFare.holidayFare,
            },
            "fare_type": newJobRequest!.fareType,
            "total_client_pays": newJobRequest!.totalToPayClient,
            "total_to_pay_employee": newJobRequest!.totalToPayEmployee,
            'total_client_night_surcharge':
                newJobRequest!.totalClientNightSurcharge,
            'total_employee_night_surcharge':
                newJobRequest!.totalEmployeeNightSurcharge,
          };
        } else {
          int usedFareTypesCount = 0;
          bool hasDynamicFare = false;
          bool hasNormalFare = false;
          bool hasHolidayFare = false;
          if (request.details.fare.clientFare.dynamicFare.fare > 0) {
            usedFareTypesCount++;
            hasDynamicFare = true;
          }

          if (request.details.fare.clientFare.normalFare.fare > 0) {
            usedFareTypesCount++;
            hasNormalFare = true;
          }

          if (request.details.fare.clientFare.holidayFare.fare > 0) {
            usedFareTypesCount++;
            hasHolidayFare = true;
          }

          double clientFarePerFareType = double.parse(
              (double.parse(clientFareController.text) / usedFareTypesCount)
                  .toStringAsFixed(0));
          double employeeFarePerFareType = double.parse(
              (double.parse(employeeFareController.text) / usedFareTypesCount)
                  .toStringAsFixed(0));

          double hoursPerFareType = double.parse(
              (totalHours / usedFareTypesCount).toStringAsFixed(1));

          updateMap["new_data"]["details.fare"] = {
            "client_fare": {
              "dynamic": (hasDynamicFare)
                  ? {
                      "fare": clientFarePerFareType,
                      "fare_name":
                          request.details.fare.clientFare.dynamicFare.fareName,
                      "hours": hoursPerFareType,
                      "total_to_pay": double.parse(
                          (clientFarePerFareType * hoursPerFareType)
                              .toStringAsFixed(0)),
                      "total_night_surcharge": request.details.fare.clientFare
                          .dynamicFare.totalNightSurcharge,
                    }
                  : {},
              "normal": (hasNormalFare)
                  ? {
                      "fare": clientFarePerFareType,
                      "fare_name":
                          request.details.fare.clientFare.normalFare.fareName,
                      "hours": hoursPerFareType,
                      "total_to_pay": double.parse(
                          (clientFarePerFareType * hoursPerFareType)
                              .toStringAsFixed(0)),
                      "total_night_surcharge": request.details.fare.clientFare
                          .normalFare.totalNightSurcharge,
                    }
                  : {},
              "holiday": (hasHolidayFare)
                  ? {
                      "fare": clientFarePerFareType,
                      "fare_name":
                          request.details.fare.clientFare.holidayFare.fareName,
                      "hours": hoursPerFareType,
                      "total_to_pay": double.parse(
                          (clientFarePerFareType * hoursPerFareType)
                              .toStringAsFixed(0)),
                      "total_night_surcharge": request.details.fare.clientFare
                          .dynamicFare.totalNightSurcharge,
                    }
                  : {},
            },
            "employee_fare": {
              "dynamic": (hasDynamicFare)
                  ? {
                      "fare": employeeFarePerFareType,
                      "fare_name": request
                          .details.fare.employeeFare.dynamicFare.fareName,
                      "hours": hoursPerFareType,
                      "total_to_pay": double.parse(
                          (employeeFarePerFareType * hoursPerFareType)
                              .toStringAsFixed(0)),
                      "total_night_surcharge": request.details.fare.employeeFare
                          .dynamicFare.totalNightSurcharge,
                    }
                  : {},
              "normal": (hasNormalFare)
                  ? {
                      "fare": employeeFarePerFareType,
                      "fare_name":
                          request.details.fare.employeeFare.normalFare.fareName,
                      "hours": hoursPerFareType,
                      "total_to_pay": double.parse(
                          (employeeFarePerFareType * hoursPerFareType)
                              .toStringAsFixed(0)),
                      "total_night_surcharge": request.details.fare.employeeFare
                          .normalFare.totalNightSurcharge,
                    }
                  : {},
              "holiday": (hasHolidayFare)
                  ? {
                      "fare": employeeFarePerFareType,
                      "fare_name": request
                          .details.fare.employeeFare.holidayFare.fareName,
                      "hours": hoursPerFareType,
                      "total_to_pay": double.parse(
                          (employeeFarePerFareType * hoursPerFareType)
                              .toStringAsFixed(0)),
                      "total_night_surcharge": request.details.fare.employeeFare
                          .holidayFare.totalNightSurcharge,
                    }
                  : {},
            },
            "fare_type": request.details.fare.type,
            "total_client_pays": totalClientPays,
            "total_to_pay_employee": totalToPayEmployee,
            "total_client_night_surcharge":
                request.details.fare.totalClientNightSurcharge,
            "total_employee_night_surcharge":
                request.details.fare.totalEmployeeNightSurcharge,
          };
        }
        if (!isEventSelected) {
          Map<String, dynamic> newEvent = {
            'client_info': {
              'country': 'Costa Rica',
              'id': request.clientInfo.id,
              'image': request.clientInfo.imageUrl,
              'name': request.clientInfo.name,
            },
            'details': {
              'end_date':
                  Timestamp.fromDate(updateMap["new_data"]['details.end_date']),
              'start_date': Timestamp.fromDate(
                  updateMap["new_data"]['details.start_date']),
              'total_hours': updateMap["new_data"]['details.total_hours'],
              'status': 1,
              'location': request.details.location,
              'rate': request.details.rate,
              'fare': {
                'total_client_pays': updateMap["new_data"]['details.fare']
                    ['total_client_pays'],
                'total_to_pay_employees': updateMap["new_data"]['details.fare']
                    ['total_to_pay_employee'],
              }
            },
            'employees_info': {
              'employees_accepted':
                  updateMap["new_data"]['details.status'] == 2 ||
                          updateMap["new_data"]['details.status'] == 3
                      ? 1
                      : 0,
              'employees_arrived':
                  updateMap["new_data"]['details.status'] == 3 ? 1 : 0,
              'employees_needed': 1,
              'jobs_needed': {
                request.details.job['value']: {
                  'employees': 1,
                  'name': updateMap["new_data"]['details.job']['name'],
                  'value': updateMap["new_data"]['details.job']['value'],
                  'total_hours': updateMap["new_data"]['details.total_hours'],
                },
              },
            },
            'event_number': newEventNameController.text,
            'month': updateMap["new_data"]["month"],
            'week_end': updateMap["new_data"]["week_end"],
            'year': updateMap["new_data"]['year'],
            'week_start': updateMap["new_data"]["week_start"],
            'week_cut':
                CodeUtils().getCutOffWeek(selectedEvent!.details.startDate),
            'id': ''
          };
          decrementTotalHours = request.details.totalHours;
          decrementTotalClientPays = request.details.fare.totalClientPays;
          decrementTotalToPayEmployees =
              request.details.fare.totalToPayEmployee;
          updateMap['move_request_new_event'] = newEvent;
        }
        UiMethods().showLoadingDialog(context: context);
        bool itsOk = await requestsProvider.updateRequestByAdmin(
            updateMap, isEventSelected);

        UiMethods().hideLoadingDialog(context: context);
        if (itsOk) {
          widget.requestsProvider.activeClientEvents.clear();
          if (mounted) Navigator.of(context).pop();
          LocalNotificationService.showSnackBar(
            type: "success",
            message: "Solicitud actualizada correctamente",
            icon: Icons.check_outlined,
          );
          return;
        }

        LocalNotificationService.showSnackBar(
          type: "fails",
          message: "Ocurrió un error, intenta nuevamente",
          icon: Icons.check_outlined,
        );
      },
      child: Container(
        width: screenSize.blockWidth >= 920
            ? screenSize.blockWidth * 0.1
            : screenSize.blockWidth * 0.3,
        height: 35,
        decoration: BoxDecoration(
          color: UiVariables.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "Guardar cambios",
            style: TextStyle(
              color: Colors.white,
              fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
            ),
          ),
        ),
      ),
    );
  }

  bool _validateEditFields() {
    try {
      if ((selectedStatus["value"] > 0 &&
              selectedStatus["value"] != 5 &&
              selectedStatus["value"] != 6) &&
          selectedEmployee.id.isEmpty) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Debes agregar un colaborador para el estado seleccionado",
          icon: Icons.error_outline,
        );
        return false;
      }

      if (!isEventSelected && newEventNameController.text.isEmpty) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message:
              "Debes agregar un nombre para el evento al cual vas a mover la solicitud.",
          icon: Icons.error_outline,
        );
        return false;
      }
      int minutesDifferenceRequest =
          selectedEndDate.difference(selectedStartDate).inMinutes;
      if (minutesDifferenceRequest > (24 * 60)) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "La cantidad máxima de horas por solicitud es 24.",
          icon: Icons.error_outline,
          duration: 5,
        );
        return false;
      }

      // if (totalClientPays < totalToPayEmployee) {
      //   LocalNotificationService.showSnackBar(
      //     type: "fail",
      //     message: "La tarifa del cliente debe ser mayor a la del colaborador",
      //     icon: Icons.error_outline,
      //   );
      //   return false;
      // }

      if (indicactionsController.text.isEmpty) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Debes agregar las indicaciones",
          icon: Icons.error_outline,
        );
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
            "AdminRequestAction, _DialogContent, _validateEditFields error: $e");
      }
      return false;
    }
  }

  Future<void> _getNewFare() async {
    try {
      UiMethods().showLoadingDialog(context: context);

      ClientEntity client =
          await ClientServices.getClient(clientId: request.clientInfo.id);
      Map<String, dynamic> jobMap = client.jobs.values
          .firstWhere((element) => element["value"] == selectedJobMap['value']);
      if (!useClientFare) {
        for (var element in jobMap['fares'].values.toList()) {
          element['client_fare'] = double.parse(clientFareController.text);
          element['employee_fare'] = double.parse(employeeFareController.text);
        }
      }
      Job job = Job(
        name: jobMap["name"],
        value: jobMap["value"],
        fares: jobMap["fares"],
      );
      JobRequest jobRequest = _getJobRequest();

      newJobRequest = await JobFareService.get(
        job,
        jobRequest,
        selectedStartDate,
        selectedEndDate,
        client.accountInfo.hasDynamicFare,
        client.accountInfo.id,
        generalInfoProvider.generalInfo.countryInfo,
      );
      UiMethods().hideLoadingDialog(context: context);
    } catch (e) {
      UiMethods().hideLoadingDialog(context: context);
      if (kDebugMode) {
        print("AdminRequestAction, _DialogContent, getNewFare error: $e");
      }
    }
  }

  JobRequest _getJobRequest() {
    return JobRequest(
      clientInfo: {
        "id": request.clientInfo.id,
        "image": request.clientInfo.imageUrl,
        "name": request.clientInfo.name,
        "country": "Costa Rica",
      },
      eventId: selectedEvent!.id,
      eventName: selectedEvent!.eventName,
      startDate: selectedStartDate,
      endDate: selectedEndDate,
      location: request.details.location,
      fareType: "",
      job: {
        "name": selectedJobMap["name"],
        "value": selectedJobMap["value"],
      },
      employeeHours: totalHours,
      totalHours: totalHours,
      employeeFare: JobRequestFare(
        holidayFare: {},
        normalFare: {},
        dynamicFare: {},
      ),
      clientFare: JobRequestFare(
        holidayFare: {},
        normalFare: {},
        dynamicFare: {},
      ),
      totalToPayEmployee: 0,
      totalToPayAllEmployees: 0,
      totalToPayClient: 0,
      totalToPayClientPerEmployee: 0,
      totalClientNightSurcharge: 0,
      totalEmployeeNightSurcharge: 0,
      employeesNumber: 1,
      indications: indicactionsController.text,
      references: referencesController.text,
    );
  }

  String _getWeekDateFormat(DateTime date) {
    return "${date.year}-${CodeUtils.getFormatStringNum(date.month)}-${CodeUtils.getFormatStringNum(date.day)}";
  }

  List<Map<String, dynamic>> getEventsItems() {
    List<Map<String, dynamic>> items = [];
    for (Event event in widget.requestsProvider.activeClientEvents) {
      items.add({
        event.id:
            '${event.eventName}:${CodeUtils.formatDate(selectedEvent!.details.startDate)}'
      });
    }

    return items;
  }

  List<Map<String, dynamic>> getJobsItems() {
    List<Map<String, dynamic>> items = [];
//   items: systemJobs.map<DropdownMenuItem<String>>(
    //     (Map<String, dynamic> job) {
    //       return DropdownMenuItem(
    //         value: job["value"],
    //         child: Text(
    //           job["name"],
    //           style: TextStyle(
    //             color: Colors.black87,
    //             fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
    //           ),
    //         ),
    //       );
    //     },
    //   ).toList(),
    for (Map<String, dynamic> job in systemJobs) {
      items.add(
        {
          'name': job['name'],
          'value': job['value'],
        },
      );
    }

    return items;
  }

  Column _buildClientNightSurcharge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recargo nocturno cliente",
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.12
              : screenSize.blockWidth,
          height: screenSize.height * 0.056,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  blurRadius: 2, color: Colors.black26, offset: Offset(2, 2))
            ],
          ),
          child: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
              color:
                  Colors.grey, //(!useClientFare) ? Colors.black : Colors.grey,
            ),
            enabled: false, //!useClientFare,
            cursorColor: UiVariables.primaryColor,
            controller: clientNightSurchargeController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              border: InputBorder.none,
            ),
            // onChanged: (String newValue) {
            //   if (newValue.isEmpty) return;

            //   setState(() {
            //     totalToPayEmployee = double.parse(newValue) * totalHours;
            //   });
            // },
          ),
        ),
      ],
    );
  }

  Column _buildEmployeeNightSurcharge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recargo nocturno colaborador",
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.12
              : screenSize.blockWidth,
          height: screenSize.height * 0.056,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  blurRadius: 2, color: Colors.black26, offset: Offset(2, 2))
            ],
          ),
          child: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
              color: Colors.grey,
            ), //(!useClientFare) ? Colors.black : Colors.grey),
            enabled: false, //!useClientFare,
            cursorColor: UiVariables.primaryColor,
            controller: employeeNightSurchargeController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              border: InputBorder.none,
            ),
            // onChanged: (String newValue) {
            //   if (newValue.isEmpty) return;

            //   setState(() {
            //     totalToPayEmployee = double.parse(newValue) * totalHours;
            //   });
            // },
          ),
        ),
      ],
    );
  }
}
