// ignore_for_file: use_build_context_synchronously

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/services/events/clone_event_service.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/company.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/domain/entities/event_entity.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/employee_services/employee_availability_service.dart';
import '../../../../../core/services/local_notification_service.dart';
import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../core/utils/ui/widgets/general/date_time_picker.dart';
import '../../../../clients/domain/entities/client_entity.dart';
import '../../../data/models/event_model.dart';
import '../../providers/create_event_provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RequestActionDialog {
  static Future<void> show(
    String actionType,
    String titleAction,
    Request request,
    Event event, [
    List<int>? indexesList,
    List<Request>? requestsList,
    bool? isItComeFromDialog = true,
  ]) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    if (actionType == "edit" ||
        actionType == "move-requests" ||
        actionType == "clone") {
      GetRequestsProvider requestsProvider =
          Provider.of<GetRequestsProvider>(globalContext, listen: false);
      await requestsProvider.getActiveEvents(
        event.clientInfo.id,
        globalContext,
      );
      if (actionType == "clone") {
        requestsProvider.activeClientEvents
            .removeWhere((element) => element.id == request.eventId);
      }
    }

    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: EdgeInsets.zero,
            title: ActionDialogContent(
              action: actionType,
              titleAction: titleAction,
              request: request,
              event: event,
              indexesList: indexesList,
              requestsList: requestsList,
              isItComeFromDialog: isItComeFromDialog,
            ),
          ),
        );
      },
    );
  }
}

class ActionDialogContent extends StatefulWidget {
  final String action;
  final String titleAction;
  final Request request;
  final Event event;
  final List<Request>? requestsList;
  final List<int>? indexesList;
  final bool? isItComeFromDialog;

  const ActionDialogContent({
    required this.action,
    required this.titleAction,
    required this.request,
    required this.event,
    this.requestsList,
    this.indexesList,
    this.isItComeFromDialog,
    Key? key,
  }) : super(key: key);

  @override
  State<ActionDialogContent> createState() => _ActionDialogContentState();
}

class _ActionDialogContentState extends State<ActionDialogContent> {
  bool isWidgetLoaded = false;
  late GeneralInfoProvider generalInfoProvider;
  late AuthProvider authProvider;
  late GetRequestsProvider getRequestsProvider;
  late CreateEventProvider createEventProvider;
  late EmployeesProvider employeesProvider;

  List<Map<String, dynamic>> employeeRatingOptions = [];
  List<Request> newRequestsList = [];

  //Time and clone action variables //
  bool isSelectingDate = false;
  DateTime? newStartDate;
  DateTime? newEndDate;
  bool fromStartDate = false;
  DateTime currentDate = DateTime.now();
  bool canEditStartDate = false;

  //Edit action variables//
  String? selectedEventId;
  Map<String, dynamic> selectedEventMap = {};

  Event? newEvent;
  TextEditingController indicationsController = TextEditingController();
  TextEditingController nameEventController = TextEditingController();

  //Favorite action variables//
  bool alreadyFavorite = false;

  //Block action variables//
  bool alreadyBlocked = false;

  //Clone action variables//
  bool isEventSelected = true;
  TextEditingController newEventNameController = TextEditingController();

  Map<String, dynamic> selectedStatus = {};
  Map<String, dynamic> updateData = {};
  List<Map<String, dynamic>> requestsStatus = [
    {"name": "Pendiente", "value": 0},
    {"name": "Asignada", "value": 1},
    {"name": "Aceptada", "value": 2},
    {"name": "Activa", "value": 3},
    {"name": "Finalizada", "value": 4},
    {"name": "Cancelada", "value": 5},
    {"name": "Rechazada", "value": 6},
  ];
  List<Map<String, dynamic>> editRequestTabs = [
    {
      "name": "Indicaciones",
      "is_selected": true,
    },
    {
      "name": "Mover solicitud",
      "is_selected": false,
    },
  ];
  Map<String, dynamic> tabItemClient = {};

  bool firstBuild = false;
  Map<String, dynamic> actionInfo = {};

  ClientEntity? client;

  @override
  void didChangeDependencies() async {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    authProvider = Provider.of<AuthProvider>(context);
    getRequestsProvider = Provider.of<GetRequestsProvider>(context);
    createEventProvider = Provider.of<CreateEventProvider>(context);
    employeesProvider = Provider.of<EmployeesProvider>(context);

    newStartDate = widget.request.details.startDate;
    newEndDate = widget.request.details.endDate;

    if (widget.action != "time") {
      canEditStartDate = true;
    } else if (currentDate.isBefore(newStartDate!) &&
        currentDate.day != newStartDate!.day) {
      canEditStartDate = true;
    }
    getRequestsProvider.clientEditRequestOptions = 'indications';
    if (widget.action == "edit" ||
        widget.action == "move-requests" ||
        widget.action == "clone" ||
        widget.action == 'time') {
      selectedEventId = widget.event.id;
      selectedEventMap = {
        widget.event.id:
            '${widget.event.eventName}:${CodeUtils.formatDate(widget.event.details.startDate)}',
      };

      newEvent = widget.event;
      indicationsController.text = widget.request.details.indications;
    }

    if (widget.action != "rate") return;
    if (widget.request.details.rate.isEmpty) {
      for (Map<String, dynamic> rateOption
          in generalInfoProvider.generalInfo.ratingOptions) {
        employeeRatingOptions.add({
          "name": rateOption["name"],
          "value": rateOption["value"],
          "rate": 4,
        });
      }
      return;
    }

    for (int i = 0; i < widget.request.details.rate.keys.length; i++) {
      String key = widget.request.details.rate.keys.toList()[i];
      if (key == "general_rate") continue;

      Map<String, dynamic> rateItem = widget.request.details.rate[key];
      employeeRatingOptions.add({
        "name": rateItem["name"],
        "value": rateItem["value"],
        "rate": rateItem["rate"],
      });
    }

    super.didChangeDependencies();
  }

  void _setInitialValues() {
    int statusRequest = widget.request.details.status;
    if (!firstBuild) {
      firstBuild = true;
      actionInfo = {"type": widget.action};

      if (authProvider.webUser.accountInfo.type != 'admin') {
        requestsStatus = requestsStatus.getRange(1, 3).toList();
        getRequestsProvider.clientEditRequestOptions = 'indications';
      }
      statusRequest = widget.request.details.status;

      selectedStatus = authProvider.webUser.accountInfo.type != 'admin'
          ? requestsStatus.first
          : requestsStatus
              .where(
                (element) => element["value"] == statusRequest,
              )
              .toList()
              .first;
      if (widget.action == 'move-requests' ||
          widget.action == 'edit' ||
          widget.action == 'clone' ||
          widget.action == 'time') {
        newRequestsList.clear();
        List<Request> auxList = [];
        List<Request> previousRequests = [];
        if (widget.action == 'move-requests') {
          auxList = widget.requestsList!;
        } else {
          newRequestsList.add(widget.request.createCopy());
          previousRequests.add(widget.request.createCopy());
        }
        if (widget.action == 'move-requests') {
          for (int index in widget.indexesList!) {
            newRequestsList.add(auxList[index].createCopy());
            previousRequests.add(auxList[index].createCopy());
          }
        }
        updateData['previous_requests'] = (previousRequests).asMap();
        newRequestsList.sort(
            ((a, b) => a.details.startDate.compareTo(b.details.startDate)));
        updateData['previous_event'] = (widget.event as EventModel).toMap();
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _setInitialValues();
    return buildContent(context);
  }

  Container buildContent(BuildContext context) {
    return Container(
      width: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Container(
            height: (widget.action == "rate") ? 500 : null,
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
            ),
            margin: EdgeInsets.symmetric(
              vertical: generalInfoProvider.screenSize.height * 0.09,
            ),
            child: SingleChildScrollView(
              physics: (widget.action == "rate")
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getActionTitle(),
                  (widget.action == "time")
                      ? _buildTimeBody()
                      : (widget.action == "clone" && !isEventSelected ||
                              widget.action == "clone-event")
                          ? _buildStartWidget()
                          : (widget.action == "clone" && isEventSelected)
                              ? _buildEventsWidget()
                              : (widget.action == "rate")
                                  ? buildRateBody()
                                  : (widget.action == "edit" &&
                                              !isEventSelected ||
                                          widget.action == 'edit-name-event')
                                      ? const SizedBox()
                                      : const SizedBox(),
                ],
              ),
            ),
          ),
          _buildHeader(context),
          if (widget.action != "rate" ||
              (widget.action == "rate" && widget.request.details.rate.isEmpty))
            _buildActionFooter(),
        ],
      ),
    );
  }

  Widget buildRateBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: generalInfoProvider.screenSize.height * 0.03,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  foregroundImage: NetworkImage(
                    widget.request.employeeInfo.imageUrl,
                  ),
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 2,
                      text: TextSpan(
                        text: "Nombre: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:
                              generalInfoProvider.screenSize.blockWidth >= 920
                                  ? 16
                                  : 13,
                        ),
                        children: [
                          TextSpan(
                            text:
                                "${widget.request.employeeInfo.names} ${widget.request.employeeInfo.lastNames}",
                            style: TextStyle(
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.normal,
                              fontSize:
                                  generalInfoProvider.screenSize.blockWidth >=
                                          920
                                      ? 16
                                      : 13,
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        text: "Cargo: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:
                              generalInfoProvider.screenSize.blockWidth >= 920
                                  ? 16
                                  : 13,
                        ),
                        children: [
                          TextSpan(
                            text: widget.request.details.job["name"],
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize:
                                  generalInfoProvider.screenSize.blockWidth >=
                                          920
                                      ? 16
                                      : 13,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
            if (widget.request.details.rate.isNotEmpty)
              Text(
                "Calificación: ${widget.request.details.rate['general_rate']}",
                textAlign: generalInfoProvider.screenSize.blockWidth >= 920
                    ? TextAlign.start
                    : TextAlign.center,
                style: TextStyle(
                  fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                      ? 16
                      : 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        SizedBox(
          height: generalInfoProvider.screenSize.height * 0.015,
        ),
        ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: employeeRatingOptions.length,
            itemBuilder: (BuildContext listCtx, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: OverflowBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  overflowAlignment: OverflowBarAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      child: Text(
                        employeeRatingOptions[index]["name"],
                        style: TextStyle(
                          fontSize:
                              generalInfoProvider.screenSize.blockWidth >= 920
                                  ? 13
                                  : 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    (widget.request.details.rate.isNotEmpty)
                        ? RatingBarIndicator(
                            itemPadding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            itemBuilder: (ctx, _) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            rating: employeeRatingOptions[index]["rate"],
                            itemSize: 22,
                          )
                        : RatingBar.builder(
                            glow: false,
                            itemSize: 22,
                            initialRating: 4,
                            minRating: 1,
                            allowHalfRating: true,
                            maxRating: 5,
                            itemPadding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            itemBuilder: (ctx, _) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (double newRate) {
                              setState(() {
                                employeeRatingOptions[index]["rate"] = newRate;
                              });
                            },
                          )
                  ],
                ),
              );
            }),
        SizedBox(height: generalInfoProvider.screenSize.height * 0.03),
      ],
    );
  }

  SizedBox buildEditRequestTabs() {
    return SizedBox(
      height: 35,
      width: generalInfoProvider.screenSize.blockWidth >= 920
          ? generalInfoProvider.screenSize.blockWidth * 0.4
          : generalInfoProvider.screenSize.blockWidth * 0.3,
      child: ListView.builder(
        itemCount: editRequestTabs.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, int index) {
          tabItemClient = editRequestTabs[index];
          return Container(
            margin: const EdgeInsets.only(right: 30),
            child: ChoiceChip(
              backgroundColor: Colors.white,
              label: Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  tabItemClient["name"],
                  style: TextStyle(
                    fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                        ? 14
                        : 11,
                    color: tabItemClient["is_selected"]
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
              selected: tabItemClient["is_selected"],
              elevation: 2,
              selectedColor: UiVariables.primaryColor,
              onSelected: (bool newValue) {
                int lastSelectedIndex = editRequestTabs.indexWhere(
                  (element) => element["is_selected"],
                );

                if (lastSelectedIndex == index) {
                  return;
                }

                if (lastSelectedIndex != -1) {
                  editRequestTabs[lastSelectedIndex]["is_selected"] = false;
                }
                setState(
                  () {
                    getRequestsProvider.clientEditRequestOptions =
                        (index == 0) ? "indications" : 'move-request';
                    editRequestTabs[index]["is_selected"] = newValue;
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Column _buildEditBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   widget.action == "move-requests"
        //       ? '- Puedes mover las solicitudes seleccionadas a un evento nuevo o a uno existente.\n\n- Puedes editar las indicaciones para este evento.'
        //       : "- Puedes cambiar el evento al que pertenece la solicitud.\n\n- Puedes editar las indicaciones dadas al colaborador.",
        //   style: TextStyle(
        //     fontSize:
        //         generalInfoProvider.screenSize.blockWidth >= 920 ? 15 : 12,
        //     color: Colors.black,
        //   ),
        // ),
        const SizedBox(height: 20),
        buildEditRequestTabs(),
        if (getRequestsProvider.clientEditRequestOptions == 'move-request')
          const SizedBox(height: 20),
        if (getRequestsProvider.clientEditRequestOptions == 'move-request')
          Text(
            widget.action == "move-requests"
                ? 'Mover solicitudes seleccionadas'
                : "Mover solicitud",
            style: TextStyle(
              fontSize:
                  generalInfoProvider.screenSize.blockWidth >= 920 ? 14 : 11,
            ),
          ),
        const SizedBox(height: 10),
        if (getRequestsProvider.clientEditRequestOptions == 'move-request')
          _buildMoveRequestOptions(),
        const SizedBox(height: 20),
        if (!isEventSelected &&
            getRequestsProvider.clientEditRequestOptions == 'move-request')
          _buildNameNewEvent(),
        if (isEventSelected &&
            getRequestsProvider.clientEditRequestOptions == 'move-request')
          _buildEventsWidget(),
        const SizedBox(height: 20),
        if (getRequestsProvider.clientEditRequestOptions == 'indications')
          _buildIndicationsWidget(),
      ],
    );
  }

  Row _buildMoveRequestOptions() {
    return Row(
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
              fontSize:
                  generalInfoProvider.screenSize.blockWidth >= 920 ? 14 : 11,
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
              fontSize:
                  generalInfoProvider.screenSize.blockWidth >= 920 ? 14 : 11,
            ),
          ),
          selected: !isEventSelected,
          elevation: 2,
          selectedColor: UiVariables.primaryColor,
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
          height: generalInfoProvider.screenSize.height * 0.056,
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
              fontSize:
                  generalInfoProvider.screenSize.blockWidth >= 920 ? 14 : 12,
            ),
            cursorColor: UiVariables.primaryColor,
            controller: newEventNameController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              border: InputBorder.none,
            ),
          ),
        ),
        _buildStartWidget(),
      ],
    );
  }

  Column _buildTimeBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStartWidget(),
        _buildEndWidget(),
      ],
    );
  }

  Widget _buildEventsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Selecciona un evento",
          style: TextStyle(
            color: Colors.grey,
            fontSize:
                generalInfoProvider.screenSize.blockWidth >= 920 ? 14 : 11,
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 5, left: 10),
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: UiVariables.lightBlueColor,
          ),
          height: generalInfoProvider.screenSize.height * 0.07,
          child: DropdownSearch<Map<String, dynamic>>(
            mode: Mode.MENU,
            items: getItems(),
            selectedItem: selectedEventMap,
            maxHeight: 200,
            itemAsString: (item) => item == null ? '' : item.values.first,
            onChanged: ((widget.action == "clone" ||
                        widget.action == "edit" ||
                        widget.action == "move-requests")
                    ? true
                    : getCanChangeEvent())
                ? (Map<String, dynamic>? newValue) {
                    if (newValue == null) return;
                    selectedEventMap = newValue;
                    updateData['previous_event'] =
                        (newEvent as EventModel).toMap();
                    newEvent = getRequestsProvider.activeClientEvents
                        .firstWhere((element) =>
                            element.id == selectedEventMap.keys.first);
                    updateData['new_event'] = (newEvent as EventModel).toMap();

                    setState(() {});
                  }
                : null,
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
        ),
        const SizedBox(
          height: 10,
        ),
        // if (context.read<AuthProvider>().webUser.accountInfo.type != "client")
        _buildStartWidget(),
      ],
    );
  }

  List<Map<String, dynamic>> getItems() {
    List<Map<String, dynamic>> items = [];
    for (Event event in getRequestsProvider.activeClientEvents) {
      // items.add(event.id);
      items.add({
        event.id:
            '${event.eventName}:${CodeUtils.formatDate(event.details.startDate)}'
      });
    }

    return items;
  }

  bool getCanChangeEvent() {
    DateTime requestStartDate = widget.request.details.startDate;
    bool isSameDay = true;

    if (requestStartDate.year != currentDate.year) isSameDay = false;
    if (requestStartDate.month != currentDate.month) isSameDay = false;
    if (requestStartDate.day != currentDate.day) isSameDay = false;

    return currentDate.isBefore(requestStartDate) && !isSameDay;
  }

  Widget _buildIndicationsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Indicaciones",
          style: TextStyle(
              color: Colors.grey,
              fontSize:
                  generalInfoProvider.screenSize.blockWidth >= 920 ? 14 : 11),
        ),
        Container(
          width: double.infinity,
          height: 100,
          padding: const EdgeInsets.all(14),
          margin: EdgeInsets.only(
            top: generalInfoProvider.screenSize.height * 0.01,
            bottom: generalInfoProvider.screenSize.height * 0.04,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: UiVariables.lightBlueColor,
          ),
          child: TextField(
            controller: indicationsController,
            maxLines: 50,
            cursorColor: UiVariables.primaryColor,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Indicaciones",
              hintStyle: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
              contentPadding: EdgeInsets.all(3),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildActionFooter() {
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
          left: 8.0,
          right: 14.0,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () async {
              if (widget.action == "move-requests" || widget.action == "edit") {
                if (getRequestsProvider.clientEditRequestOptions ==
                    'indications') {
                  if (indicationsController.text ==
                      widget.request.details.indications) {
                    LocalNotificationService.showSnackBar(
                      type: "fail",
                      message: "Indicaciones iguales a las anteriores.",
                      icon: Icons.error_outline,
                    );
                    return;
                  }
                  if (indicationsController.text.isEmpty) {
                    LocalNotificationService.showSnackBar(
                      type: "fail",
                      message: "Debes agregar las nuevas indicaciones",
                      icon: Icons.error_outline,
                    );
                    return;
                  }

                  await getRequestsProvider.saveRequestActionChanges(
                    {
                      'event': widget.event,
                      'new_event': widget.event,
                      'request': newRequestsList.first,
                      'type': 'edit',
                      'new_indications': indicationsController.text,
                    },
                    generalInfoProvider.screenSize,
                  );
                  return;
                }
                if (newEventNameController.text.isEmpty && !isEventSelected) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "Debes agregar un nombre para el nuevo evento.",
                    icon: Icons.error_outline,
                  );
                  return;
                }

                int minutesDifferenceRequest =
                    newEndDate!.difference(newStartDate!).inMinutes;
                if (minutesDifferenceRequest > (24 * 60)) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: 'La cantidad máxima de horas por solicitud es 24.',
                    duration: 5,
                    icon: Icons.error_outline,
                  );
                  return;
                }
                if (!isEventSelected) {
                  updateData['new_event'] = EventModel.emptyEvent().toMap();
                  updateData['new_name_event'] = newEventNameController.text;
                } else {
                  updateData['new_event'] = (newEvent as EventModel).toMap();
                }
                ClientEntity? client;
                ClientsProvider clientProvider =
                    context.read<ClientsProvider>();
                int minutesDifference =
                    newEndDate!.difference(newStartDate!).inMinutes;
                double hoursDifference =
                    CodeUtils.minutesToHours(minutesDifference);
                int minRequestHours = 0;
                if (authProvider.webUser.accountInfo.type != 'client') {
                  client = clientProvider.allClients.firstWhere(
                    (element) =>
                        element.accountInfo.id ==
                        newRequestsList.first.clientInfo.id,
                  );
                  minRequestHours = client.accountInfo.minRequestHours;
                } else {
                  minRequestHours = authProvider
                      .webUser.company.accountInfo['min_request_hours'];
                }

                if (hoursDifference < minRequestHours) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: authProvider.webUser.accountInfo.type != 'client'
                        ? "El horario seelccionado no cumple con el mínimo de horas del cliente, la cantidad mínima de horas es ${client!.accountInfo.minRequestHours}"
                        : 'El horario seelccionado no cumple con el mínimo de horas que tiene asignado.',
                    icon: Icons.error,
                  );
                  return;
                }
                if (newRequestsList.isEmpty) {
                  newRequestsList.add(widget.request);
                }

                for (int i = 0; i < newRequestsList.length; i++) {
                  newRequestsList[i].details.startDate = newStartDate!;
                  newRequestsList[i].details.endDate = newEndDate!;
                }

                UiMethods().showLoadingDialog(context: context);
                bool resp = await getRequestsProvider.moveRequests(
                  newRequestsList,
                  updateData,
                  generalInfoProvider.screenSize,
                  isEventSelected,
                );
                if (resp) {
                  LocalNotificationService.showSnackBar(
                    type: "success",
                    message: "Se movieron las solicitudes con éxito.",
                    icon: Icons.check_outlined,
                  );
                  Navigator.of(context).pop();

                  if (mounted && widget.isItComeFromDialog!) {
                    Navigator.of(context).pop();
                  }
                }
                UiMethods().hideLoadingDialog(context: context);

                if (!resp) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "Ocurrio un error al mover las solicitudes.",
                    icon: Icons.error_outline,
                  );
                  return;
                }
                return;
              }
              if (widget.action == "edit-name-event") {
                UiMethods().showLoadingDialog(context: context);

                bool editnameEvent = await createEventProvider.updateNameEvent(
                    widget.event.id, nameEventController.text);
                UiMethods().hideLoadingDialog(context: context);

                if (editnameEvent) {
                  LocalNotificationService.showSnackBar(
                    type: "success",
                    message: "Nombre del evento cambiado correctamente",
                    icon: Icons.check_outlined,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                  return;
                }
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "No se pudo cambiar el nombre del evento",
                  icon: Icons.error_outline,
                );

                return;
              }
              if (widget.action == "clone-event") {
                UiMethods().showLoadingDialog(context: context);
                final cloneEventResp = await CloneEventService.run(
                  widget.event.eventName,
                  getRequestsProvider.allRequests,
                  Provider.of<GeneralInfoProvider>(context, listen: false)
                      .generalInfo
                      .countryInfo,
                  newStartDate!,
                );
                UiMethods().hideLoadingDialog(context: context);

                cloneEventResp.fold(
                  (ServerException exception) {
                    LocalNotificationService.showSnackBar(
                      type: "fail",
                      message: exception.message,
                      icon: Icons.error_outline,
                    );
                  },
                  (bool itsOk) {
                    if (itsOk) {
                      LocalNotificationService.showSnackBar(
                        type: "success",
                        message: "Evento clonado correctamente",
                        icon: Icons.check_outlined,
                      );
                      Navigator.of(context).pop();
                      return;
                    }
                    LocalNotificationService.showSnackBar(
                      type: "fail",
                      message: "No se pudo clonar el evento",
                      icon: Icons.error_outline,
                    );
                  },
                );

                return;
              }
              if (widget.action != "edit") {
                if (widget.action == "clone" || widget.action == "time") {
                  if (widget.action != "time") {
                    if (isEventSelected && newEvent == null) {
                      LocalNotificationService.showSnackBar(
                        type: "fail",
                        message: "Debes seleccionar un evento",
                        icon: Icons.error_outline,
                      );
                      return;
                    }

                    if (!isEventSelected &&
                        newEventNameController.text.isEmpty) {
                      LocalNotificationService.showSnackBar(
                        type: "fail",
                        message: "Debes agregar el nombre del nuevo evento",
                        icon: Icons.error_outline,
                      );
                      return;
                    }
                  }

                  int minutesDifferenceRequest =
                      newEndDate!.difference(newStartDate!).inMinutes;
                  if (minutesDifferenceRequest > (24 * 60)) {
                    LocalNotificationService.showSnackBar(
                      type: "fail",
                      message:
                          'La cantidad máxima de horas por solicitud es 24.',
                      duration: 5,
                      icon: Icons.error_outline,
                    );
                    return;
                  }

                  bool itsConfirmed = false;

                  ClientsProvider clientProvider =
                      context.read<ClientsProvider>();

                  int minutesDifference =
                      newEndDate!.difference(newStartDate!).inMinutes;
                  double hoursDifference =
                      CodeUtils.minutesToHours(minutesDifference);
                  int minRequestHours = 0;
                  if (authProvider.webUser.accountInfo.type != 'client') {
                    client = clientProvider.allClients.firstWhere(
                      (element) =>
                          element.accountInfo.id ==
                          newRequestsList.first.clientInfo.id,
                    );
                    minRequestHours = client!.accountInfo.minRequestHours;
                  } else {
                    minRequestHours = authProvider
                        .webUser.company.accountInfo['min_request_hours'];
                  }
                  if (widget.action != "time") {
                    itsConfirmed = await confirm(
                      context,
                      title: Text(
                        "¿Seguro quiere clonar esa solicitud con estado ${selectedStatus["name"]}?",
                        style: TextStyle(
                          color: UiVariables.primaryColor,
                        ),
                      ),
                      content: const Text(
                        "¿Ya cordino con el colaborador?",
                      ),
                      textCancel: const Text(
                        "Cancelar",
                        style: TextStyle(color: Colors.grey),
                      ),
                      textOK: const Text(
                        "Aceptar",
                        style: TextStyle(color: Colors.blue),
                      ),
                    );
                    if (!itsConfirmed) return;
                  }

                  if (newStartDate == null) {
                    LocalNotificationService.showSnackBar(
                      type: "fail",
                      message: "Debe seleccionar una fecha",
                      icon: Icons.error,
                    );
                    return;
                  }
                  if (widget.action != "time") {
                    if (!isEventSelected &&
                        newEventNameController.text.isEmpty) {
                      LocalNotificationService.showSnackBar(
                        type: "fail",
                        message: "Debes agregar el nombre del nuevo evento",
                        icon: Icons.error_outline,
                      );
                      return;
                    }
                  }
                  if (hoursDifference < minRequestHours) {
                    LocalNotificationService.showSnackBar(
                      type: "fail",
                      message: authProvider.webUser.accountInfo.type != 'client'
                          ? "El nuevo horario no cumple con el mínimo de horas del cliente, la cantidad mínima de horas es ${client!.accountInfo.minRequestHours}"
                          : 'El nuevo horario no cumple con el mínimo de horas que tiene asignado por solicitud.',
                      icon: Icons.error,
                    );
                    return;
                  }
                  List<double> hoursIncreasingList = [];

                  for (Request request in newRequestsList) {
                    request.details.startDate = DateTime(
                      newStartDate!.year,
                      newStartDate!.month,
                      newStartDate!.day,
                      newStartDate!.hour,
                      newStartDate!.minute,
                    );
                    request.details.endDate = DateTime(
                      newEndDate!.year,
                      newEndDate!.month,
                      newEndDate!.day,
                      newEndDate!.hour,
                      newEndDate!.minute,
                    );
                    request.details.status = selectedStatus['value'];
                    hoursIncreasingList.add(
                        (hoursDifference - request.details.totalHours)
                            .toDouble());
                    request.details.totalHours = hoursDifference;
                  }
                  bool resp = false;
                  if (widget.action != "time") {
                    if (!isEventSelected) {
                      newEvent!.eventName = newEventNameController.text;
                    }
                    UiMethods().showLoadingDialog(context: context);

                    resp = await getRequestsProvider.cloneOrEditRequestsByEvent(
                      hoursIncreasingList,
                      isEventSelected: isEventSelected,
                      requestsList: newRequestsList,
                      screenSize: generalInfoProvider.screenSize,
                      type: 'clone-requests',
                      event: newEvent!,
                    );
                  } else {
                    UiMethods().showLoadingDialog(context: context);

                    resp = await getRequestsProvider.cloneOrEditRequestsByEvent(
                      hoursIncreasingList,
                      isEventSelected: isEventSelected,
                      requestsList: newRequestsList,
                      screenSize: generalInfoProvider.screenSize,
                      type: 'change-schedule',
                      event: newEvent!,
                    );
                  }
                  if (resp) {
                    UiMethods().hideLoadingDialog(context: context);

                    UiMethods().hideLoadingDialog(context: context);
                    if (mounted && widget.isItComeFromDialog!) {
                      Navigator.pop(context);
                      getRequestsProvider.showEventDetailsDialog(
                        context,
                        generalInfoProvider.screenSize,
                        newRequestsList.first.eventId,
                      );
                    }

                    return;
                  }
                  UiMethods().hideLoadingDialog(context: context);
                  return;
                }
                int minutesDifferenceRequest =
                    newEndDate!.difference(newStartDate!).inMinutes;
                if (minutesDifferenceRequest > (24 * 60)) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: 'La cantidad máxima de horas por solicitud es 24.',
                    duration: 5,
                    icon: Icons.error_outline,
                  );
                  return;
                }

                await _callProviderAction();
                return;
              }
              if (indicationsController.text.isEmpty) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "El campo de indicaciones no puede estar vacío",
                  icon: Icons.error_outline,
                );
                return;
              }

              await _callProviderAction();
            },
            child: Container(
              width: (widget.action != "block" && widget.action != "favorite")
                  ? 150
                  : 100,
              height: 35,
              decoration: BoxDecoration(
                color: UiVariables.primaryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  (widget.action != "block" &&
                          widget.action != "favorite" &&
                          widget.action != "clone" &&
                          widget.action != "clone-event")
                      ? "Guardar cambios"
                      : (widget.action == "clone" ||
                              widget.action == "clone-event")
                          ? "Clonar"
                          : "Continuar",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                          ? 15
                          : 12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _callProviderAction() async {
    bool cloneWithoutEmployee = true;

    Job job = Job(name: "name", value: "value", fares: {});

    if (authProvider.webUser.accountInfo.type != "admin") {
      if (!authProvider.webUser.company.jobs.any(
          (element) => element.name == widget.request.details.job["name"])) {
        LocalNotificationService.showSnackBar(
            type: "fail",
            message:
                "El cargo de la solicitud ya no se encuentra disponible para el cliente",
            icon: Icons.error_outline,
            duration: 6);
        return;
      }
      widget.request.details.status = 1;
      job = authProvider.webUser.company.jobs.firstWhere(
        (element) => element.name == widget.request.details.job["name"],
      );
    } else {
      ClientsProvider clientsProvider =
          Provider.of<ClientsProvider>(context, listen: false);

      int requestClientIndex = clientsProvider.allClients.indexWhere(
          (element) => element.accountInfo.id == widget.request.clientInfo.id);

      if (requestClientIndex == -1) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al obtener la información",
          icon: Icons.error_outline,
        );
        return;
      }

      if (!clientsProvider.allClients[requestClientIndex].jobs
          .containsKey(widget.request.details.job["value"])) {
        LocalNotificationService.showSnackBar(
            type: "fail",
            message:
                "El cargo de la solicitud ya no se encuentra disponible para el cliente",
            icon: Icons.error_outline,
            duration: 6);
        return;
      }

      Map<String, dynamic> jobFares = clientsProvider
          .allClients[requestClientIndex]
          .jobs[widget.request.details.job["value"]]["fares"];

      job = Job(
        name: widget.request.details.job["name"],
        value: widget.request.details.job["value"],
        fares: jobFares,
      );
    }

    if (authProvider.webUser.accountInfo.type != "admin" &&
        widget.action == 'clone') {
      widget.request.details.status = selectedStatus['value'];
    }

    widget.action == 'edit-name-event'
        ? actionInfo['event']['eventName'] = nameEventController
        : actionInfo['event'] = widget.event;
    actionInfo['request'] = widget.request;
    actionInfo['job'] = job;
    actionInfo['start_date'] = newStartDate!;
    actionInfo['web_user'] = authProvider.webUser;
    actionInfo['country_info'] = generalInfoProvider.generalInfo.countryInfo;
    actionInfo['client_id'] = widget.request.clientInfo.id;
    actionInfo["status_new_request"] = selectedStatus['value'];

    actionInfo['has_dynamic_rate'] =
        (authProvider.webUser.accountInfo.type == "admin")
            ? Provider.of<ClientsProvider>(context, listen: false)
                .allClients
                .firstWhere((element) =>
                    element.accountInfo.id == widget.request.clientInfo.id)
                .accountInfo
                .hasDynamicFare
            : authProvider.webUser.company.accountInfo["has_dynamic_fare"];

    if (widget.action != "clone") {
      actionInfo['job_request'] = _getJobRequest(null);
      actionInfo['end_date'] = newEndDate!;
      actionInfo['last_client_pays'] =
          widget.request.details.fare.totalClientPays;
      actionInfo['last_pay_employees'] =
          widget.request.details.fare.totalToPayEmployee;
      if (widget.action == "rate") {
        actionInfo["employee_rate"] = employeeRatingOptions;
      }
    } else {
      DateTime cloneEndDate = newEndDate!;

      actionInfo['job_request'] = _getJobRequest(cloneEndDate);
      actionInfo['end_date'] = cloneEndDate;
      actionInfo["is_to_event"] = isEventSelected;

      //If request is already assigned, validate employee availability //
      if (actionInfo['request'].details.status > 0) {
        (bool, double)? isAvaliable = await EmployeeAvailabilityService.get(
          actionInfo["start_date"],
          actionInfo["end_date"],
          actionInfo["request"].employeeInfo.id,
        );
        bool withOutEmployee = actionInfo['request'].employeeInfo.id == '';
        if (withOutEmployee) {
          actionInfo["request"].details.status = 0;
        }

        if (isAvaliable == null) {
          LocalNotificationService.showSnackBar(
            type: "fail",
            message: "No se pudo validar la disponibilidad del colaborador",
            icon: Icons.error_outline,
          );
          return;
        }

        if (!isAvaliable.$1) {
          if (!mounted) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: "No se pudo validar la disponibilidad del colaborador",
              icon: Icons.error_outline,
            );
            return;
          }
          cloneWithoutEmployee = await confirm(
            context,
            title: SizedBox(
              width: 400,
              child: Text(
                "Colaborador no disponible",
                style: TextStyle(
                  color: UiVariables.primaryColor,
                ),
              ),
            ),
            content: const SizedBox(
              width: 400,
              child: Text(
                "El colaborador no está disponible para el turno de la solicitud a clonar. ¿Quieres continuar y que el sistema asigne un nuevo colaborador?",
              ),
            ),
            textCancel: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.grey),
            ),
            textOK: Text(
              "Continuar",
              style: TextStyle(color: UiVariables.primaryColor),
            ),
          );

          if (cloneWithoutEmployee) {
            actionInfo["request"].details.status = 0;
          }
        }
      }
    }
    // actionInfo['employee'] = employeesProvider.employees.firstWhere(
    //     (element) => element.id == actionInfo['request'].employeeInfo.id);
    if (cloneWithoutEmployee) {
      actionInfo["new_indications"] = indicationsController.text;
      if (!isEventSelected) {
        actionInfo['job_request'].eventName =
            newEventNameController.text.trim();
      }
      actionInfo["new_event"] = newEvent;
      await getRequestsProvider.saveRequestActionChanges(
        actionInfo,
        generalInfoProvider.screenSize,
      );
    }
  }

  JobRequest? _getJobRequest(DateTime? cloneEndDate) {
    double newJobHours = CodeUtils.minutesToHours(
      (cloneEndDate == null)
          ? newEndDate!.difference(newStartDate!).inMinutes
          : cloneEndDate.difference(newStartDate!).inMinutes,
    );
    return JobRequest(
      clientInfo: (authProvider.webUser.accountInfo.type != "admin")
          ? {
              "id": authProvider.webUser.company.id,
              "image": authProvider.webUser.company.image,
              "name": authProvider.webUser.company.name,
              "country": authProvider.webUser.company.country,
            }
          : {
              "id": widget.request.clientInfo.id,
              "image": widget.request.clientInfo.imageUrl,
              "name": widget.request.clientInfo.name,
              "country": "Costa Rica",
            },
      eventId: widget.request.eventId,
      eventName: widget.request.eventName,
      startDate: newStartDate!,
      endDate: (cloneEndDate == null) ? newEndDate! : cloneEndDate,
      location: widget.request.details.location,
      fareType: "",
      job: {
        "name": widget.request.details.job["name"]!,
        "value": widget.request.details.job["value"],
      },
      employeeHours: newJobHours,
      totalHours: newJobHours,
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
      indications: widget.request.details.indications,
      references: widget.request.details.references,
    );
  }

  void _validateDate(DateTime? selectedDate) {
    if (selectedDate == null) return;
    bool invalidDate = false;
    int requestStatus = widget.request.details.status;

    double minHours = 4;

    if (authProvider.webUser.accountInfo.type != "admin") {
      minHours = authProvider.webUser.company.accountInfo["min_request_hours"];
    } else {
      ClientsProvider clientsProvider =
          Provider.of<ClientsProvider>(context, listen: false);

      int requestClientIndex = clientsProvider.allClients.indexWhere(
          (element) => element.accountInfo.id == widget.request.clientInfo.id);

      if (requestClientIndex == -1) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al obtener la información",
          icon: Icons.error_outline,
        );
        return;
      }

      minHours = clientsProvider
          .allClients[requestClientIndex].accountInfo.minRequestHours
          .toDouble();
    }

    if (fromStartDate && newEndDate != null) {
      int minutesDifference = newEndDate!.difference(selectedDate).inMinutes;
      double hoursDifference = CodeUtils.minutesToHours(minutesDifference);
      if (hoursDifference < minHours) invalidDate = true;
    }

    if (!fromStartDate && newStartDate != null) {
      int minutesDifference = selectedDate.difference(newStartDate!).inMinutes;
      double hoursDifference = CodeUtils.minutesToHours(minutesDifference);
      if (hoursDifference < minHours) invalidDate = true;
    }

    if (requestStatus == 3 && newEndDate != null) {
      if (selectedDate.isBefore(newEndDate!)) invalidDate = true;
    }

    if (invalidDate) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: (requestStatus == 3)
            ? "No puedes disminuir la duración durante el turno"
            : "La cantidad mínima de horas es $minHours",
        icon: Icons.error_outline,
        duration: 5,
      );
      return;
    }

    setState(() {
      if (fromStartDate) newStartDate = selectedDate;
      if (!fromStartDate) newEndDate = selectedDate;
      fromStartDate = false;
    });
  }

  Column _buildStartWidget() {
    DateTime compareDate = DateTime(
      widget.request.details.startDate.year,
      widget.request.details.startDate.month,
      widget.request.details.startDate.day - 1,
      23,
      59,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isEventSelected)
          SizedBox(
            height: generalInfoProvider.screenSize.height * 0.03,
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Fecha y hora inicio",
                  style: TextStyle(
                    color: (widget.action == "time") &&
                            DateTime.now().isAfter(compareDate)
                        ? Colors.grey
                        : Colors.black,
                    fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                        ? 14
                        : 11,
                  ),
                ),
                InkWell(
                  onTap: (widget.action == "time") &&
                          DateTime.now().isAfter(compareDate)
                      ? null
                      : () async {
                          if (widget.action == "time") {
                            if (!canEditStartDate) return;
                            fromStartDate = true;
                            _validateDate(
                              await DateTimePickerDialog.show(
                                generalInfoProvider.screenSize,
                                true,
                                widget.request.details.startDate,
                                widget.request.details.startDate,
                              ),
                            );
                          } else if (widget.action == "clone" ||
                              widget.action == "clone-event" ||
                              widget.action == "move-requests" ||
                              widget.action == 'edit') {
                            bool isClone = widget.action == "clone" ||
                                widget.action == "move-requests" ||
                                widget.action == 'edit';

                            DateTime? selectedDate =
                                await DateTimePickerDialog.show(
                              generalInfoProvider.screenSize,
                              true,
                              (isClone)
                                  ? widget.request.details.startDate
                                  : DateTime.now(),
                              (isClone)
                                  ? widget.request.details.startDate
                                  : DateTime.now(),
                              isTimeEnabled: isClone,
                            );
                            if (selectedDate == null) return;
                            setState(() {
                              newStartDate = selectedDate;
                            });
                          }
                        },
                  child: Container(
                    width: widget.action == "time"
                        ? 540
                        : (widget.action == 'clone' ||
                                widget.action == 'edit' ||
                                widget.action == "move-requests")
                            ? generalInfoProvider.screenSize.blockWidth * 0.17
                            : generalInfoProvider.screenSize.blockWidth * 0.35,
                    padding: const EdgeInsets.all(14),
                    margin: EdgeInsets.only(
                      top: generalInfoProvider.screenSize.height * 0.01,
                      bottom: generalInfoProvider.screenSize.height * 0.03,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: UiVariables.lightBlueColor,
                    ),
                    child: Text(
                      (widget.action == "clone" || widget.action == "edit")
                          ? CodeUtils.formatDate(newStartDate ?? currentDate)
                          : CodeUtils.formatDate(
                              newStartDate ?? DateTime.now()),
                      //  .split(" ")[0],
                      style: TextStyle(
                        fontSize:
                            generalInfoProvider.screenSize.blockWidth >= 920
                                ? 14
                                : 11,
                        color: (canEditStartDate) ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.action == 'clone' ||
                widget.action == 'edit' ||
                widget.action == "move-requests")
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha y hora fin',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                          ? 14
                          : 11,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      DateTime? selectedDate = await DateTimePickerDialog.show(
                        generalInfoProvider.screenSize,
                        true,
                        widget.request.details.endDate,
                        widget.request.details.endDate,
                        isTimeEnabled: true,
                      );
                      if (selectedDate == null) return;
                      setState(
                        () {
                          newEndDate = selectedDate;
                        },
                      );
                    },
                    child: Container(
                      width: generalInfoProvider.screenSize.blockWidth * 0.17,
                      padding: const EdgeInsets.all(14),
                      margin: EdgeInsets.only(
                        top: generalInfoProvider.screenSize.height * 0.01,
                        bottom: generalInfoProvider.screenSize.height * 0.03,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: UiVariables.lightBlueColor,
                      ),
                      child: Text(
                        CodeUtils.formatDate(
                          newEndDate ?? widget.request.details.endDate,
                        ),
                        style: TextStyle(
                          fontSize:
                              generalInfoProvider.screenSize.blockWidth >= 920
                                  ? 14
                                  : 11,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (widget.action == "clone" && !isEventSelected)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nombre del evento",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                      ? 14
                      : 11,
                ),
              ),
              Container(
                height: 45,
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: EdgeInsets.only(
                  top: generalInfoProvider.screenSize.height * 0.01,
                  bottom: generalInfoProvider.screenSize.height * 0.03,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: UiVariables.lightBlueColor,
                ),
                child: TextField(
                  controller: newEventNameController,
                  decoration: InputDecoration(
                    hintStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                          ? 14
                          : 11,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      bottom: 20,
                    ),
                  ),
                ),
              ),
            ],
          )
      ],
    );
  }

  Column _buildEndWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fecha y hora fin",
          style: TextStyle(
            color: Colors.black,
            fontSize:
                generalInfoProvider.screenSize.blockWidth >= 920 ? 14 : 11,
          ),
        ),
        InkWell(
          onTap: () async {
            fromStartDate = false;
            _validateDate(
              await DateTimePickerDialog.show(
                generalInfoProvider.screenSize,
                widget.request.details.status <= 4,
                widget.request.details.startDate,
                widget.request.details.endDate,
                fromClientEditRequestEndTime:
                    authProvider.webUser.accountInfo.type == "client" &&
                        actionInfo["type"] == "time",
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: EdgeInsets.only(
              top: generalInfoProvider.screenSize.height * 0.01,
              bottom: generalInfoProvider.screenSize.height * 0.04,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: UiVariables.lightBlueColor,
            ),
            child: Text(
              CodeUtils.formatDate(
                  newEndDate ?? widget.request.details.endDate),
              style: TextStyle(
                fontSize:
                    generalInfoProvider.screenSize.blockWidth >= 920 ? 14 : 11,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Container _buildHeader(BuildContext context) {
    String dialogTitle = widget.action == "clone-event"
        ? "Clonar evento ${widget.event.eventName}"
        : widget.action == 'edit-name-event'
            ? "Editar nombre del evento: ${widget.event.eventName}"
            : (widget.action == "block" || widget.action == "favorite")
                ? "${widget.titleAction} ${widget.request.employeeInfo.names}"
                : widget.titleAction; // ${widget.request.employeeInfo.names}";
    return Container(
      width: double.infinity,
      height: generalInfoProvider.screenSize.blockWidth >= 920 ? 60 : 50,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor.withOpacity(0.8),
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
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            // Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            // children: [
            Text(
              dialogTitle,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                      ? 18
                      : 13),
            ),
            // const SizedBox(width: 30),
            // Text(
            // (widget.action == "clone-event")
            // ? "Id: ${widget.event.id}"
            // : "Id: ${widget.request.id}",
            // style: TextStyle(
            // color: Colors.white,
            // fontSize: generalInfoProvider.screenSize.blockWidth >= 920
            // ? 12
            // : 10),
            // )
            // ],
            // )
          ],
        ),
      ),

      // Align(
      //   alignment: Alignment.centerLeft,
      //   child: Padding(
      //     padding: const EdgeInsets.all(8.0),
      //     child: InkWell(
      //       onTap: () => Navigator.of(context).pop(),
      //       child: Icon(
      //         Icons.close,
      //         color: Colors.white,
      //         size: generalInfoProvider.screenSize.width * 0.02,
      //       ),
      //     ),
      //   ),
      // ),
    );
  }

  Column _buildStatusSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Estado de solicitud",
          style: TextStyle(
            color: Colors.grey,
            fontSize:
                generalInfoProvider.screenSize.blockWidth >= 920 ? 12 : 10,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(top: 5, right: 10),
          width: generalInfoProvider.screenSize.blockWidth >= 920
              ? generalInfoProvider.screenSize.blockWidth * 0.2
              : generalInfoProvider.screenSize.blockWidth,
          height: generalInfoProvider.screenSize.height * 0.05,
          decoration: BoxDecoration(
            color: UiVariables.lightBlueColor,
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
            menuMaxHeight: 300,
            items: requestsStatus.map<DropdownMenuItem<int>>(
              (Map<String, dynamic> job) {
                return DropdownMenuItem(
                  value: job["value"],
                  child: Text(
                    job["name"],
                    style: TextStyle(
                      color:
                          selectedStatus['value'] == 0 ? null : Colors.black87,
                      fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                          ? 12
                          : 10,
                    ),
                  ),
                );
              },
            ).toList(),
            onChanged: selectedStatus['value'] == 0
                ? null
                : (int? newValue) {
                    selectedStatus = requestsStatus.firstWhere(
                      (element) => element["value"] == newValue,
                    );
                    actionInfo['status_new_requets'] = selectedStatus['value'];
                    setState(() {});
                  },
          ),
        ),
      ],
    );
  }

  Widget _getActionTitle() {
    alreadyBlocked = false;
    alreadyFavorite = false;

    if (authProvider.webUser.accountInfo.type != "admin") {
      alreadyFavorite = (authProvider.webUser.company.favoriteEmployees.any(
        (favoriteEmployee) =>
            favoriteEmployee.uid == widget.request.employeeInfo.id,
      ));

      alreadyBlocked = (authProvider.webUser.company.blockedEmployees.any(
        (blockedEmployee) =>
            blockedEmployee.uid == widget.request.employeeInfo.id,
      ));
    } else {
      ClientsProvider clientsProvider =
          Provider.of<ClientsProvider>(context, listen: false);

      int requestClientIndex = clientsProvider.allClients.indexWhere(
          (element) => element.accountInfo.id == widget.request.clientInfo.id);

      if (requestClientIndex == -1) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message:
              "Ocurrió un error al obtener el estado de bloqueo del colaborador",
          icon: Icons.error_outline,
        );
      } else {
        alreadyFavorite = clientsProvider
            .allClients[requestClientIndex].favoriteEmployees
            .containsKey(widget.request.employeeInfo.id);
        alreadyBlocked = clientsProvider
            .allClients[requestClientIndex].blockedEmployees
            .containsKey(widget.request.employeeInfo.id);
      }
    }

    if (widget.action == "clone" || widget.action == "clone-event") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.action == "clone"
                ? (authProvider.webUser.clientAssociationInfo.isEmpty)
                    ? "Información de la solicitud:\n\nEvento: ${widget.request.eventName}\nCargo: ${widget.request.details.job["name"]}\nColaborador: ${widget.request.employeeInfo.names} ${widget.request.employeeInfo.lastNames}\nHoras turno: ${widget.request.details.totalHours}\nTotal a pagar: ${CodeUtils.formatMoney(widget.request.details.fare.totalClientPays)}\n\nSelecciona la fecha y agrega el nombre del nuevo evento o selecciona uno ya existente. Además, selecciona el estado en el que deseas que este la solicitud."
                    : "Información de la solicitud:\n\nEvento: ${widget.request.eventName}\nCargo: ${widget.request.details.job["name"]}\nColaborador: ${widget.request.employeeInfo.names} ${widget.request.employeeInfo.lastNames}\nHoras turno: ${widget.request.details.totalHours}\n\nSelecciona la fecha y agrega el nombre del nuevo evento o selecciona uno ya existente. Además, selecciona el estado en el que deseas que este la solicitud."
                : "Información del evento:\n\nNombre: ${widget.event.eventName}\nHora inicio: ${CodeUtils.formatDate(widget.event.details.endDate).split(" ")[1]}\nCargos solicitados: ${widget.event.employeesInfo.neededJobs.keys.length}\nColaboradores solicitados: ${widget.event.employeesInfo.neededEmployees}\nTotal horas: ${widget.event.details.totalHours}\n\nSelecciona la fecha en la que deseas clonar este evento. Además, selecciona el estado en el que deseas dejar el evento.",
            style: TextStyle(
              fontSize:
                  generalInfoProvider.screenSize.blockWidth >= 920 ? 15 : 12,
              color: Colors.black,
            ),
          ),
          if (widget.action == "clone") const SizedBox(height: 30),
          if (widget.action == "clone")
            Row(
              children: [
                ChoiceChip(
                  onSelected: (bool newValue) {
                    setState(() {
                      isEventSelected = !newValue;
                    });
                  },
                  backgroundColor: Colors.white,
                  label: Text(
                    "Elegir Fecha",
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
                const SizedBox(width: 30),
                ChoiceChip(
                  onSelected: (bool newValue) {
                    setState(() {
                      isEventSelected = newValue;
                    });
                  },
                  backgroundColor: Colors.white,
                  label: Text(
                    "Elegir Evento",
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
              ],
            ),
          const SizedBox(height: 15),
          _buildStatusSelection(),
        ],
      );
    }

    if (widget.action == "edit" || widget.action == "move-requests") {
      return _buildEditBody();
    }

    if (widget.action == "edit-name-event") {
      return Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(top: 10, right: 10),
        width: generalInfoProvider.screenSize.blockWidth * 0.42,
        height: generalInfoProvider.screenSize.height * 0.058,
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
        child: TextField(
          controller: nameEventController,
          decoration: InputDecoration(
            hintText: "Nuevo nombre del evento",
            hintStyle: TextStyle(
              color: Colors.black54,
              fontSize:
                  generalInfoProvider.screenSize.blockWidth >= 920 ? 14 : 11,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      );
    }

    return Text(
      (widget.action == "time")
          ? "Cambia las fechas para modificar el horario del turno"
          : (widget.action == "edit")
              ? "- Puedes cambiar el evento al que pertenece la solicitud\n  (hasta media noche del día anterior).\n\n- Puedes editar las indicaciones dadas al colaborador."
              : (widget.action == "rate")
                  ? (widget.request.details.rate.isNotEmpty)
                      ? "Calificación realizada al colaborador:"
                      : "Califica el desempeño que tuvo el colaborador durante el turno de ${widget.request.details.totalHours} horas para el evento: ${widget.request.eventName}. Tu calificación es muy importante ya que nos ayuda a mejorar cada vez más."
                  : (widget.action == "block")
                      ? (alreadyBlocked)
                          ? "Se desbloqueará a ${widget.request.employeeInfo.names} ${widget.request.employeeInfo.lastNames} y podrá recibir tus solicitudes nuevamente. ¿Quieres continuar?"
                          : "Se marcará a ${widget.request.employeeInfo.names} ${widget.request.employeeInfo.lastNames} como bloqueado y no podrá recibir tus próximas solicitudes. ¿Quieres continuar?"
                      : (alreadyFavorite)
                          ? "Se quitará a ${widget.request.employeeInfo.names} ${widget.request.employeeInfo.lastNames} de tus favoritos y ya no se le dará prioridad en la asignación de tus solicitudes. ¿Quieres continuar?"
                          : "Se agregará a ${widget.request.employeeInfo.names} ${widget.request.employeeInfo.lastNames} a tu lista de favoritos. Esto le dará prioridad en la asignación de tus solicitudes. ¿Quieres continuar?",
      style: TextStyle(
        fontSize: generalInfoProvider.screenSize.blockWidth >= 920 ? 15 : 12,
        color: Colors.black,
      ),
    );
  }
}
