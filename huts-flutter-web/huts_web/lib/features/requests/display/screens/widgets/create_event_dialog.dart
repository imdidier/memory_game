import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/widgets/employees/employee_selection/dialog.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_scroll_behavior.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/core/utils/ui/widgets/general/button_progess_indicator.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/requests/display/providers/create_event_provider.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/employee_services/employee_services.dart';
import '../../../../../core/utils/ui/ui_variables.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;

import '../../../../../core/utils/ui/widgets/general/date_time_picker.dart';
import '../../../../auth/domain/entities/company.dart';
import '../../../../clients/domain/entities/client_entity.dart';
import '../../../domain/entities/event_entity.dart';

class CreateEventDialog extends StatefulWidget {
  final ScreenSize screenSize;
  final Event? event;

  const CreateEventDialog({
    required this.screenSize,
    required this.event,
    Key? key,
  }) : super(key: key);

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  bool isScreenLoaded = false;

  late GetRequestsProvider requestsProvider;
  late GeneralInfoProvider generalInfoProvider;
  late AuthProvider authProvider;
  late CreateEventProvider createEventProvider;
  late ClientsProvider clientsProvider;
  late EmployeesProvider employeesProvider;

  TextEditingController requestsController = TextEditingController();
  TextEditingController eventNameController = TextEditingController();
  TextEditingController indicationsController = TextEditingController();
  TextEditingController referenceController = TextEditingController();

  TextEditingController clientSearchController = TextEditingController();
  TextEditingController employeeSearchController = TextEditingController();

  bool isSelectingStartDate = false;
  bool isAdmin = false;
  int selectedClientIndex = -1;
  Employee? selectedClientEmployee;
  // int selectedEmployeeIndex = -1;

  bool isMovingCamera = false;

  List<String> jobsHeaders = [
    "Cargo",
    "Colabs",
    "Hrs.Colab",
    "To.Hrs",
    "Tipo.Ta",
    "Ta.Cliente",
    "Nocturno",
    "Ta.Colab",
    "To.Cliente",
    "To.Colab",
    "To.Pagar",
    "Acción",
  ];

  List<String> jobsHeadersLabels = [
    "Cargo",
    "Colaboradores",
    "Horas colaborador",
    "Total horas",
    "Tipo tarifa",
    "Tarifa cliente",
    "Recargo nocturno cliente",
    "Tarifa colaborador",
    "Total cliente",
    "Total colaborador",
    "Total a pagar",
    "Acción",
  ];

  final GeoPoint validateLocation = const GeoPoint(
    9.9355151,
    -84.2568767,
  );

  List<ClientEntity> filteredClients = [];

  @override
  Widget build(BuildContext context) {
    TextStyle defaultStyle = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11,
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      width: widget.screenSize.blockWidth >= 920
          ? widget.screenSize.blockWidth * 0.82
          : widget.screenSize.blockWidth,
      height: widget.screenSize.height * 0.8,
      child: Stack(
        children: [
          Container(
            height: widget.screenSize.height * 0.7,
            margin: EdgeInsets.only(
              top: widget.screenSize.height * 0.1,
              left: widget.screenSize.blockWidth * 0.015,
              right: widget.screenSize.blockWidth * 0.015,
            ),
            child: SingleChildScrollView(
              physics: isMovingCamera
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              primary: false,
              controller: createEventProvider.scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (createEventProvider.jobsRequests.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 15, bottom: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Lista de cargos solicitados:",
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: widget.screenSize.blockWidth >= 920
                                    ? 14
                                    : 11),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 6),
                          Table(
                            children: buildTableRows(),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 6),
                          const SizedBox(height: 15),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total colaboradores: ${createEventProvider.currentEventRequest.employeesInfo.neededEmployees}",
                                  style: defaultStyle,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Total horas: ${createEventProvider.currentEventRequest.details.totalHours}",
                                  style: defaultStyle,
                                ),
                                const SizedBox(height: 6),
                                if (authProvider
                                    .webUser.clientAssociationInfo.isEmpty)
                                  Text(
                                    "Total a pagar: ${CodeUtils.formatMoney(createEventProvider.currentEventRequest.details.fare.totalClientPays)}",
                                    style: defaultStyle,
                                  ),
                                if (isAdmin) const SizedBox(height: 15),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isAdmin)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OverflowBar(
                          alignment: MainAxisAlignment.spaceBetween,
                          overflowAlignment: OverflowBarAlignment.start,
                          overflowSpacing: 10,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, 15),
                              child: Text(
                                "Selecciona un cliente.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: widget.screenSize.blockWidth >= 920
                                      ? 14
                                      : 11,
                                ),
                              ),
                            ),
                            buildClientSearchField(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(
                          height: 6,
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 5),
                          width: generalInfoProvider.screenSize.blockWidth,
                          height: generalInfoProvider.screenSize.height * 0.19,
                          child: ScrollConfiguration(
                            behavior: CustomScrollBehavior(),
                            child: ListView.builder(
                              itemCount: filteredClients.length,
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (_, int index) {
                                ClientEntity clientItem =
                                    filteredClients[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (widget.event != null) return;
                                          if (filteredClients[index]
                                                  .location
                                                  .position ==
                                              validateLocation) {
                                            LocalNotificationService
                                                .showSnackBar(
                                              type: "fail",
                                              message:
                                                  "Primero agrega una dirección al cliente",
                                              icon: Icons.error_outline,
                                            );
                                            return;
                                          }
                                          setState(() {
                                            if (index == selectedClientIndex) {
                                              selectedClientIndex = -1;
                                              return;
                                            }

                                            selectedClientIndex = index;
                                            createEventProvider
                                                    .addressController.text =
                                                clientItem.location.address;

                                            createEventProvider
                                                .eventCoordinates = maps.LatLng(
                                              clientItem
                                                  .location.position.latitude,
                                              clientItem
                                                  .location.position.longitude,
                                            );

                                            createEventProvider.mapMarkers
                                                .clear();

                                            createEventProvider.mapMarkers.add(
                                              maps.Marker(
                                                markerId: const maps.MarkerId(
                                                    "current_location"),
                                                position: maps.LatLng(
                                                  clientItem.location.position
                                                      .latitude,
                                                  clientItem.location.position
                                                      .longitude,
                                                ),
                                              ),
                                            );

                                            createEventProvider
                                                .updateMapCamera();
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            color: Colors.white,
                                            boxShadow: const [
                                              BoxShadow(
                                                blurRadius: 2,
                                                color: Colors.black12,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                            border: Border.all(
                                              color:
                                                  (index == selectedClientIndex)
                                                      ? Colors.green
                                                      : Colors.transparent,
                                              width: 3,
                                            ),
                                          ),
                                          width: generalInfoProvider
                                                  .screenSize.width *
                                              0.07,
                                          height: generalInfoProvider
                                                  .screenSize.height *
                                              0.1,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              clientItem.imageUrl,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width:
                                            widget.screenSize.blockWidth * 0.13,
                                        child: Center(
                                          child: Text(
                                            clientItem.name,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  // if (isAdmin && selectedClientIndex != -1)
                  //   buildEmployeeSelection(context),
                  const SizedBox(height: 10),
                  Text(
                    (isAdmin || widget.event != null)
                        ? "Completa los campos para agregar una solicitud."
                        : "Completa los campos para agregar un cargo al evento.",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize:
                            widget.screenSize.blockWidth >= 920 ? 14 : 11),
                  ),
                  const SizedBox(height: 10),
                  const Divider(
                    height: 6,
                  ),
                  buildBody(),
                ],
              ),
            ),
          ),
          buildHeader(),
        ],
      ),
    );
  }

  void filterClients(String query) {
    if (query.isEmpty) {
      filteredClients = [...clientsProvider.allClients];
      setState(() {});
      return;
    }

    filteredClients.clear();
    for (ClientEntity client in clientsProvider.allClients) {
      if (client.name.toLowerCase().contains(query)) {
        filteredClients.add(client);
        continue;
      }
    }
    setState(() {});
  }

  Column buildEmployeeSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Transform.translate(
              offset: const Offset(0, 15),
              child: Text(
                "Selecciona un colaborador (opcional).",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11,
                ),
              ),
            ),
            // buildEmployeeSearchField(),
          ],
        ),
        const SizedBox(height: 30),
        const Divider(
          height: 6,
        ),
        InkWell(
          onTap: () async {
            UiMethods().showLoadingDialog(context: context);

            List<Employee>? gottenEmployees =
                await EmployeeServices.getClientEmployees(
              filteredClients[selectedClientIndex].accountInfo.id,
            );

            UiMethods().hideLoadingDialog(context: context);
            if (gottenEmployees == null) return;

            List<Employee?> selectedEmployees =
                await EmployeeSelectionDialog.show(
              employees: gottenEmployees,
              indexesList: employeesProvider.locksOrFavsToEditIndexes,
            );

            if (selectedEmployees.isEmpty) return;

            setState(() {
              selectedClientEmployee = selectedEmployees[0];
            });
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(top: 20, bottom: 35),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Seleccionar",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11),
            ),
          ),
        ),
        if (selectedClientEmployee != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 2,
                          color: Colors.black12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    width: generalInfoProvider.screenSize.width * 0.08,
                    height: generalInfoProvider.screenSize.height * 0.12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        selectedClientEmployee!.profileInfo.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Nombre:",
                    style: TextStyle(
                        fontSize:
                            widget.screenSize.blockWidth >= 920 ? 16 : 11),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Documento:",
                    style: TextStyle(
                        fontSize:
                            widget.screenSize.blockWidth >= 920 ? 16 : 11),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Teléfono",
                    style: TextStyle(
                        fontSize:
                            widget.screenSize.blockWidth >= 920 ? 16 : 11),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Cargos",
                    style: TextStyle(
                        fontSize:
                            widget.screenSize.blockWidth >= 920 ? 16 : 11),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(
                height: 6,
                color: Colors.grey,
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      selectedClientEmployee!.profileInfo.image,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    CodeUtils.getFormatedName(
                      selectedClientEmployee!.profileInfo.names,
                      selectedClientEmployee!.profileInfo.lastNames,
                    ),
                    style: TextStyle(
                        fontSize:
                            widget.screenSize.blockWidth >= 920 ? 16 : 11),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    selectedClientEmployee!.profileInfo.docNumber,
                    style: TextStyle(
                        fontSize:
                            widget.screenSize.blockWidth >= 920 ? 16 : 11),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    selectedClientEmployee!.profileInfo.phone,
                    style: TextStyle(
                        fontSize:
                            widget.screenSize.blockWidth >= 920 ? 16 : 11),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    UiMethods.getJobsNamesBykeys(selectedClientEmployee!.jobs),
                    style: TextStyle(
                        fontSize:
                            widget.screenSize.blockWidth >= 920 ? 16 : 11),
                  )
                ],
              ),
            ],
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Container buildClientSearchField() {
    return Container(
      margin: const EdgeInsets.only(top: 10, right: 10),
      width: widget.screenSize.blockWidth >= 920
          ? widget.screenSize.blockWidth * 0.25
          : widget.screenSize.blockWidth,
      height: widget.screenSize.height * 0.056,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              blurRadius: 2,
              color: Color.fromARGB(66, 204, 172, 172),
              offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        enabled: widget.event == null &&
            authProvider.webUser.clientAssociationInfo.isEmpty,
        controller: clientSearchController,
        cursorColor: UiVariables.primaryColor,
        style: TextStyle(
            color: Colors.black87,
            fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11),
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.search, size: 14),
          ),
          border: InputBorder.none,
          hintText: "Buscar cliente",
          hintStyle: TextStyle(
            color: (widget.event == null) ? Colors.black54 : Colors.grey,
            fontSize: widget.screenSize.blockWidth >= 920 ? 12 : 9,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        ),
        onChanged: ((value) {
          if (selectedClientIndex != -1) {
            setState(() {
              selectedClientIndex = -1;
            });
          }
          filterClients(value.toLowerCase());
        }),
      ),
    );
  }

  Container buildEmployeeSearchField() {
    return Container(
      margin: const EdgeInsets.only(top: 10, right: 10),
      width: widget.screenSize.blockWidth * 0.14,
      height: widget.screenSize.height * 0.056,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(blurRadius: 2, color: Colors.black26, offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        controller: employeeSearchController,
        cursorColor: UiVariables.primaryColor,
        style: TextStyle(
          color: Colors.black87,
          fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11,
        ),
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.search, size: 14),
          ),
          border: InputBorder.none,
          hintText: "Buscar colaborador",
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: widget.screenSize.blockWidth >= 920 ? 12 : 9,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        ),
      ),
    );
  }

  void validateDate(DateTime? selectedDate) {
    if (selectedDate == null) return;
    bool invalidDate = false;

    double minHours = (!isAdmin)
        ? authProvider.webUser.company.accountInfo["min_request_hours"]
        : filteredClients[selectedClientIndex].accountInfo.minRequestHours;

    if (isSelectingStartDate) {
      if (createEventProvider.currentEndDate != null) {
        int minutesDifference = createEventProvider.currentEndDate!
            .difference(selectedDate)
            .inMinutes;
        double hoursDifference = CodeUtils.minutesToHours(minutesDifference);
        if (hoursDifference < minHours) invalidDate = true;
      }
    }

    if (!isSelectingStartDate) {
      if (createEventProvider.currentStartDate != null) {
        int minutesDifference = selectedDate
            .difference(createEventProvider.currentStartDate!)
            .inMinutes;
        double hoursDifference = CodeUtils.minutesToHours(minutesDifference);
        if (hoursDifference < minHours) invalidDate = true;
        if (hoursDifference > 24) {
          LocalNotificationService.showSnackBar(
            type: "fail",
            message: "La cantidad máxima de horas por solicitud es 24",
            icon: Icons.error_outline,
            duration: 5,
          );
          return;
        }
      }
    }

    if (invalidDate) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "La cantidad mínima de horas es $minHours",
        icon: Icons.error_outline,
        duration: 5,
      );
      return;
    }

    createEventProvider.updateCurrentDate(
      isFromStart: isSelectingStartDate,
      newDate: selectedDate,
    );
  }

  @override
  void didChangeDependencies() {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    requestsProvider = Provider.of<GetRequestsProvider>(context);
    authProvider = Provider.of<AuthProvider>(context);
    createEventProvider = Provider.of<CreateEventProvider>(context);
    clientsProvider = Provider.of<ClientsProvider>(context);
    employeesProvider = Provider.of<EmployeesProvider>(context);
    filteredClients = [...clientsProvider.allClients];

    if (authProvider.webUser.clientAssociationInfo.isNotEmpty) {
      filteredClients = [
        filteredClients.firstWhere(
          (element) =>
              element.accountInfo.id ==
              authProvider.webUser.clientAssociationInfo["client_id"],
        )
      ];
    }

    if (widget.event != null) {
      filteredClients = [
        ...filteredClients
            .where((element) =>
                element.accountInfo.id == widget.event!.clientInfo.id)
            .toList()
      ];

      createEventProvider.currentEventRequest.id = widget.event!.id;
      selectedClientIndex = filteredClients.indexWhere(
        (element) => element.accountInfo.id == widget.event!.clientInfo.id,
      );
      eventNameController.text = widget.event!.eventName;

      createEventProvider.addressController.text =
          widget.event!.details.location["address"];
      createEventProvider.currentStartDate = widget.event!.details.startDate;
    }
    GeoPoint geoPoint = (widget.event != null)
        ? widget.event!.details.location["position"]
        : authProvider.webUser.company.location["position"] ??
            const GeoPoint(0, 0);

    createEventProvider.mapMarkers.add(
      maps.Marker(
        markerId: const maps.MarkerId("current_location"),
        position: maps.LatLng(
          geoPoint.latitude,
          geoPoint.longitude,
        ),
      ),
    );

    createEventProvider.eventCoordinates = maps.LatLng(
      geoPoint.latitude,
      geoPoint.longitude,
    );

    if (widget.event == null) {
      createEventProvider.addressController.text =
          authProvider.webUser.company.location["address"] ?? "";
    }

    isAdmin = authProvider.webUser.accountInfo.type == "admin";

    super.didChangeDependencies();
  }

  Container buildBody() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OverflowBar(
            overflowSpacing: 5,
            alignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tipo",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 14 : 11),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Tipo de cargo que deseas solicitar",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 12 : 9),
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 5, left: 10),
                      margin: const EdgeInsets.only(top: 10),
                      width: widget.screenSize.blockWidth >= 920
                          ? widget.screenSize.blockWidth * 0.22
                          : widget.screenSize.blockWidth,
                      height: widget.screenSize.height * 0.056,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 2,
                            color: Colors.black26,
                            offset: Offset(2, 2),
                          )
                        ],
                      ),
                      child: DropdownSearch<String>(
                        items: getItems(),
                        onChanged: createEventProvider.updateCurrentJob,
                        mode: Mode.MENU,
                        maxHeight: 300,
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          cursorColor: UiVariables.primaryColor,
                        ),
                        emptyBuilder: (context, searchEntry) => const Center(
                            child: Text('No se encontraron cargos')),
                        dropdownSearchDecoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Selecciona un cargo',
                          hintStyle: TextStyle(
                            color: Colors.black54,
                            fontSize:
                                widget.screenSize.blockWidth >= 920 ? 12 : 9,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              //   if (!isAdmin)
              Container(
                margin: const EdgeInsets.only(top: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cantidad",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "¿Cuántas solicitudes deseas agregar?",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 12 : 9),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: widget.screenSize.blockWidth >= 920
                          ? widget.screenSize.blockWidth * 0.14
                          : widget.screenSize.blockWidth,
                      height: widget.screenSize.height * 0.056,
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        controller: requestsController,
                        cursorColor: UiVariables.primaryColor,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 16 : 13,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Número solicitudes",
                          hintStyle: TextStyle(
                            color: Colors.black54,
                            fontSize:
                                widget.screenSize.blockWidth >= 920 ? 12 : 9,
                          ),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nombre evento",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "¿Cómo identificaremos el evento?",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 12 : 9),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: widget.screenSize.blockWidth >= 920
                          ? widget.screenSize.blockWidth * 0.14
                          : widget.screenSize.blockWidth,
                      height: widget.screenSize.height * 0.056,
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
                        enabled: createEventProvider.jobsRequests.isEmpty &&
                            widget.event == null,
                        controller: eventNameController,
                        cursorColor: UiVariables.primaryColor,
                        style: TextStyle(
                          color: (createEventProvider.jobsRequests.isEmpty &&
                                  widget.event == null)
                              ? Colors.black87
                              : Colors.grey,
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 16 : 13,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Nombre",
                          hintStyle: TextStyle(
                            color: Colors.black54,
                            fontSize:
                                widget.screenSize.blockWidth >= 920 ? 12 : 9,
                          ),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowSpacing: 5,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Fecha inicio",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Selecciona la fecha de inicio para el cargo",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 12 : 9),
                    ),
                    InkWell(
                      onTap: () async {
                        if (isAdmin && selectedClientIndex == -1) return;

                        isSelectingStartDate = true;

                        DateTime? dateResp = await DateTimePickerDialog.show(
                          widget.screenSize,
                          (isSelectingStartDate &&
                                  createEventProvider.jobsRequests.isEmpty &&
                                  widget.event == null) ||
                              !isSelectingStartDate,
                          (!isSelectingStartDate || widget.event != null)
                              ? createEventProvider.currentStartDate
                              : null,
                          null,
                          eventDate: (widget.event != null)
                              ? widget.event!.details.startDate
                              : null,
                        );

                        validateDate(dateResp);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: widget.screenSize.blockWidth >= 920
                            ? widget.screenSize.blockWidth * 0.22
                            : widget.screenSize.blockWidth,
                        height: widget.screenSize.height * 0.056,
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
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              createEventProvider.currentStartDate == null
                                  ? "Elige una fecha"
                                  : CodeUtils.formatDate(
                                      createEventProvider.currentStartDate!,
                                    ),
                              style: createEventProvider.currentStartDate ==
                                      null
                                  ? TextStyle(
                                      color: Colors.black54,
                                      fontSize:
                                          widget.screenSize.blockWidth >= 920
                                              ? 12
                                              : 9,
                                    )
                                  : TextStyle(
                                      color: Colors.black87,
                                      fontSize:
                                          widget.screenSize.blockWidth >= 920
                                              ? 14
                                              : 11,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Fecha fin",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Selecciona la fecha de fin para el cargo",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 12 : 9),
                    ),
                    InkWell(
                      onTap: () async {
                        if (isAdmin && selectedClientIndex == -1) return;
                        isSelectingStartDate = false;
                        DateTime? dateResp = await DateTimePickerDialog.show(
                          widget.screenSize,
                          (isSelectingStartDate &&
                                  createEventProvider.jobsRequests.isEmpty &&
                                  widget.event == null) ||
                              !isSelectingStartDate,
                          (!isSelectingStartDate || widget.event != null)
                              ? createEventProvider.currentStartDate
                              : null,
                          null,
                        );

                        validateDate(dateResp);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: widget.screenSize.blockWidth >= 920
                            ? widget.screenSize.blockWidth * 0.22
                            : widget.screenSize.blockWidth,
                        height: widget.screenSize.height * 0.056,
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
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              createEventProvider.currentEndDate == null
                                  ? "Elige una fecha"
                                  : CodeUtils.formatDate(
                                      createEventProvider.currentEndDate!),
                              style: createEventProvider.currentEndDate == null
                                  ? TextStyle(
                                      color: Colors.black54,
                                      fontSize:
                                          widget.screenSize.blockWidth >= 920
                                              ? 12
                                              : 9,
                                    )
                                  : TextStyle(
                                      color: Colors.black87,
                                      fontSize:
                                          widget.screenSize.blockWidth >= 920
                                              ? 14
                                              : 11,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Indicaciones especiales",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Escribe las indicaciones que deben seguir los colaboradores. Por ejemplo: llegar al salón... contactar con...",
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: widget.screenSize.blockWidth >= 920 ? 12 : 9),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: widget.screenSize.blockWidth,
                  height: widget.screenSize.height * 0.2,
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
                    controller: indicationsController,
                    maxLines: 50,
                    cursorColor: UiVariables.primaryColor,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: widget.screenSize.blockWidth >= 920 ? 16 : 13,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Indicaciones",
                      hintStyle: TextStyle(
                        color: Colors.black54,
                        fontSize: widget.screenSize.blockWidth >= 920 ? 12 : 9,
                      ),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                )
              ],
            ),
          ),
          buildAddressWidget(),
          buildAddEmployeesBtn()
        ],
      ),
    );
  }

  Widget buildAddEmployeesBtn() {
    return InkWell(
      onTap: () {
        if (createEventProvider.isAddingJob) return;
        if (isAdmin && selectedClientIndex == -1) {
          LocalNotificationService.showSnackBar(
            type: "Fail",
            message: "Debes seleccionar un cliente",
            icon: Icons.error_outline,
          );
          return;
        }

        createEventProvider.addJobRequest(
          authProvider.webUser,
          requestsController.text,
          eventNameController.text,
          indicationsController.text,
          referenceController.text,
          generalInfoProvider.generalInfo.countryInfo,
          (isAdmin) ? filteredClients[selectedClientIndex] : null,
          widget.event != null,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: UiVariables.primaryColor,
          borderRadius: BorderRadius.circular(15),
        ),
        margin: EdgeInsets.only(
          top: 40,
          bottom: 40,
          left: (!isAdmin)
              ? widget.screenSize.blockWidth * 0.15
              : widget.screenSize.blockWidth * 0.2,
          right: (!isAdmin)
              ? widget.screenSize.blockWidth * 0.15
              : widget.screenSize.blockWidth * 0.2,
        ),
        width: widget.screenSize.blockWidth,
        height: widget.screenSize.height * 0.06,
        child: Center(
          child: (!createEventProvider.isAddingJob)
              ? Text(
                  (!isAdmin) ? "Agregar colaboradores al evento" : "Continuar",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 12),
                )
              : const ButtonProgressIndicator(
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  Container buildAddressWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dirección del trabajo",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Escribe la dirección de destino del trabajo en caso de no necesitar la que tienes almacenada.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: widget.screenSize.blockWidth >= 920 ? 12 : 9,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Usar dirección guardada",
                style: TextStyle(
                  fontSize: widget.screenSize.blockWidth >= 920 ? 13 : 10,
                  color: createEventProvider.jobsRequests.isEmpty &&
                          widget.event == null
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  tristate: true,
                  activeColor: (createEventProvider.jobsRequests.isEmpty &&
                              widget.event == null) &&
                          isAdmin
                      ? UiVariables.primaryColor
                      : Colors.grey,
                  value: isAdmin ? createEventProvider.useSavedAddress : null,
                  onChanged: (bool? newValue) {
                    if (!isAdmin) return;

                    if (createEventProvider.jobsRequests.isNotEmpty ||
                        widget.event != null) return;
                    createEventProvider.updateSavedAddressStatus(
                      newValue,
                      (!isAdmin)
                          ? authProvider.webUser.company.location
                          : {
                              "address": filteredClients[selectedClientIndex]
                                  .location
                                  .address,
                              "position": filteredClients[selectedClientIndex]
                                  .location
                                  .position,
                            },
                    );
                  },
                ),
              )
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            width: widget.screenSize.blockWidth,
            height: widget.screenSize.height * 0.056,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    blurRadius: 2, color: Colors.black26, offset: Offset(2, 2))
              ],
            ),
            child: TextField(
              enabled: (!createEventProvider.useSavedAddress ||
                      (!createEventProvider.useSavedAddress &&
                          createEventProvider.jobsRequests.isEmpty &&
                          widget.event == null))
                  ? true
                  : false,
              controller: createEventProvider.addressController,
              cursorColor: UiVariables.primaryColor,
              style: TextStyle(
                color: (!createEventProvider.useSavedAddress ||
                        (!createEventProvider.useSavedAddress &&
                            createEventProvider.jobsRequests.isEmpty &&
                            widget.event == null))
                    ? Colors.black87
                    : Colors.grey,
                fontSize: widget.screenSize.blockWidth >= 920 ? 16 : 13,
              ),
              onSubmitted: (String value) async {
                createEventProvider.addressController.text = value;
                await createEventProvider.getLocationByAddress(
                  authProvider.webUser.company.country,
                );
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Dirección",
                hintStyle: TextStyle(
                  color: Colors.black54,
                  fontSize: widget.screenSize.blockWidth >= 920 ? 12 : 9,
                ),
                contentPadding: const EdgeInsets.all(10),
                suffix: (!createEventProvider.useSavedAddress)
                    ? (createEventProvider.isSearchingLocation)
                        ? const ButtonProgressIndicator()
                        : InkWell(
                            onTap: () =>
                                createEventProvider.getLocationByAddress(
                              authProvider.webUser.company.country,
                            ),
                            child: Text(
                              "Buscar",
                              style: TextStyle(
                                color: UiVariables.primaryColor,
                                fontSize: widget.screenSize.blockWidth >= 920
                                    ? 14
                                    : 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                    : const SizedBox(),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Puntos de referencia",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Escribe algunos puntos de referencia para que le colaborador se ubique más facilmente. Por ejemplo: diagonal al parque... al lado de la iglesia...",
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: widget.screenSize.blockWidth >= 920 ? 12 : 9),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: widget.screenSize.blockWidth,
                  height: widget.screenSize.height * 0.05,
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
                    controller: referenceController,
                    maxLines: 5,
                    cursorColor: UiVariables.primaryColor,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: widget.screenSize.blockWidth >= 920 ? 16 : 13,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Puntos de referencia",
                      hintStyle: TextStyle(
                        color: Colors.black54,
                        fontSize: widget.screenSize.blockWidth >= 920 ? 12 : 9,
                      ),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                )
              ],
            ),
          ),
          if (createEventProvider.jobsRequests.isEmpty && widget.event == null)
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 20),
              width: widget.screenSize.blockWidth,
              height: widget.screenSize.height * 0.35,
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
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  maps.GoogleMap(
                    onMapCreated: createEventProvider.onMapCreated,
                    zoomGesturesEnabled: !createEventProvider.useSavedAddress,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    tiltGesturesEnabled: false,
                    initialCameraPosition: maps.CameraPosition(
                      target:
                          (authProvider.webUser.accountInfo.type == "client")
                              ? maps.LatLng(
                                  authProvider.webUser.company
                                      .location['position'].latitude,
                                  authProvider.webUser.company
                                      .location['position'].longitude,
                                )
                              : const maps.LatLng(0, 0),
                      zoom: 18,
                    ),
                    // markers: createEventProvider.mapMarkers,
                    onCameraMove: (maps.CameraPosition cameraPosition) {
                      if (!isMovingCamera) {
                        setState(() {
                          isMovingCamera = true;
                        });
                      }

                      createEventProvider.newCoordinates =
                          cameraPosition.target;
                    },
                    onCameraIdle: () async {
                      createEventProvider.updateAddressText(context);
                      isMovingCamera = false;
                      setState(() {});
                    },
                  ),
                  Center(
                    child: Icon(
                      Icons.location_on_sharp,
                      color: UiVariables.primaryColor,
                      size: 40,
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: UiVariables.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => createEventProvider.updateDialogStatus(
              false,
              widget.screenSize,
              null,
            ),
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: widget.screenSize.width * 0.018,
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: () {
                  if (createEventProvider.jobsRequests.isEmpty) return;
                  createEventProvider.clearJobsRequests();
                },
                child: Text(
                  "Limpiar",
                  style: TextStyle(
                    color: (createEventProvider.jobsRequests.isEmpty)
                        ? Colors.white38
                        : Colors.white,
                    fontSize: widget.screenSize.width * 0.011,
                  ),
                ),
              ),
              const SizedBox(width: 30),
              InkWell(
                onTap: () async {
                  if (createEventProvider.jobsRequests.isEmpty) return;
                  UiMethods().showLoadingDialog(context: context);
                  await createEventProvider.createEvent(
                    widget.screenSize,
                    isAdmin,
                  );
                  if (mounted) UiMethods().hideLoadingDialog(context: context);
                },
                child: Text(
                  (isAdmin || widget.event != null)
                      ? "Agregar solicitudes"
                      : "Crear evento",
                  style: TextStyle(
                    color: (createEventProvider.jobsRequests.isEmpty)
                        ? Colors.white38
                        : Colors.white,
                    fontSize: widget.screenSize.width * 0.011,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> getDropdownItems() {
    List<DropdownMenuItem<String>> items = [];

    if (authProvider.webUser.accountInfo.type == "client") {
      for (Job jobItem in authProvider.webUser.company.jobs) {
        items.add(
          DropdownMenuItem<String>(
            value: jobItem.name,
            child: Text(
              jobItem.name,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        );
      }
    } else if (selectedClientIndex != -1) {
      filteredClients[selectedClientIndex].jobs.forEach((key, value) {
        Job jobItem = Job(
          fares: value["fares"],
          name: value["name"],
          value: value["value"],
        );
        items.add(
          DropdownMenuItem<String>(
            value: jobItem.name,
            child: Text(
              jobItem.name,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        );
      });
    }

    return items;
  }

  List<String> getItems() {
    List<String> items = [];

    if (authProvider.webUser.accountInfo.type == "client") {
      for (Job jobItem in authProvider.webUser.company.jobs) {
        items.add(jobItem.name);
      }
    } else if (selectedClientIndex != -1) {
      filteredClients[selectedClientIndex].jobs.forEach((key, value) {
        Job jobItem = Job(
          fares: value["fares"],
          name: value["name"],
          value: value["value"],
        );
        items.add(jobItem.name);
      });
    }

    return items;
  }

  CustomTooltip getRowChild(String text, TextStyle style, int index) =>
      CustomTooltip(
        message: jobsHeadersLabels[index],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Text(
              text,
              style: style,
            ),
          ),
        ),
      );

  List<TableRow> buildTableRows() {
    final List<TableRow> rows = [];

    List<Widget> headerItems = [];

    int counter = 0;

    for (String text in jobsHeaders) {
      if (!isAdmin) {
        if (text == "Tipo.Ta" ||
            text == "Ta.Cliente" ||
            text == "Ta.Colab" ||
            text == "To.Cliente") {
          continue;
        }
      }
      if (authProvider.webUser.clientAssociationInfo.isNotEmpty) {
        if (text == "Ta.Cliente" ||
            text == "Nocturno" ||
            text == "Ta.Colab" ||
            text == "To.Cliente" ||
            text == "To.Colab" ||
            text == "To.Pagar") {
          continue;
        }
      }
      headerItems.add(
        getRowChild(
          text,
          const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 13,
          ),
          counter,
        ),
      );
      counter++;
    }

    rows.add(TableRow(children: headerItems));

    TextStyle style = const TextStyle(
      fontSize: 14,
      color: Colors.black,
    );

    for (JobRequest jobRequest in createEventProvider.jobsRequests) {
      String typeFare = jobRequest.fareType;
      double fareClient = typeFare == 'Dinámica'
          ? jobRequest.clientFare.dynamicFare['fare']
          : typeFare == 'Normal'
              ? jobRequest.clientFare.normalFare['fare']
              : jobRequest.clientFare.holidayFare['fare'];
      double fareEmployee = typeFare == 'Dinámica'
          ? jobRequest.employeeFare.dynamicFare['fare']
          : typeFare == 'Normal'
              ? jobRequest.employeeFare.normalFare['fare']
              : jobRequest.employeeFare.holidayFare['fare'];
      rows.add(
        TableRow(
          children: [
            getRowChild(jobRequest.job["name"], style, 0),
            getRowChild("${jobRequest.employeesNumber}", style, 1),
            getRowChild("${jobRequest.employeeHours}", style, 2),
            getRowChild("${jobRequest.totalHours}", style, 3),
            if (isAdmin) getRowChild(typeFare, style, 4),
            if (isAdmin && authProvider.webUser.clientAssociationInfo.isEmpty)
              getRowChild(CodeUtils.formatMoney(fareClient), style, 5),
            if (authProvider.webUser.clientAssociationInfo.isEmpty)
              getRowChild(
                  CodeUtils.formatMoney(jobRequest.totalClientNightSurcharge),
                  style,
                  6),
            if (isAdmin && authProvider.webUser.clientAssociationInfo.isEmpty)
              getRowChild(CodeUtils.formatMoney(fareEmployee), style, 7),
            if (isAdmin && authProvider.webUser.clientAssociationInfo.isEmpty)
              getRowChild(
                  CodeUtils.formatMoney(jobRequest.totalToPayClientPerEmployee),
                  style,
                  8),
            if (authProvider.webUser.clientAssociationInfo.isEmpty)
              getRowChild(
                  CodeUtils.formatMoney(isAdmin
                      ? jobRequest.totalToPayEmployee
                      : jobRequest.totalToPayClient),
                  style,
                  9),
            if (authProvider.webUser.clientAssociationInfo.isEmpty)
              getRowChild(CodeUtils.formatMoney(jobRequest.totalToPayClient),
                  style, 10),
            InkWell(
              onTap: () =>
                  createEventProvider.deleteJobRequest(jobRequest.job["name"]),
              child: getRowChild(
                "Eliminar",
                const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                ),
                11,
              ),
            ),
          ],
        ),
      );
    }

    return rows;
  }
}
