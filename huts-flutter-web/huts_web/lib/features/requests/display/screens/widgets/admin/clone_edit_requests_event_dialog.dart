// ignore_for_file: use_build_context_synchronously

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/services/local_notification_service.dart';
import '../../../../../../core/services/navigation_service.dart';
import '../../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../../core/utils/ui/widgets/general/date_time_picker.dart';
import '../../../../../auth/domain/entities/screen_size_entity.dart';
import '../../../../../clients/display/provider/clients_provider.dart';
import '../../../../../general_info/display/providers/general_info_provider.dart';
import '../../../../domain/entities/event_entity.dart';
import '../../../providers/create_event_provider.dart';
import '../../../providers/get_requests_provider.dart';

class CloneOrEditRequestsByEventDialog {
  static Future<void> showActionDialog({
    required String type,
    required List<Request> requestsList,
    required List<int> indexesList,
    bool isItComeFromDialog = true,
  }) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;
    GetRequestsProvider requestsProvider =
        Provider.of<GetRequestsProvider>(globalContext, listen: false);
    await requestsProvider.getActiveEvents(
      requestsList.first.clientInfo.id,
      globalContext,
    );
    if (type == "clone") {
      requestsProvider.activeClientEvents
          .removeWhere((element) => element.id == requestsList.first.eventId);
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
                type: type,
                indexesList: indexesList,
                requestsList: requestsList,
                isItComeFromDialog: isItComeFromDialog,
              ),
            ),
          );
        });
  }
}

class _DialogContent extends StatefulWidget {
  final String type;
  final List<Request> requestsList;
  final List<int> indexesList;
  final bool? isItComeFromDialog;

  const _DialogContent({
    required this.type,
    required this.requestsList,
    required this.indexesList,
    this.isItComeFromDialog,
  });
  @override
  State<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<_DialogContent> {
  late GeneralInfoProvider generalInfoProvider;
  late GetRequestsProvider requestsProvider;
  late CreateEventProvider createEventProvider;
  late AuthProvider authProvider;

  DateTime? selectedDateStart;
  DateTime? selectedDateEnd;

  DateTime? startDate;
  DateTime? endDate;

  DateTime? newSelectedDate;

  late ScreenSize screenSize;
  Map<String, dynamic> selectedEventMap = {};
  Event? newEvent;
  bool isAdmin = false;

  bool isEventSelected = false;
  TextEditingController newEventNameController = TextEditingController();

  List<Request> newRequestsList = [];
  double totalHours = 0;
  int totalJobs = 1;
  List<String> jobs = [];
  bool isDialogLoaded = false;
  ClientEntity? client;

  Map<String, dynamic> selectedStatus = {};
  List<Map<String, dynamic>> requestsStatus = [
    {"name": "Pendiente", "value": 0},
    {"name": "Asignada", "value": 1},
    {"name": "Aceptada", "value": 2},
    {"name": "Activa", "value": 3},
    {"name": "Finalizada", "value": 4},
    {"name": "Cancelada", "value": 5},
    {"name": "Rechazada", "value": 6},
  ];

  @override
  void didChangeDependencies() {
    if (isDialogLoaded) return;
    isDialogLoaded = true;

    _setInitialValues();

    if (mounted) {
      setState(() {});
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          //  widget.type == 'clone-requests'
          // ?
          screenSize.blockWidth * 0.4,
      // : screenSize.blockWidth * 0.3,
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
            height: widget.type == 'clone-requests'
                ? screenSize.height * 0.7
                : screenSize.height * 0.43,
            margin: EdgeInsets.only(
              left: 10,
              right: 10,
              top: screenSize.height * 0.09,
            ),
            child: _buildBody(),
          ),
          _buildHeader(context),
          _buildFooter(),
        ],
      ),
    );
  }

  Column _buildBody() {
    return Column(
      children: [
        widget.type == 'clone-requests'
            ? _cloneRequestsInfo()
            : _changeSchedule()
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
              },
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: screenSize.width * 0.02,
              ),
            ),
            const SizedBox(width: 10),
            CustomTooltip(
              message: widget.type == 'clone-requests'
                  ? "Clonar solicitudes del evento: ${newRequestsList[0].eventName}"
                  : "Modificar horario",
              child: SizedBox(
                width: screenSize.blockWidth * 0.35,
                child: Text(
                  widget.type == 'clone-requests'
                      ? "Clonar solicitudes del evento: ${newRequestsList[0].eventName}"
                      : "Modificar horario de solicitudes seleccionadas",
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Positioned _buildFooter() {
    return Positioned(
      bottom: 20,
      right: 30,
      child: _buildSaveBtn(),
    );
  }

  _buildSaveBtn() {
    return InkWell(
      onTap: () async {
        if (widget.type == 'clone-requests') {
          int minutesDifferenceRequest =
              selectedDateEnd!.difference(selectedDateStart!).inMinutes;
          if (minutesDifferenceRequest > (24 * 60)) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: 'La cantidad máxima de horas por solicitud es 24.',
              icon: Icons.error_outline,
              duration: 5,
            );
            return;
          }
          bool itsConfirmed = false;

          ClientsProvider clientProvider = context.read<ClientsProvider>();

          int minutesDifference =
              selectedDateEnd!.difference(selectedDateStart!).inMinutes;
          double hoursDifference = CodeUtils.minutesToHours(minutesDifference);
          int minRequestHours = 0;
          if (authProvider.webUser.accountInfo.type != 'client') {
            client = clientProvider.allClients.firstWhere(
              (element) =>
                  element.accountInfo.id == newRequestsList.first.clientInfo.id,
            );
            minRequestHours = client!.accountInfo.minRequestHours;
          } else {
            minRequestHours =
                authProvider.webUser.company.accountInfo['min_request_hours'];
          }

          if (!isAdmin) {
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

          if (selectedDateStart == null) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: "Debe seleccionar una fecha",
              icon: Icons.error,
            );
            return;
          }
          if (!isEventSelected && newEventNameController.text.isEmpty) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: "Debes agregar el nombre del nuevo evento",
              icon: Icons.error_outline,
            );
            return;
          }
          // DateTime? dateCompare = DateTime(
          //   newRequestsList.first.details.startDate.year,
          //   newRequestsList.first.details.startDate.month,
          //   newRequestsList.first.details.startDate.day + 1,
          //   00,
          //   00,
          // );

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
              selectedDateStart!.year,
              selectedDateStart!.month,
              selectedDateStart!.day,
              selectedDateStart!.hour,
              selectedDateStart!.minute,
            );
            request.details.endDate = DateTime(
              selectedDateEnd!.year,
              selectedDateEnd!.month,
              selectedDateEnd!.day,
              selectedDateEnd!.hour,
              selectedDateEnd!.minute,
            );
            request.details.status = selectedStatus['value'];
            hoursIncreasingList
                .add((hoursDifference - request.details.totalHours).toDouble());
            request.details.totalHours = hoursDifference;
          }

          if (!isEventSelected) {
            newEvent!.eventName = newEventNameController.text;
          }

          UiMethods().showLoadingDialog(context: context);
          newRequestsList.sort(
              (a, b) => a.details.startDate.compareTo(b.details.startDate));
          bool resp = await requestsProvider.cloneOrEditRequestsByEvent(
            hoursIncreasingList,
            isEventSelected: isEventSelected,
            requestsList: [...newRequestsList],
            screenSize: screenSize,
            type: widget.type,
            event: newEvent!,
          );

          if (resp) {
            UiMethods().hideLoadingDialog(context: context);

            UiMethods().hideLoadingDialog(context: context);
            if (mounted && widget.isItComeFromDialog!) {
              Navigator.pop(context);
              requestsProvider.showEventDetailsDialog(
                  context, screenSize, newRequestsList.first.eventId);
            }

            return;
          }
          UiMethods().hideLoadingDialog(context: context);
        } else {
          if (startDate == null || endDate == null) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: "Debe seleccionar una fecha de inicio y una de fin.",
              icon: Icons.error,
            );
            return;
          }
          if (startDate!.isAfter(endDate!)) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: "La fecha de fin debe ser mayor a la fecha de inicio.",
              icon: Icons.error,
            );
            return;
          }
          int minutesDifferenceRequest =
              endDate!.difference(startDate!).inMinutes;
          if (minutesDifferenceRequest > (24 * 60)) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: 'La cantidad máxima de horas por solicitud es 24.',
              icon: Icons.error_outline,
              duration: 5,
            );
            return;
          }

          ClientsProvider clientProvider = context.read<ClientsProvider>();

          int minutesDifference = endDate!.difference(startDate!).inMinutes;
          double hoursDifference = CodeUtils.minutesToHours(minutesDifference);
          int minRequestHours = 0;
          if (authProvider.webUser.accountInfo.type != 'client') {
            client = clientProvider.allClients.firstWhere(
              (element) =>
                  element.accountInfo.id == newRequestsList.first.clientInfo.id,
            );
            minRequestHours = client!.accountInfo.minRequestHours;
          } else {
            minRequestHours =
                authProvider.webUser.company.accountInfo['min_request_hours'];
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
          // if (authProvider.webUser.accountInfo.type == 'client') {
          //   DateTime startDate = DateTime(
          //     newRequestsList.first.details.startDate.year,
          //     newRequestsList.first.details.startDate.month,
          //     newRequestsList.first.details.startDate.day - 1,
          //     23,
          //     59,
          //   );
          //   if (DateTime.now().isAfter(startDate)) {
          //     LocalNotificationService.showSnackBar(
          //       type: "fail",
          //       message:
          //           "Solo puedes modificar el horario hasta la media noche del día anterior.",
          //       icon: Icons.error,
          //     );
          //     return;
          //   }
          // }
          List<double> hoursIncreasingList = [];
          for (int i = 0; i < newRequestsList.length; i++) {
            newRequestsList[i].details.startDate = DateTime(
              startDate!.year,
              startDate!.month,
              startDate!.day,
              startDate!.hour,
              startDate!.minute,
            );
            newRequestsList[i].details.endDate = DateTime(
              endDate!.year,
              endDate!.month,
              endDate!.day,
              endDate!.hour,
              endDate!.minute,
            );
            hoursIncreasingList.add(
                (hoursDifference - newRequestsList[i].details.totalHours)
                    .toDouble());
            newRequestsList[i].details.totalHours = hoursDifference;
          }

          UiMethods().showLoadingDialog(context: context);
          newRequestsList.sort(
              (a, b) => a.details.startDate.compareTo(b.details.startDate));

          bool resp = await requestsProvider.cloneOrEditRequestsByEvent(
            hoursIncreasingList,
            isEventSelected: isEventSelected,
            requestsList: [...newRequestsList],
            screenSize: screenSize,
            type: widget.type,
            event: newEvent!,
          );
          if (resp) {
            UiMethods().hideLoadingDialog(context: context);
            UiMethods().hideLoadingDialog(context: context);
            if (mounted && widget.isItComeFromDialog!) {
              Navigator.pop(context);
              requestsProvider.showEventDetailsDialog(
                  context, screenSize, newRequestsList.first.eventId);
              requestsProvider.requestsToEditIndexes.clear();
            }

            return;
          }
          UiMethods().hideLoadingDialog(context: context);
        }
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
            widget.type == 'clone-requests'
                ? 'Clonar solicitudes'
                : 'Cambiar horario',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
            ),
          ),
        ),
      ),
    );
  }

  _changeSchedule() {
    DateTime compareDate = DateTime(
      newRequestsList.first.details.startDate.year,
      newRequestsList.first.details.startDate.month,
      newRequestsList.first.details.startDate.day - 1,
      23,
      59,
    );
    return SizedBox(
      width: double.infinity,
      height: screenSize.height * 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Información de las solicitudes a cambiar horario',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          _title('Fecha inicio', true),
          InkWell(
            onTap: !isAdmin && DateTime.now().isAfter(compareDate)
                ? null
                : () async {
                    DateTime? selectedDate = await DateTimePickerDialog.show(
                      screenSize,
                      true,
                      newRequestsList.first.details.startDate,
                      newRequestsList.first.details.startDate,
                      // DateTime.now(),
                    );
                    if (selectedDate == null) return;
                    setState(
                      () {
                        startDate = selectedDate;
                      },
                    );
                  },
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: double.infinity,
              height: screenSize.height * 0.056,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 2,
                    color: !isAdmin && DateTime.now().isAfter(compareDate)
                        ? Colors.grey
                        : Colors.black26,
                    offset: const Offset(2, 2),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CodeUtils.formatDate(
                      startDate ?? createEventProvider.currentStartDate!,
                    ),
                    style: TextStyle(
                      color: !isAdmin && DateTime.now().isAfter(compareDate)
                          ? Colors.grey
                          : Colors.black87,
                      fontSize: screenSize.blockWidth >= 920 ? 14 : 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _title('Fecha fin', false),
          InkWell(
            onTap: () async {
              DateTime? selectedDate = await DateTimePickerDialog.show(
                screenSize,
                true,
                newRequestsList.first.details.endDate,
                newRequestsList.first.details.endDate,
                fromClientEditRequestEndTime:
                    authProvider.webUser.accountInfo.type == "client" &&
                        widget.type != 'clone-requests',
              );
              if (selectedDate == null) return;
              setState(() {
                endDate = selectedDate;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: double.infinity,
              height: screenSize.height * 0.056,
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
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CodeUtils.formatDate(
                      endDate ?? createEventProvider.currentEndDate!,
                    ),
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: screenSize.blockWidth >= 920 ? 14 : 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
              (Map<String, dynamic> status) {
                return DropdownMenuItem(
                  value: status["value"],
                  child: Text(
                    status["name"],
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
            onChanged: selectedStatus["value"] == 0 &&
                    authProvider.webUser.accountInfo.type == 'admin'
                ? null
                : (int? newValue) {
                    selectedStatus = requestsStatus.firstWhere(
                      (element) => element["value"] == newValue,
                    );
                    setState(() {});
                  },
          ),
        ),
      ],
    );
  }

  _cloneRequestsInfo() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _item(
            'Información del nuevo evento al clonar las solicitudes:',
            '',
          ),
          const SizedBox(
            height: 10,
          ),
          CustomTooltip(
            message: 'Nombre: ${newRequestsList[0].eventName}',
            child: _item(
              'Nombre: ',
              newRequestsList.first.eventName,
            ),
          ),
          _item(
            'Hora inicio: ',
            CodeUtils.formatDate(
              newRequestsList.first.details.startDate,
            ).split(" ")[1],
          ),
          _item(
            'Total cargos solicitados: ',
            totalJobs.toString(),
          ),
          CustomTooltip(
            message: 'Cargos solicitados: ${jobs.join(', ')}',
            child: _item(
              'Cargos solicitados:',
              jobs.join(', '),
            ),
          ),
          _item(
            'Colaboradores solicitados:  ',
            '${newRequestsList.length}',
          ),
          _item(
            'Total horas:',
            '$totalHours',
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'Selecciona la fecha en la que deseas clonar las solicitudes seleccionadas.',
            style: TextStyle(
              fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
          _buildStatusSelection(),
          if (!isEventSelected) _buildStartWidget(),
          if (isEventSelected) _buildEventsWidget(),
        ],
      ),
    );
  }

  Widget _buildEventsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: generalInfoProvider.screenSize.height * 0.03,
        ),
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
            onChanged: (Map<String, dynamic>? newValue) {
              if (newValue == null) return;
              selectedEventMap = newValue;
              newEvent = requestsProvider.activeClientEvents.firstWhere(
                (element) => element.id == selectedEventMap.keys.first,
              );
              setState(() {});
            },
            showSearchBox: true,
            emptyBuilder: (context, searchEntry) => const Center(
              child: Text('No se encontraron eventos'),
            ),
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
        _buildStartWidget(),
      ],
    );
  }

  List<Map<String, dynamic>> getItems() {
    List<Map<String, dynamic>> items = [];
    for (Event event in requestsProvider.activeClientEvents) {
      items.add({
        event.id:
            '${event.eventName}:${CodeUtils.formatDate(event.details.startDate)}'
      });
    }
    return items;
  }

  Column _buildStartWidget() {
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
                Text(
                  'Fecha y hora inicio',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                        ? 14
                        : 11,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    newSelectedDate = await DateTimePickerDialog.show(
                      generalInfoProvider.screenSize,
                      true,
                      newRequestsList.first.details.startDate,
                      newRequestsList.first.details.startDate,
                      isTimeEnabled: true,
                    );
                    if (newSelectedDate == null) return;
                    setState(
                      () {
                        selectedDateStart = newSelectedDate;
                      },
                    );
                  },
                  child: Container(
                    width: widget.type == 'clone-requests'
                        ? generalInfoProvider.screenSize.blockWidth * 0.17
                        : double.infinity,
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
                        selectedDateStart ??
                            newRequestsList.first.details.endDate,
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
                    newSelectedDate = await DateTimePickerDialog.show(
                      generalInfoProvider.screenSize,
                      true,
                      newRequestsList.first.details.endDate,
                      newRequestsList.first.details.endDate,
                    );
                    // if (newRequestsList.first.details.startDate
                    //     .isAfter(newSelectedDate!)) {
                    //   LocalNotificationService.showSnackBar(
                    //     type: "fail",
                    //     message:
                    //         "La fecha de inicio debe ser superior a la fecha de inicio de las solicitudes.",
                    //     icon: Icons.error,
                    //   );
                    //   return;
                    // }
                    if (newSelectedDate == null) return;
                    setState(
                      () {
                        selectedDateEnd = newSelectedDate;
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
                        selectedDateEnd ??
                            newRequestsList.first.details.endDate,
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
        if (!isEventSelected)
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

  Column _buildSelectDate(String title, DateTime? selectedDate,
      [bool canEditStartDate = true]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: canEditStartDate ? Colors.black : Colors.grey,
            fontSize:
                generalInfoProvider.screenSize.blockWidth >= 920 ? 14 : 11,
          ),
        ),
        const SizedBox(
          height: 6,
        ),
      ],
    );
  }

  Column _item(String title, String value) {
    return Column(
      children: [
        Text(
          '$title $value',
          maxLines: 1,
          style: TextStyle(
            fontSize: screenSize.blockWidth >= 920
                ? value.isEmpty
                    ? 15
                    : 14
                : 12,
            color: Colors.black,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(
          height: 6,
        ),
      ],
    );
  }

  void _setInitialValues() {
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    requestsProvider = Provider.of<GetRequestsProvider>(context);
    createEventProvider = Provider.of<CreateEventProvider>(context);
    authProvider = context.read<AuthProvider>();

    isAdmin = authProvider.webUser.accountInfo.type == "admin";

    screenSize = generalInfoProvider.screenSize;
    newRequestsList.clear();
    List<Request> auxList = List<Request>.from([...widget.requestsList]);
    for (int index in widget.indexesList) {
      newRequestsList.add(auxList[index].createCopy());
    }
    newRequestsList
        .sort(((a, b) => a.details.startDate.compareTo(b.details.startDate)));
    jobs.add(newRequestsList.first.details.job['name']);
    startDate = newRequestsList.first.details.startDate;
    endDate = newRequestsList.first.details.endDate;
    selectedDateStart = newRequestsList.first.details.startDate;
    selectedDateEnd = newRequestsList.first.details.endDate;
    int statusRequest = newRequestsList.first.details.status;
    if (authProvider.webUser.accountInfo.type != 'admin') {
      requestsStatus = requestsStatus.getRange(1, 3).toList();
    }
    selectedStatus = authProvider.webUser.accountInfo.type != 'admin'
        ? requestsStatus.first
        : requestsStatus
            .where(
              (element) => element["value"] == statusRequest,
            )
            .toList()
            .first;
    for (Request request in newRequestsList) {
      totalHours += request.details.totalHours;
      if (newRequestsList.first.details.job['name'] !=
          request.details.job['name']) {
        totalJobs++;
        jobs.add(request.details.job['name']);
      }
    }

    newEvent = requestsProvider.clientFilteredEvents
        .firstWhere((element) => element.id == newRequestsList.first.eventId);
    selectedEventMap = {
      newEvent!.id:
          '${newEvent!.eventName}:${CodeUtils.formatDate(newEvent!.details.startDate)}'
    };
  }

  Container _title(String title, bool isStartDate) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: screenSize.blockWidth >= 920 ? 14 : 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isStartDate
                ? "Selecciona la fecha de inicio"
                : "Selecciona la fecha de finalización",
            style: TextStyle(
              color: Colors.grey,
              fontSize: screenSize.blockWidth >= 920 ? 12 : 9,
            ),
          ),
        ],
      ),
    );
  }
}
