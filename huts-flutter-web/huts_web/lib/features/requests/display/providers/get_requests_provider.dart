// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/requests/data/datasources/admin/admin_requests_remote_datasource.dart';
import 'package:huts_web/features/requests/data/datasources/get_requests_remote_datasource.dart';
import 'package:huts_web/features/requests/data/repositories/admin/requests_repository_impl.dart';
import 'package:huts_web/features/requests/data/repositories/get_requests_repository_impl.dart';
import 'package:huts_web/features/requests/display/screens/widgets/event_item_widget.dart';
import 'package:huts_web/features/requests/domain/entities/event_entity.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:huts_web/features/requests/domain/use_cases/admin/admin_requests_crud.dart';
import 'package:huts_web/features/requests/domain/use_cases/client/get_events.dart';
import 'package:huts_web/features/requests/domain/use_cases/client/get_requests.dart';
import 'package:huts_web/features/requests/domain/use_cases/client/run_request_action.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/services/employee_services/employee_availability_service.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/use_cases/client/mark_arrival.dart';
import '../../domain/use_cases/client/move_requests.dart';

class GetRequestsProvider with ChangeNotifier {
  List<DateTime> selectedDates = [DateTime.now()];
  List<Event> events = [];
  List<Event> activeClientEvents = [];
  List<Request> allRequests = [];
  List<Request> filteredRequests = [];
  List<Event> filteredEvents = [];
  List<Employee> adminFilteredEmployees = [];
  List<Event> adminAllEvents = [];
  List<Event> adminFilteredEvents = [];
  List<Event> clientFilteredEvents = [];

  List<Request> adminFilteredRequests = [];
  List<Request> clientFilteredRequests = [];

  List<Request> clientAllRequests = [];
  List<Request> adminAllRequests = [];
  List<Map<String, dynamic>> selectedRequestChanges = [];
  List<int> requestsToEditIndexes = [];
  Map<String, dynamic> dateEvents = {};
  bool isExpanded = false;
  String clientEditRequestOptions = 'indications';

  TextEditingController requestSearchController = TextEditingController();
  TextEditingController requestSearchControllerClient = TextEditingController();

  void updateRequestsToEditIndexes(List<int> newIndexes, bool notify) {
    requestsToEditIndexes = [...newIndexes];
    if (notify) notifyListeners();
  }

  void updateDateEvents(Map<String, dynamic> newDateEvent, int eventIndex) {
    dateEvents.values.toList()[eventIndex] = newDateEvent;
    notifyListeners();
  }

  void updateExpanded(bool newValue) {
    isExpanded = newValue;
    notifyListeners();
  }

  void updateDateEvent(List<String> eventsIds) {
    for (String eventId in eventsIds) {
      dateEvents.removeWhere((key, value) => key == eventId);
    }
    notifyListeners();
  }

  String adminRequestsType = "general";
  String clientRequestsType = "generales";

  int selectedAdminCompanyIndex = 0;

  Map<String, dynamic> adminFilteredRequestsInfo = {
    "money": {
      "clients_total": 0,
      "employees_total": 0,
      "difference": 0,
    },
    "requests": {
      "total": 0,
      "for_search": 0,
      "pending": 0,
      "confirmed": 0,
      "active": 0,
      "finalized": 0,
      "canceled": 0,
      "rejected": 0,
    }
  };

  int totalEvents = 0;
  int pendingEvents = 0;
  int finishedEvents = 0;
  int requestedEmployees = 0;
  int totalRequestsPerClient = 0;
  int pendingRequestsPerClient = 0;
  int finishedRequestsPerClient = 0;

  StreamSubscription? eventsStream;
  StreamSubscription? requestsStream;
  StreamSubscription? allRequestsStream;

  bool isShowingDetails = false;

  bool isGettingRequests = false;

  DateTime? adminRequestsStartDate;
  DateTime? adminRequestsEndDate;

  bool requestsSnapshotDone = false;

  void filterAdminRequests(String query) {
    query = query.toLowerCase();
    if (query.isEmpty) {
      adminFilteredRequests = [...adminAllRequests];
      notifyListeners();
      return;
    }
    adminFilteredRequests.clear();
    for (Request request in adminAllRequests) {
      String statusName =
          CodeUtils.getStatusName(request.details.status).toLowerCase();

      if (request.clientInfo.name.toLowerCase().contains(query)) {
        adminFilteredRequests.add(request);
        continue;
      }

      if (request.employeeInfo.names.toLowerCase().contains(query)) {
        adminFilteredRequests.add(request);
        continue;
      }

      if (request.employeeInfo.lastNames.toLowerCase().contains(query)) {
        adminFilteredRequests.add(request);
        continue;
      }

      if (request.details.job["name"].toLowerCase().contains(query)) {
        adminFilteredRequests.add(request);
        continue;
      }

      if (statusName.contains(query)) {
        adminFilteredRequests.add(request);
        continue;
      }

      if (request.eventName.toLowerCase().contains(query)) {
        adminFilteredRequests.add(request);
        continue;
      }
    }
    notifyListeners();
  }

  void filterClientRequests(String query) {
    query = query.toLowerCase();
    if (query.isEmpty) {
      clientFilteredRequests = [...clientAllRequests];
      totalRequestsPerClient = clientFilteredRequests.length;
      pendingRequestsPerClient = clientFilteredRequests
          .where((element) => element.details.status == 0)
          .length;
      finishedRequestsPerClient = clientFilteredRequests
          .where((element) => element.details.status == 4)
          .length;
      notifyListeners();
      return;
    }
    clientFilteredRequests.clear();
    for (Request request in clientAllRequests) {
      String statusName =
          CodeUtils.getStatusName(request.details.status).toLowerCase();

      if (request.employeeInfo.names.toLowerCase().contains(query)) {
        clientFilteredRequests.add(request);
        continue;
      }

      if (request.employeeInfo.lastNames.toLowerCase().contains(query)) {
        clientFilteredRequests.add(request);
        continue;
      }

      if (request.details.job["name"].toLowerCase().contains(query)) {
        clientFilteredRequests.add(request);
        continue;
      }

      if (statusName.contains(query)) {
        clientFilteredRequests.add(request);
        continue;
      }

      if (request.eventName.toLowerCase().contains(query)) {
        clientFilteredRequests.add(request);
        continue;
      }
    }
    totalRequestsPerClient = clientFilteredRequests.length;
    pendingRequestsPerClient = clientFilteredRequests
        .where((element) => element.details.status == 0)
        .length;
    finishedRequestsPerClient = clientFilteredRequests
        .where((element) => element.details.status == 4)
        .length;
    notifyListeners();
  }

  void initFilteredRequestsInfo() {
    adminFilteredRequestsInfo = {
      "money": {
        "clients_total": 0,
        "employees_total": 0,
        "difference": 0,
      },
      "requests": {
        "total": 0,
        "for_search": 0,
        "pending": 0,
        "confirmed": 0,
        "active": 0,
        "finalized": 0,
        "canceled": 0,
        "rejected": 0,
      }
    };
  }

  void filterRequests(String query) {
    String finalQuery = query.toLowerCase();
    if (query.isEmpty) {
      filteredRequests = [...allRequests];
      notifyListeners();
      return;
    }

    filteredRequests.clear();
    for (Request request in allRequests) {
      RequestEmployeeInfo employeeInfo = request.employeeInfo;
      String name =
          CodeUtils.getFormatedName(employeeInfo.names, employeeInfo.lastNames)
              .toLowerCase();
      String job = request.details.job["name"].toLowerCase();
      String startDate = CodeUtils.formatDate(request.details.startDate);
      String endDate = CodeUtils.formatDate(request.details.endDate);
      String status =
          CodeUtils.getStatusName(request.details.status).toLowerCase();

      if (name.contains(finalQuery)) {
        filteredRequests.add(request);
        continue;
      }
      if (job.contains(finalQuery)) {
        filteredRequests.add(request);
        continue;
      }
      if (startDate.contains(finalQuery)) {
        filteredRequests.add(request);
        continue;
      }
      if (endDate.contains(finalQuery)) {
        filteredRequests.add(request);
        continue;
      }
      if (status.contains(finalQuery)) {
        filteredRequests.add(request);
        continue;
      }
    }
    notifyListeners();
  }

  Future<bool> cloneOrEditRequestsByEvent(
    List<double>? hoursIncreasingList, {
    required ScreenSize screenSize,
    required List<Request> requestsList,
    required String type,
    required bool isEventSelected,
    required Event event,
  }) async {
    AdminRequestsRepositoryImpl repositoryImpl = AdminRequestsRepositoryImpl(
      AdminRequestsRemoteDatasourceImpl(),
    );
    List<double> hoursMaxIncrementList = [];
    (bool, double)? isEmployeeAvailability = (true, 0.0);
    List<Request> requestIsNotEmployeeAvailability = [];
    bool itsConfirmed = false;
    if (!isEventSelected) {}
    await Future.forEach(
      requestsList,
      (Request request) async {
        if (request.details.status > 0) {
          isEmployeeAvailability = await EmployeeAvailabilityService.get(
            request.details.startDate,
            request.details.endDate,
            request.employeeInfo.id,
            request.id,
            type,
          );
        }
        if (isEmployeeAvailability == null ||
            (isEmployeeAvailability != null && !isEmployeeAvailability!.$1)) {
          requestIsNotEmployeeAvailability.add(request);
          hoursMaxIncrementList.add(isEmployeeAvailability!.$2);
        } else {
          int indexRequest =
              requestsList.indexWhere((element) => element.id == request.id);
          hoursIncreasingList!.remove(indexRequest);
        }
      },
    );

    if (requestIsNotEmployeeAvailability.isNotEmpty) {
      String stringToShow = '';
      List<String> data = [];
      for (int i = 0; i < requestIsNotEmployeeAvailability.length; i++) {
        Request request = requestIsNotEmployeeAvailability[i];
        bool isRequestActive = request.details.status == 3;
        int index =
            requestsList.indexWhere((element) => element.id == request.id);
        if (index != -1) requestsList[index].details.status = 0;
        String fullName = request.details.status == 0
            ? ' '
            : '${request.employeeInfo.names} ${request.employeeInfo.lastNames}';
        if (isRequestActive) {
          data.add(
              ' - $fullName: \nIba a ${hoursIncreasingList![i] > 0 ? 'aumentar' : 'disminuir'}  el tiempo de una solicitud activa ${hoursIncreasingList[i].abs()} horas pero no se puede, debido a que se encuentra en estado activa.\n');
        } else {
          data.add(
              ' - $fullName: \nIba a ${hoursIncreasingList![i] > 0 ? 'aumentar' : 'disminuir'}  el tiempo de la solicitud de: ${request.employeeInfo.names} ${request.employeeInfo.lastNames}, ${hoursIncreasingList[i].abs()} horas pero no se puede, debido a que se cruza con otra.\n'); //, maximo puede aumentar ${hoursMaxIncrementList[i]}\n');
        }
      }
      stringToShow = data.join('\n');

      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) false;
      itsConfirmed = await confirm(
        globalContext!,
        title: SizedBox(
          width: screenSize.blockWidth * 0.3,
          child: Center(
            child: Text(
              type != 'clone-requests'
                  ? 'El nuevo horario seleccionado interfiere con las solicitudes de uno o más colaboradores.'
                  : 'El horario al clonar las solicitudes interfiere con las solicitudes de uno o más colaboradores.',
              style: TextStyle(
                color: UiVariables.primaryColor,
              ),
            ),
          ),
        ),
        content: SizedBox(
          width: screenSize.blockWidth * 0.3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (type != 'clone-requests')
                    ? 'Al continuar, las solicitudes activas no serán modificadas y las demás se les asignará un nuevo colaborador.'
                    : 'Al continuar las solicitudes que interfieren con otras se les asignará a un nuevo colaborador.',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // if (type != 'clone-requests')
              RichText(
                text: TextSpan(
                  text: '\nDetalle de cruce de solicitudes:\n\n',
                  children: <TextSpan>[
                    TextSpan(
                      text: stringToShow,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      if (!itsConfirmed) return false;
    }
    if (type != 'clone-requests') {
      for (Request request in requestIsNotEmployeeAvailability) {
        requestsList.removeWhere(
          (element) =>
              element.id == request.id &&
              (request.details.status == 3 || request.details.status == 4),
        );
      }
    }
    if (type == 'clone-requests') {
      for (Request request in requestsList) {
        bool withOutEmployee = request.employeeInfo.id == '';
        if (withOutEmployee) {
          int index =
              requestsList.indexWhere((element) => element.id == request.id);
          if (index != -1) requestsList[index].details.status = 0;
        }
      }
    }
    if (requestsList.isEmpty && type != 'clone-requests') {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message:
            "No puede realizar la acción, ya que una o más solicitudes seleccioandas se encuentran activas.",
        icon: Icons.check,
      );
      return true;
    }

    String resp = await repositoryImpl.cloneOrEditRequestsByEvent(
      requestsList,
      type,
      isEventSelected,
      event,
    );
    //  String resp = 'ok';
    if (resp == 'ok') {
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Acción realizada correctamente",
        icon: Icons.check,
      );
      return true;
    }
    if (resp == 'client-not-exists') {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "El cliente para quién se clonarán las solicitudes no existe.",
        icon: Icons.error,
        duration: 7,
      );
    }
    if (resp == 'null-context') {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrio algo inesperado.",
        icon: Icons.error,
      );
    }
    if (resp == 'job-not-exists') {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message:
            "Uno de los cargos con los que clonará las solicitudes no existe.",
        icon: Icons.error,
        duration: 7,
      );
    }
    return false;
  }

  void updateDetailsStatus(
      bool newValue, ScreenSize screenSize, String eventId) {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;
    if (newValue) {
      showEventDetailsDialog(globalContext, screenSize, eventId);
      return;
    }
    Navigator.of(globalContext).pop();
    requestsToEditIndexes.clear();
    return;
  }

  void getEventsOrFail(
      String clientId, List<DateTime> dates, BuildContext context) {
    GetRequestRepositoryImpl repositoryImpl = GetRequestRepositoryImpl(
      GetRequestsRemoteDatasourceImpl(),
    );

    GetRequestsProvider provider = Provider.of<GetRequestsProvider>(
      context,
      listen: false,
    );

    GetEvents(repositoryImpl).call(
      clientId: clientId,
      filterDates: dates,
      requestsProvider: provider,
    );
  }

  void getAllRequestOrFail(
      {required List<DateTime> dates,
      required BuildContext context,
      required String nameTab,
      String idClient = ''}) {
    GetRequestRepositoryImpl repositoryImpl = GetRequestRepositoryImpl(
      GetRequestsRemoteDatasourceImpl(),
    );

    GetRequestsProvider provider = Provider.of<GetRequestsProvider>(
      context,
      listen: false,
    );

    GetRequests(repositoryImpl).getAllRequests(
      filterDates: dates,
      provider: provider,
      nameTab: nameTab,
      idClient: idClient,
    );
  }

  void updateFilteredEvent(List<Event> newEvents, [bool notify = true]) {
    filteredEvents = [...newEvents];
    if (notify) notifyListeners();
  }

  void getRequestsOrFail(Event event, BuildContext context) {
    isGettingRequests = true;
    GetRequestRepositoryImpl repositoryImpl = GetRequestRepositoryImpl(
      GetRequestsRemoteDatasourceImpl(),
    );

    GetRequestsProvider provider = Provider.of<GetRequestsProvider>(
      context,
      listen: false,
    );

    GetRequests(repositoryImpl).call(
      event: event,
      provider: provider,
    );
  }

  Future<void> getActiveEvents(String clientId, BuildContext context) async {
    GetRequestRepositoryImpl repositoryImpl = GetRequestRepositoryImpl(
      GetRequestsRemoteDatasourceImpl(),
    );

    GetRequestsProvider provider =
        Provider.of<GetRequestsProvider>(context, listen: false);

    await GetEvents(repositoryImpl).getActiveClientEvents(clientId, provider);
  }

  void updateEvents(List<Event> newEvents) {
    events = [...newEvents];
    adminFilteredEvents = [...newEvents];
    clientFilteredEvents = [...newEvents];
    totalEvents = events.length;
    filteredEvents = [...newEvents];
    finishedEvents = events.where((event) => event.details.status == 4).length;

    pendingEvents = events
        .where(
            (event) => event.details.status != 4 && event.details.status != 5)
        .length;

    requestedEmployees = 0;

    for (Event event in events) {
      requestedEmployees += event.employeesInfo.neededEmployees;
    }

    notifyListeners();
  }

  void updateActiveEvents(List<Event> newEvents) {
    activeClientEvents = [...newEvents];
    //notifyListeners();
  }

  void updateRequests(List<Request> newRequests) {
    BuildContext? context = NavigationService.getGlobalContext();
    if (context == null) return;
    bool isAdmin =
        context.read<AuthProvider>().webUser.accountInfo.type == 'admin';
    allRequests = [...newRequests];
    adminAllRequests = [...allRequests];
    adminFilteredRequests = [...allRequests];
    filteredRequests = [...allRequests];
    requestsSnapshotDone = true;
    isGettingRequests = false;
    if (!isAdmin) {
      clientAllRequests = [
        ...allRequests.where((element) =>
            element.clientInfo.id ==
            context.read<AuthProvider>().webUser.company.id)
      ];
      clientFilteredRequests = [...clientAllRequests];
      totalRequestsPerClient = clientFilteredRequests.length;
      pendingRequestsPerClient = clientFilteredRequests
          .where((element) => element.details.status == 0)
          .length;
      finishedRequestsPerClient = clientFilteredRequests
          .where((element) => element.details.status == 4)
          .length;
    }

    if (requestSearchController.text.isNotEmpty) {
      filterAdminRequests(requestSearchController.text);
      return;
    }

    if (requestSearchControllerClient.text.isNotEmpty) {
      filterClientRequests(requestSearchControllerClient.text);
      return;
    }

    notifyListeners();
  }

  TableCalendarProperties calendarProperties = TableCalendarProperties(
    calendarFormat: CalendarFormat.month,
    rangeSelectionMode: RangeSelectionMode.toggledOn,
    focusedDay: DateTime.now(),
    firstDay: DateTime(2020, 10, 16),
    lastDay: DateTime.now().add(const Duration(days: 365)),
    selectedDay: null,
    rangeStart: null,
    rangeEnd: null,
  );

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    calendarProperties.selectedDay = selectedDay;
    calendarProperties.focusedDay = focusedDay;
    calendarProperties.rangeStart = null;
    calendarProperties.rangeEnd = null;
    calendarProperties.rangeSelectionMode = RangeSelectionMode.toggledOn;
    notifyListeners();
  }

  void onRangeSelected(String clientId, DateTime? start, DateTime? end,
      DateTime focusedDay, BuildContext context) {
    calendarProperties.selectedDay = null;
    calendarProperties.focusedDay = focusedDay;
    calendarProperties.rangeStart = start;
    calendarProperties.rangeEnd = end;
    calendarProperties.rangeSelectionMode = RangeSelectionMode.toggledOn;
    notifyListeners();

    if (start == null) return;

    end ??= DateTime(
      start.year,
      start.month,
      start.day,
      23,
      59,
    );

    if (end.day != start.day) {
      end = DateTime(
        end.year,
        end.month,
        end.day,
        23,
        59,
      );
    }

    getEventsOrFail(clientId, [start, end], context);
    getAllRequestOrFail(
      dates: [
        calendarProperties.rangeStart!,
        calendarProperties.rangeEnd ?? end,
      ],
      context: context,
      nameTab: clientRequestsType == 'General' ? 'General' : 'Por solicitud',
      idClient: context.read<AuthProvider>().webUser.company.id,
    );
    getAdminRequestsValuesByRange();
  }

  void onFormatChanged(CalendarFormat format) {
    calendarProperties.calendarFormat = format;
    notifyListeners();
  }

  void showEventDetailsDialog(
    BuildContext globalContext,
    ScreenSize screenSize,
    String eventId,
  ) {
    bool isAdmin = Provider.of<AuthProvider>(globalContext, listen: false)
            .webUser
            .accountInfo
            .type ==
        "admin";

    int eventIndex = (isAdmin)
        ? adminFilteredEvents
            .indexWhere((Event eventItem) => eventItem.id == eventId)
        : events.indexWhere((Event eventItem) => eventItem.id == eventId);

    if (eventIndex == -1) return;

    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return WillPopScope(
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: const EdgeInsets.all(0),
            title: EventDetailDialog(
              screenSize: screenSize,
              event: (isAdmin)
                  ? adminFilteredEvents[eventIndex]
                  : events[eventIndex],
              isAdmin: isAdmin,
            ),
          ),
          onWillPop: () async => false,
        );
      },
    );
  }

  Future<void> saveRequestActionChanges(
      Map<String, dynamic> actionInfo, ScreenSize screenSize,
      [bool isFromDialog = false]) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    bool useContext = globalContext != null;
    AuthProvider? authProvider;

    if (useContext) {
      UiMethods().showLoadingDialog(context: globalContext);
      authProvider = Provider.of<AuthProvider>(globalContext, listen: false);
    }
    GetRequestRepositoryImpl repositoryImpl = GetRequestRepositoryImpl(
      GetRequestsRemoteDatasourceImpl(),
    );

    bool resp = await RunRequestAction(repositoryImpl).call(
      actionInfo: actionInfo,
      authProvider: authProvider,
    );

    if (useContext) {
      UiMethods().hideLoadingDialog(context: globalContext);
    }

    if (!resp) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "No se pudo realizar la acción, intenta nuevamente",
        icon: Icons.error_outline,
      );
      return;
    }

    if (useContext) {
      UiMethods().hideLoadingDialog(context: globalContext);
      //Necesary to update data table rowsPerPage and update event info//
      if (actionInfo["type"] != "clone" && isFromDialog) {
        UiMethods().hideLoadingDialog(context: globalContext);
        showEventDetailsDialog(
            globalContext, screenSize, actionInfo["event"].id);
      }
    }
    if (actionInfo["type"] == 'edit') {
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Se modificaron las indicaciones correctamente",
        icon: Icons.check,
      );
    } else {
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Acción realizada correctamente",
        icon: Icons.check,
      );
    }
  }

  void onAdminRangeSelected(DateTime? start, DateTime? end,
      BuildContext context, String tabName, String clientId) {
    adminRequestsStartDate = start;
    adminRequestsEndDate = end;
    if (start == null) return;

    start = DateTime(
      start.year,
      start.month,
      start.day,
      00,
      00,
    );

    end ??= DateTime(
      start.year,
      start.month,
      start.day,
      23,
      59,
    );

    if (end.day != start.day) {
      end = DateTime(
        end.year,
        end.month,
        end.day,
        23,
        59,
      );
    }

    getAllRequestOrFail(
      dates: [start, end],
      context: context,
      nameTab: tabName,
      idClient: clientId,
    );

    getAdminRequestsValuesByRange();
  }

  Future<void> getAdminRequestsValuesByRange() async {
    if (!requestsSnapshotDone) {
      Future.delayed(
        const Duration(seconds: 1),
        () async => getAdminRequestsValuesByRange(),
      );
    }

    requestsSnapshotDone = false;

    initFilteredRequestsInfo();
    for (Request request in adminFilteredRequests) {
      adminFilteredRequestsInfo["money"]["clients_total"] +=
          request.details.fare.totalClientPays.roundToDouble();
      adminFilteredRequestsInfo["money"]["employees_total"] +=
          request.details.fare.totalToPayEmployee.roundToDouble();

      if (request.details.status == 0) {
        adminFilteredRequestsInfo["requests"]["for_search"]++;
        continue;
      }

      if (request.details.status == 1) {
        adminFilteredRequestsInfo["requests"]["pending"]++;
        // if (request.employeeInfo.id.isEmpty) {
        //   adminFilteredRequestsInfo["requests"]["for_search"]++;
        // }
        continue;
      }

      if (request.details.status == 2) {
        adminFilteredRequestsInfo["requests"]["confirmed"]++;
        continue;
      }

      if (request.details.status == 3) {
        adminFilteredRequestsInfo["requests"]["active"]++;
        continue;
      }

      if (request.details.status == 4) {
        adminFilteredRequestsInfo["requests"]["finalized"]++;
        continue;
      }
      if (request.details.status == 5) {
        adminFilteredRequestsInfo["requests"]["canceled"]++;
        continue;
      }
      if (request.details.status == 6) {
        adminFilteredRequestsInfo["requests"]["rejected"]++;
        continue;
      }
    }

    adminFilteredRequestsInfo["money"]["difference"] =
        adminFilteredRequestsInfo["money"]["clients_total"] -
            adminFilteredRequestsInfo["money"]["employees_total"];

    notifyListeners();
  }

  // getAdminfilteredEmployees(
  //     List<Employee> allEmployees, ClientEntity clientEntity) {
  //   //TOdO: add client jobs employees to the list

  //   //for (Employee employee in allEmployees) {
  //   // clientEntity.jobs.forEach((key, value) {
  //   //   if (employee.jobs.any((element) => false)) {}
  //   // });
  //   // }
  //   adminFilteredEmployees = [...allEmployees];
  //   notifyListeners();
  // }

  Future<void> deleteRequest(Request request) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();

      if (globalContext == null) return;

      bool itsConfirmed = await confirm(
        globalContext,
        title: Text(
          "Eliminar solicitud",
          style: TextStyle(
            color: UiVariables.primaryColor,
          ),
        ),
        content: SizedBox(
          width: 350,
          child: RichText(
            text: TextSpan(
              text: request.employeeInfo.names != ''
                  ? '¿Quieres eliminar la solicitud del colaborador '
                  : '¿Quieres eliminar la solicitud',
              children: <TextSpan>[
                TextSpan(
                  text:
                      '${request.employeeInfo.names} ${request.employeeInfo.lastNames}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ', para el evento '),
                TextSpan(
                  text: '${request.eventName}?.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' Esta acción no se puede revertir.'),
              ],
            ),
          ),
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

      AdminRequestsRepositoryImpl repositoryImpl = AdminRequestsRepositoryImpl(
        AdminRequestsRemoteDatasourceImpl(),
      );

      UiMethods().showLoadingDialog(context: globalContext);
      bool itsDeleted = await AdminRequestsCrud(repositoryImpl).delete(request);
      UiMethods().hideLoadingDialog(context: globalContext);

      if (!itsDeleted) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al eliminar la solicitud",
          icon: Icons.error_outline,
        );
        return;
      }

      adminFilteredRequests.removeWhere((element) => element.id == request.id);

      //Set requests info money values//

      adminFilteredRequestsInfo["money"]["clients_total"] -=
          request.details.fare.totalClientPays;
      adminFilteredRequestsInfo["money"]["employees_total"] -=
          request.details.fare.totalToPayEmployee;
      adminFilteredRequestsInfo["money"]["difference"] =
          adminFilteredRequestsInfo["money"]["clients_total"] -
              adminFilteredRequestsInfo["money"]["employees_total"];

      //Set requests info requests values//

      adminFilteredRequestsInfo["requests"]["total"]--;

      if (request.details.status == 0) {
        adminFilteredRequestsInfo["requests"]["for_search"]--;
      }

      if (request.details.status == 1) {
        adminFilteredRequestsInfo["requests"]["pending"]--;
      }

      if (request.details.status == 2) {
        adminFilteredRequestsInfo["requests"]["confirmed"]--;
      }

      if (request.details.status == 3) {
        adminFilteredRequestsInfo["requests"]["active"]--;
      }

      if (request.details.status == 4) {
        adminFilteredRequestsInfo["requests"]["finalized"]--;
      }
      if (request.details.status == 5) {
        adminFilteredRequestsInfo["requests"]["canceled"]--;
      }
      if (request.details.status == 6) {
        adminFilteredRequestsInfo["requests"]["rejected"]--;
      }

      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Solicitud eliminada correctamente",
        icon: Icons.check,
      );

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsProvider, deleteRequest, error: $e",
        );
      }

      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al eliminar la solicitud",
        icon: Icons.error_outline,
      );
    }
  }

  Future<Event?> getRequestEvent(Request request) async {
    try {
      Event? eventResp;
      AdminRequestsRepositoryImpl adminRequestsRepositoryImpl =
          AdminRequestsRepositoryImpl(
        AdminRequestsRemoteDatasourceImpl(),
      );

      final resp = await AdminRequestsCrud(adminRequestsRepositoryImpl)
          .getEvent(request.eventId);

      resp.fold((Failure fail) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al obtener la información de la solicitud",
          icon: Icons.error_outline,
        );
      }, (Event event) {
        eventResp = event;
      });

      return eventResp;
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsProvider, getRequestEvent, error: $e",
        );
      }
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al obtener la información de la solicitud",
        icon: Icons.error_outline,
      );
      return null;
    }
  }

  Future<bool> markArrival(
    Request request,
    ScreenSize screenSize,
  ) async {
    try {
      GetRequestRepositoryImpl repository = GetRequestRepositoryImpl(
        GetRequestsRemoteDatasourceImpl(),
      );
      bool itsConfirmed = false;
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) false;
      itsConfirmed = await confirm(
        globalContext!,
        title: SizedBox(
          width: screenSize.blockWidth * 0.2,
          child: Center(
            child: Text(
              'Marcar llegada de colaborador',
              style: TextStyle(
                color: UiVariables.primaryColor,
              ),
            ),
          ),
        ),
        content: SizedBox(
          width: screenSize.blockWidth * 0.2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: '¿Seguro quiere marcar la llegada del colaborador ',
                  children: <TextSpan>[
                    TextSpan(
                      text:
                          '${request.employeeInfo.names} ${request.employeeInfo.lastNames}?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      if (!itsConfirmed) return false;
      return await MarkArrival(repository)
          .call(idRequest: request.id, request: request);
    } catch (e) {
      if (kDebugMode) {
        print("GetRequestsProvider, markArrival error: $e");
      }
      return false;
    }
  }

  Future<bool> updateRequestByAdmin(
      Map<String, dynamic> data, bool isEventSelected) async {
    try {
      AdminRequestsRepositoryImpl repository = AdminRequestsRepositoryImpl(
        AdminRequestsRemoteDatasourceImpl(),
      );
      bool resp = await AdminRequestsCrud(repository)
          .updateRequest(data, isEventSelected);
      if (resp) {
        if (adminRequestsStartDate != null) {
          await getAdminRequestsValuesByRange();
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print("GetRequestsProvider, updateRequestByAdmin error: $e");
      }
      return false;
    }
  }

  Future<void> getRequestHistorical(String requestId) async {
    try {
      AdminRequestsRepositoryImpl repository = AdminRequestsRepositoryImpl(
        AdminRequestsRemoteDatasourceImpl(),
      );

      final resp =
          await AdminRequestsCrud(repository).getRequestHistorical(requestId);

      resp.fold(
        (Failure failure) => LocalNotificationService.showSnackBar(
          type: "fail",
          message: "No se pudo obtener el historial de la solicitud",
          icon: Icons.error_outline,
        ),
        (List<Map<String, dynamic>> changes) {
          selectedRequestChanges = [...changes];
          notifyListeners();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print("GetRequestsProvider, getRequestHistorical error: $e");
      }
    }
  }

  Future<Map<String, dynamic>> getClientPrintEvents(
    String clientId,
    DateTime startDate,
    DateTime endDate,
    BuildContext context,
  ) async {
    UiMethods().showLoadingDialog(context: context);

    GetRequestRepositoryImpl repositoryImpl = GetRequestRepositoryImpl(
      GetRequestsRemoteDatasourceImpl(),
    );

    final resp = await GetEvents(repositoryImpl)
        .getClientPrintEvents(clientId, startDate, endDate);

    UiMethods().hideLoadingDialog(context: context);

    return resp.fold(
      (Failure serverFailure) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al obtener la información",
          icon: Icons.error_outline,
        );
        if (kDebugMode) {
          print("getClientPrintEvents error: ${serverFailure.errorMessage}");
        }
        return {};
      },
      (Map<String, dynamic> events) {
        return events;
      },
    );
  }

  Future<bool> moveRequests(
    List<Request> requestList,
    Map<String, dynamic> updateData,
    ScreenSize screenSize,
    bool isEventSelected,
  ) async {
    try {
      GetRequestRepositoryImpl repositoryImpl = GetRequestRepositoryImpl(
        GetRequestsRemoteDatasourceImpl(),
      );
      (bool, double)? isEmployeeAvailability = (true, 0.0);
      List<Request> requestIsNotEmployeeAvailability = [];
      bool itsConfirmed = false;

      await Future.forEach(
        requestList,
        (Request request) async {
          if (request.details.status > 0) {
            isEmployeeAvailability = await EmployeeAvailabilityService.get(
              request.details.startDate,
              request.details.endDate,
              request.employeeInfo.id,
              request.id,
              'move-requests',
            );
          }
          if (isEmployeeAvailability == null ||
              (isEmployeeAvailability != null && !isEmployeeAvailability!.$1)) {
            requestIsNotEmployeeAvailability.add(request);
          }
        },
      );
      for (int i = 0; i < requestList.length; i++) {
        double totalHours = CodeUtils.minutesToHours(requestList[i]
            .details
            .endDate
            .difference(requestList[i].details.startDate)
            .inMinutes);
        requestList[i].details.totalHours = totalHours;
      }
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) false;
      if (requestIsNotEmployeeAvailability.isNotEmpty) {
        itsConfirmed = await confirm(
          globalContext!,
          title: SizedBox(
            width: screenSize.blockWidth * 0.3,
            child: Center(
              child: Text(
                'Uno o más de los colaboradores no está disponible para la fecha que desea mover la solicitud.',
                style: TextStyle(
                  color: UiVariables.primaryColor,
                ),
              ),
            ),
          ),
          content: SizedBox(
            width: screenSize.blockWidth * 0.3,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Al continuar, a las solicitudes que cruzan horario con otra se les asiganará un nuevo colaborador.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // if (type != 'clone-requests')
              ],
            ),
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
        if (!itsConfirmed) return false;
      }
      for (Request request in requestIsNotEmployeeAvailability) {
        int index = requestList.indexWhere(
          (element) => element.id == request.id,
        );
        if (index != -1) {
          if (request.details.status == 2) {
            updateData['previous_event']['employees_info']
                ['employees_accepted']--;
          }
          if (request.details.status == 3) {
            updateData['previous_event']['employees_info']
                ['employees_arrived']--;
          }
          requestList[index].details.status = 0;
        }
      }

      requestList
          .sort((a, b) => a.details.startDate.compareTo(b.details.startDate));
      bool resp = await MoveRequests(repositoryImpl).call(
        requestList: requestList,
        updateData: updateData,
        isEventSelected: isEventSelected,
      );

      return resp;
    } catch (e) {
      if (kDebugMode) {
        print('GetRequestsProvider, moveRequests $e');
      }
      return false;
    }
  }
}

class TableCalendarProperties {
  CalendarFormat calendarFormat;
  RangeSelectionMode rangeSelectionMode;
  DateTime focusedDay;
  DateTime firstDay;
  DateTime lastDay;
  DateTime? selectedDay;
  DateTime? rangeStart;
  DateTime? rangeEnd;

  TableCalendarProperties({
    required this.calendarFormat,
    required this.rangeSelectionMode,
    required this.focusedDay,
    required this.firstDay,
    required this.lastDay,
    required this.selectedDay,
    required this.rangeStart,
    required this.rangeEnd,
  });
}
