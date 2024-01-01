// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';

import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/activity_service.dart';
import 'package:huts_web/core/services/employee_services/employee_availability_service.dart';
import 'package:huts_web/core/services/fares/job_fare_service.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/use_cases_params/activity_params.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/requests/data/models/event_model.dart';
import 'package:huts_web/features/requests/data/models/request_model.dart';
import 'package:huts_web/features/requests/display/providers/create_event_provider.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/domain/entities/event_entity.dart';

import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/code/code_utils.dart';
import '../../../auth/domain/entities/company.dart';
import '../../../clients/display/provider/clients_provider.dart';
import '../../../clients/domain/entities/client_entity.dart';
import '../../../general_info/data/models/other_info_model.dart';
import '../../../general_info/display/providers/general_info_provider.dart';
import '../../domain/entities/request_entity.dart';

abstract class GetRequestsRemoteDatasource {
  Future<void> listenEvents(
    String clientId,
    List<DateTime> dates,
    GetRequestsProvider requestsProvider,
  );
  Future<void> listenEventRequests(
    Event event,
    GetRequestsProvider provider,
  );
  Future<void> listenAllRequests({
    required GetRequestsProvider requestsProvider,
    required List<DateTime> dates,
    required String nameTab,
    String idClient = '',
  });

  Future<Map<String, dynamic>> getClientPrintEvents(
    String clientId,
    DateTime startDate,
    DateTime endDate,
  );

  Future<bool> markArrival(String idRequest, Request request);
  Future<bool> moveRequests(
    List<Request> requestList,
    Map<String, dynamic> updateData,
    bool isEvenselected,
  );

  Future<void> getActiveEvents(String clientId, GetRequestsProvider provider);

  Future<bool> runTimeAction(Map<String, dynamic> actionInfo);
  Future<bool> runCloneAction(Map<String, dynamic> actionInfo);
  Future<bool> runCloneToEventAction(Map<String, dynamic> actionInfo);
  Future<bool> runEditAction(Map<String, dynamic> actionInfo,
      {bool fromClone = false});
  Future<bool> runFavoriteAction(
      Map<String, dynamic> actionInfo, AuthProvider authProvider);
  Future<bool> runBlockAction(
      Map<String, dynamic> actionInfo, AuthProvider authProvider);
  Future<bool> runRateAction(Map<String, dynamic> actionInfo);
}

class GetRequestsRemoteDatasourceImpl implements GetRequestsRemoteDatasource {
  @override
  Future<Map<String, dynamic>> getClientPrintEvents(
      String clientId, DateTime startDate, DateTime endDate) async {
    try {
      Map<String, dynamic> events = {};

      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("requests")
          .where("client_info.id", isEqualTo: clientId)
          .where("details.start_date", isGreaterThanOrEqualTo: startDate)
          .where("details.start_date", isLessThanOrEqualTo: endDate)
          .get();

      await Future.forEach(
        querySnapshot.docs,
        (DocumentSnapshot requestDoc) async {
          Request request =
              RequestModel.fromMap(requestDoc.data() as Map<String, dynamic>);

          if (request.employeeInfo.id.isNotEmpty) {
            DocumentSnapshot employeeDoc = await FirebaseServices.db
                .collection("employees")
                .doc(request.employeeInfo.id)
                .get();

            Map<String, dynamic> employeeData =
                employeeDoc.data() as Map<String, dynamic>;

            bool hasFoodDoc = employeeData["documents"]
                    .containsKey("manipulacion_de_alimentos") &&
                employeeData["documents"]["manipulacion_de_alimentos"]
                        ["file_url"] !=
                    "";

            request.details.job["food_doc"] = (hasFoodDoc)
                ? employeeData["documents"]["manipulacion_de_alimentos"]
                    ["file_url"]
                : "";
          }

          if (events.containsKey(request.eventId)) {
            events[request.eventId]["requests"].add(request);
          } else {
            events[request.eventId] = {
              "id": request.eventId,
              "name": request.eventName,
              "requests": [request],
            };
          }
        },
      );

      return events;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<void> listenAllRequests({
    required GetRequestsProvider requestsProvider,
    required List<DateTime> dates,
    required String nameTab,
    String idClient = '',
  }) async {
    try {
      requestsProvider.requestsSnapshotDone = false;
      await requestsProvider.requestsStream?.cancel();
      Query query;
      dates[1] = DateTime(
        dates[1].year,
        dates[1].month,
        dates[1].day,
        23,
        59,
      );

      DocumentSnapshot doc =
          await FirebaseServices.db.collection('info').doc('other_info').get();
      OtherInfoModel otherInfo =
          OtherInfoModel.fromMap(doc.data() as Map<String, dynamic>);

      Map<String, dynamic> systemRoles = otherInfo.systemRoles;
      BuildContext? context = NavigationService.getGlobalContext();

      if (nameTab == 'Generales') {
        if (context != null) {
          String webUserSubtype =
              context.read<AuthProvider>().webUser.accountInfo.subtype;

          String webUserType =
              context.read<AuthProvider>().webUser.accountInfo.type;

          if (webUserType == "admin" &&
              systemRoles["admin"].containsKey(webUserSubtype) &&
              systemRoles["admin"][webUserSubtype].containsKey("client_id")) {
            String clientId = systemRoles["admin"][webUserSubtype]["client_id"];

            query = FirebaseServices.db
                .collection("requests")
                .where("details.start_date", isGreaterThanOrEqualTo: dates[0])
                .where("details.start_date", isLessThanOrEqualTo: dates[1])
                .where("client_info.id", isEqualTo: clientId);
          } else {
            query = FirebaseServices.db
                .collection("requests")
                .where("details.start_date", isGreaterThanOrEqualTo: dates[0])
                .where(
                  "details.start_date",
                  isLessThanOrEqualTo: dates[1],
                );
          }
        } else {
          query = FirebaseServices.db
              .collection("requests")
              .where("details.start_date", isGreaterThanOrEqualTo: dates[0])
              .where(
                "details.start_date",
                isLessThanOrEqualTo: dates[1],
              );
        }
      } else if (nameTab == 'Por cliente' || nameTab == 'Por solicitud') {
        query = FirebaseServices.db
            .collection("requests")
            .where(
              "client_info.id",
              isEqualTo: idClient,
            )
            .where("details.start_date", isGreaterThanOrEqualTo: dates[0])
            .where(
              "details.start_date",
              isLessThanOrEqualTo: dates[1],
            );
        listenEvents(idClient, dates, requestsProvider);
      } else {
        if (context != null) {
          String webUserSubtype =
              context.read<AuthProvider>().webUser.accountInfo.subtype;

          String webUserType =
              context.read<AuthProvider>().webUser.accountInfo.type;

          if (webUserType == "admin" &&
              systemRoles["admin"].containsKey(webUserSubtype) &&
              systemRoles["admin"][webUserSubtype].containsKey("client_id")) {
            String clientId = systemRoles["admin"][webUserSubtype]["client_id"];

            query = FirebaseServices.db
                .collection("deleted_requests")
                .where("details.start_date", isGreaterThanOrEqualTo: dates[0])
                .where("details.start_date", isLessThanOrEqualTo: dates[1])
                .where("client_info.id", isEqualTo: clientId);
          } else {
            query = FirebaseServices.db
                .collection("deleted_requests")
                .where("details.start_date", isGreaterThanOrEqualTo: dates[0])
                .where(
                  "details.start_date",
                  isLessThanOrEqualTo: dates[1],
                );
          }
        } else {
          query = FirebaseServices.db
              .collection("deleted_requests")
              .where("details.start_date", isGreaterThanOrEqualTo: dates[0])
              .where(
                "details.start_date",
                isLessThanOrEqualTo: dates[1],
              );
        }
      }
      if (nameTab == 'Por evento') {
        String clientId = idClient;

        if (context != null) {
          String webUserSubtype =
              context.read<AuthProvider>().webUser.accountInfo.subtype;

          String webUserType =
              context.read<AuthProvider>().webUser.accountInfo.type;

          if (webUserType == "admin" &&
              systemRoles["admin"].containsKey(webUserSubtype) &&
              systemRoles["admin"][webUserSubtype].containsKey("client_id")) {
            clientId = systemRoles["admin"][webUserSubtype]["client_id"];
          }
        }

        listenEvents(clientId, dates, requestsProvider);
      } else {
        requestsProvider.requestsStream = query.snapshots().listen(
          (QuerySnapshot querySnapshot) async {
            requestsProvider.requestsSnapshotDone = false;
            List<Request> requests = [];
            for (DocumentSnapshot requestDoc in querySnapshot.docs) {
              requests.add(
                RequestModel.fromMap(requestDoc.data() as Map<String, dynamic>),
              );
            }
            requestsProvider.updateRequests(requests);
          },
        );
      }

      int index = FirebaseServices.streamSubscriptions
          .indexWhere((addedStream) => addedStream.id == "listen_requests");

      if (index != -1) {
        await FirebaseServices.streamSubscriptions[index].streamSubscription
            ?.cancel();
        FirebaseServices.streamSubscriptions.removeAt(index);
      }

      FirebaseServices.streamSubscriptions.add(
        FirestoreStream(
          id: "listen_requests",
          streamSubscription: requestsProvider.requestsStream,
        ),
      );

      int eventsStreamIndex = FirebaseServices.streamSubscriptions
          .indexWhere((addedStream) => addedStream.id == "listen_events");

      if (eventsStreamIndex != -1) {
        FirebaseServices.streamSubscriptions.removeAt(eventsStreamIndex);
      }

      FirebaseServices.streamSubscriptions.add(
        FirestoreStream(
          id: "listen_events",
          streamSubscription: requestsProvider.eventsStream,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, listenAllRequests error: $e",
        );
      }
    }
  }

  @override
  Future<void> listenEventRequests(
      Event event, GetRequestsProvider provider) async {
    try {
      await provider.requestsStream?.cancel();
      provider.updateRequests([]);
      provider.requestsStream = FirebaseServices.db
          .collection("requests")
          .where("event_id", isEqualTo: event.id)
          .snapshots()
          .listen(
        (QuerySnapshot querySnapshot) async {
          List<Request> requests = [];

          for (DocumentSnapshot requestDoc in querySnapshot.docs) {
            requests.add(
              RequestModel.fromMap(requestDoc.data() as Map<String, dynamic>),
            );
          }

          bool eventStatusChanged = false;

          if (event.details.status == 1 &&
              requests.every((element) =>
                  element.details.status >= 2 && element.details.status < 5)) {
            event.details.status = 2;
            eventStatusChanged = true;
          }

          if (event.details.status == 2 &&
              requests.every((element) =>
                  element.details.status > 2 && element.details.status < 5)) {
            event.details.status = 3;
            eventStatusChanged = true;
          }

          if (event.details.status == 3 &&
              requests.every((element) => element.details.status == 4)) {
            event.details.status = 4;
            eventStatusChanged = true;
          }

          if (event.details.status != 5 &&
              requests.every((element) => element.details.status == 5)) {
            event.details.status = 5;
            eventStatusChanged = true;
          }

          if (event.details.status != 5 &&
              requests.every((element) => element.details.status == 6)) {
            event.details.status = 5;
            eventStatusChanged = true;
          }

          if (eventStatusChanged) {
            await FirebaseServices.db.collection("events").doc(event.id).update(
              {"details.status": event.details.status},
            );

            BuildContext? globalContext = NavigationService.getGlobalContext();

            if (globalContext != null) {
              bool isAdmin =
                  Provider.of<AuthProvider>(globalContext, listen: false)
                          .webUser
                          .accountInfo
                          .type ==
                      "admin";

              int eventIndex = (isAdmin)
                  ? provider.adminFilteredEvents
                      .indexWhere((Event eventItem) => eventItem.id == event.id)
                  : provider.events.indexWhere(
                      (Event eventItem) => eventItem.id == event.id);

              if (eventIndex != -1) {
                if (isAdmin) {
                  provider.adminFilteredEvents[eventIndex].details.status =
                      event.details.status;
                } else {
                  provider.events[eventIndex].details.status =
                      event.details.status;
                }
              }
            }
          }

          provider.updateRequests(requests);
        },
      );

      int index = FirebaseServices.streamSubscriptions
          .indexWhere((addedStream) => addedStream.id == "listen_requests");

      if (index != -1) {
        await FirebaseServices.streamSubscriptions[index].streamSubscription
            ?.cancel();
        FirebaseServices.streamSubscriptions.removeAt(index);
      }

      FirebaseServices.streamSubscriptions.add(
        FirestoreStream(
          id: "listen_requests",
          streamSubscription: provider.requestsStream,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, listenEventRequests error: $e",
        );
      }
    }
  }

  @override
  Future<void> listenEvents(String clientId, List<DateTime> dates,
      GetRequestsProvider requestsProvider) async {
    try {
      await requestsProvider.eventsStream?.cancel();
      Query query;
      if (clientId.isEmpty) {
        query = FirebaseServices.db
            .collection("events")
            .where("details.start_date", isGreaterThanOrEqualTo: dates[0])
            .where(
              "details.start_date",
              isLessThanOrEqualTo: dates[1],
            );
      } else {
        query = FirebaseServices.db
            .collection("events")
            .where("client_info.id", isEqualTo: clientId)
            .where("details.start_date", isGreaterThanOrEqualTo: dates[0])
            .where(
              "details.start_date",
              isLessThanOrEqualTo: dates[1],
            );
      }

      requestsProvider.eventsStream =
          query.snapshots().listen((QuerySnapshot querySnapshot) {
        List<Event> events = [];

        for (DocumentSnapshot eventDoc in querySnapshot.docs) {
          Map<String, dynamic> eventData =
              eventDoc.data() as Map<String, dynamic>;
          eventData["id"] = eventDoc.id;
          events.add(EventModel.fromMap(eventData));
        }
        requestsProvider.updateEvents(events);
      });

      int index = FirebaseServices.streamSubscriptions
          .indexWhere((addedStream) => addedStream.id == "listen_events");

      if (index != -1) FirebaseServices.streamSubscriptions.removeAt(index);

      FirebaseServices.streamSubscriptions.add(
        FirestoreStream(
          id: "listen_events",
          streamSubscription: requestsProvider.eventsStream,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, listenEvents error: $e",
        );
      }
    }
  }

  @override
  Future<bool> runTimeAction(Map<String, dynamic> actionInfo) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      //This is necessary because in some test, the request inside the map has an outdated status//
      DocumentSnapshot requestDoc = await FirebaseServices.db
          .collection("requests")
          .doc(actionInfo["request"].id)
          .get();

      actionInfo["request"].details.status =
          (requestDoc.data() as Map<String, dynamic>)["details"]["status"];

      //1. Get new job fare//
      JobRequest finalJobRequest = await JobFareService.get(
        actionInfo['job'],
        actionInfo['job_request'],
        actionInfo['start_date'],
        actionInfo['end_date'],
        actionInfo['has_dynamic_rate'],
        actionInfo['client_id'],
        actionInfo['country_info'],
      );

      Map<String, dynamic> fareUpdate = {
        "fare_type": finalJobRequest.fareType,
        "client_fare": {
          "dynamic": finalJobRequest.clientFare.dynamicFare,
          "holiday": finalJobRequest.clientFare.holidayFare,
          "normal": finalJobRequest.clientFare.normalFare,
        },
        "employee_fare": {
          "dynamic": finalJobRequest.employeeFare.dynamicFare,
          "holiday": finalJobRequest.employeeFare.holidayFare,
          "normal": finalJobRequest.employeeFare.normalFare,
        },
        "total_client_pays": finalJobRequest.totalToPayClientPerEmployee,
        "total_to_pay_employee": finalJobRequest.totalToPayEmployee,
      };

      Map<String, dynamic> employeeUpdate = {
        "doc_number": actionInfo["request"].employeeInfo.docNumber,
        "doc_type": actionInfo["request"].employeeInfo.docType,
        "last_names": actionInfo["request"].employeeInfo.lastNames,
        "names": actionInfo["request"].employeeInfo.names,
        "phone": actionInfo["request"].employeeInfo.phone,
        "image": actionInfo["request"].employeeInfo.imageUrl,
        "id": actionInfo["request"].employeeInfo.id,
      };

      int newStatus = actionInfo["request"].details.status;

      //2. If request is already assigned, validate employee availability //
      if (actionInfo["request"].details.status > 0) {
        (bool, double)? isAvaliable = await EmployeeAvailabilityService.get(
          actionInfo["start_date"],
          actionInfo["end_date"],
          actionInfo["request"].employeeInfo.id,
          actionInfo["request"].id,
        );

        if (isAvaliable == null) return false;

        if (!isAvaliable.$1) {
          bool confirmed = await confirm(
            title: const Text(
              "El colaborador no está disponible en el nuevo horario",
              style: TextStyle(color: Colors.red),
            ),
            content: const SizedBox(
              width: 200,
              child: Text(
                  "¿Deseas continuar? Si lo haces, un nuevo colaborador será asignado a la solicitud."),
            ),
            textOK:
                const Text("Continuar", style: TextStyle(color: Colors.blue)),
            textCancel:
                const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            context,
          );

          if (!confirmed) return false;

          newStatus = 0;
          employeeUpdate = {};
        }
      }

      String newWeekEnd =
          "${finalJobRequest.endDate.year}-${CodeUtils.getFormatStringNum(finalJobRequest.endDate.month)}-${CodeUtils.getFormatStringNum(finalJobRequest.endDate.day)}";

      //3. Update request info //
      await FirebaseServices.db
          .collection("requests")
          .doc(actionInfo["request"].id)
          .update({
        "details.fare": fareUpdate,
        "details.start_date": finalJobRequest.startDate,
        "details.end_date": finalJobRequest.endDate,
        "details.status": newStatus,
        "details.total_hours": finalJobRequest.employeeHours,
        "employee_info": employeeUpdate,
        "week_start":
            "${finalJobRequest.startDate.year}-${CodeUtils.getFormatStringNum(finalJobRequest.startDate.month)}-${CodeUtils.getFormatStringNum(finalJobRequest.startDate.day)}",
        "week_end": newWeekEnd
      });

      //4. Calculate new event values //

      double newEventHours = (actionInfo["event"].details.totalHours -
              actionInfo["request"].details.totalHours) +
          finalJobRequest.employeeHours;

      double lastEventJobHours = actionInfo["event"]
          .employeesInfo
          .neededJobs[finalJobRequest.job["value"]]["total_hours"];

      double newEventJobHours =
          (lastEventJobHours - actionInfo["request"].details.totalHours) +
              finalJobRequest.employeeHours;

      Map<String, dynamic> newEventFare = {
        "total_client_pays": (actionInfo["event"].details.fare.totalClientPays -
                actionInfo["last_client_pays"]) +
            finalJobRequest.totalToPayClient,
        "total_to_pay_employees":
            (actionInfo["event"].details.fare.totalToPayEmployees -
                    actionInfo["last_pay_employees"]) +
                finalJobRequest.totalToPayEmployee,
      };

      DateTime newEventEndDate = actionInfo["event"].details.endDate;

      if (finalJobRequest.endDate.isAfter(newEventEndDate)) {
        newEventEndDate = finalJobRequest.endDate;
      }
      //5. Update event info //
      await FirebaseServices.db
          .collection("events")
          .doc(actionInfo["event"].id)
          .update({
        "week_end": newWeekEnd,
        "details.end_date": newEventEndDate,
        "details.fare": newEventFare,
        "details.total_hours": newEventHours,
        "employees_info.jobs_needed.${finalJobRequest.job["value"]}.total_hours":
            newEventJobHours,
      });

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;

      String complement = newStatus > 0
          ? "Asignada a ${CodeUtils.getFormatedName(employeeUpdate["names"], employeeUpdate["last_names"])} "
          : "Sin asignar";

      ActivityParams params = ActivityParams(
        description:
            "Se actualizó el horario de una solicitud del evento ${actionInfo["event"].eventName}. $complement",
        category: {
          "key": "requests",
          "name": "Solicitudes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {"id": "", "name": "", "type_key": "", "type_name": ""},
        date: DateTime.now(),
      );

      await ActivityService.saveChange(params);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, runTimeAction error: $e",
        );
      }
      return false;
    }
  }

  @override
  Future<bool> runCloneAction(Map<String, dynamic> actionInfo) async {
    try {
      //Get new job fare//
      JobRequest finalJobRequest = await JobFareService.get(
        actionInfo['job'],
        actionInfo['job_request'],
        actionInfo['start_date'],
        actionInfo['end_date'],
        actionInfo['has_dynamic_rate'],
        actionInfo['client_id'],
        actionInfo['country_info'],
      );

      Map<String, dynamic> employeeInfo =
          actionInfo["request"].details.status == 0
              ? {}
              : {
                  "doc_number": actionInfo["request"].employeeInfo.docNumber,
                  "doc_type": actionInfo["request"].employeeInfo.docType,
                  "last_names": actionInfo["request"].employeeInfo.lastNames,
                  "names": actionInfo["request"].employeeInfo.names,
                  "phone": actionInfo["request"].employeeInfo.phone,
                  "image": actionInfo["request"].employeeInfo.imageUrl,
                  "id": actionInfo["request"].employeeInfo.id,
                };
      int newStatus = actionInfo["request"].details.status;

      String newRequestId = FirebaseServices.db.collection("requests").doc().id;
      String eventId = FirebaseServices.db.collection("events").doc().id;

      String newWeekEnd =
          "${finalJobRequest.endDate.year}-${CodeUtils.getFormatStringNum(finalJobRequest.endDate.month)}-${CodeUtils.getFormatStringNum(finalJobRequest.endDate.day)}";

      //Set new request data//
      Map<String, dynamic> requestData = {
        "client_info": finalJobRequest.clientInfo,
        "details": {
          "arrived_date": "",
          "departed_date": "",
          "fare": {
            "fare_type": finalJobRequest.fareType,
            "client_fare": {
              "dynamic": finalJobRequest.clientFare.dynamicFare,
              "holiday": finalJobRequest.clientFare.holidayFare,
              "normal": finalJobRequest.clientFare.normalFare,
            },
            "employee_fare": {
              "dynamic": finalJobRequest.employeeFare.dynamicFare,
              "holiday": finalJobRequest.employeeFare.holidayFare,
              "normal": finalJobRequest.employeeFare.normalFare,
            },
            "total_client_pays": finalJobRequest.totalToPayClientPerEmployee,
            "total_to_pay_employee": finalJobRequest.totalToPayEmployee,
          },
          "job": finalJobRequest.job,
          "location": finalJobRequest.location,
          "indications": finalJobRequest.indications,
          "rate": {},
          "start_date": finalJobRequest.startDate,
          "end_date": finalJobRequest.endDate,
          "status": newStatus != 0 ? actionInfo["status_new_request"] : 0,
          "total_hours": finalJobRequest.employeeHours,
        },
        "employee_info": employeeInfo,
        "event_id": eventId,
        "event_number": finalJobRequest.eventName,
        "id": newRequestId,
        "year": finalJobRequest.startDate.year,
        "month": finalJobRequest.startDate.month,
        "week_start":
            "${finalJobRequest.startDate.year}-${CodeUtils.getFormatStringNum(finalJobRequest.startDate.month)}-${CodeUtils.getFormatStringNum(finalJobRequest.startDate.day)}",
        "week_end": newWeekEnd,
      };

      String jobValue = finalJobRequest.job["value"];

      //Set new event data///

      Map<String, dynamic> newEventData = {
        "client_info": finalJobRequest.clientInfo,
        "details": {
          "start_date": finalJobRequest.startDate,
          "end_date": finalJobRequest.endDate,
          "fare": {
            "total_to_pay_employees": finalJobRequest.totalToPayEmployee,
            "total_client_pays": finalJobRequest.totalToPayClient,
          },
          "location": finalJobRequest.location,
          "rate": {},
          "status": 1,
          "total_hours": finalJobRequest.employeeHours,
        },
        "employees_info": {
          "employees_accepted": 0,
          "employees_arrived": 0,
          "employees_needed": 1,
          "jobs_needed": {
            jobValue: {
              "employees": 1,
              "name": finalJobRequest.job["name"],
              "total_hours": finalJobRequest.totalHours,
              "value": jobValue,
            },
          },
        },
        "week_end": newWeekEnd,
        "week_start": requestData["week_start"],
        "event_number":
            "${requestData['event_number']}", //"${requestData['event_number']}$eventNameComplement",
        "id": eventId,
        "month": requestData["month"],
        "year": requestData["year"],
        "week_cut": CodeUtils().getCutOffWeek(finalJobRequest.startDate),
      };

      //Create event//
      await FirebaseServices.db
          .collection("events")
          .doc(eventId)
          .set(newEventData);

      //Create request//
      await FirebaseServices.db
          .collection("requests")
          .doc(newRequestId)
          .set(requestData);

      //Update Client requests count
      await FirebaseServices.db
          .collection("clients")
          .doc(finalJobRequest.clientInfo["id"])
          .update(
        {"account_info.total_requests": FieldValue.increment(1)},
      );

      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;

      ActivityParams params = ActivityParams(
        description:
            "Se clonó una solicitud del evento ${actionInfo["request"].eventName}. Para la fecha: ${CodeUtils.formatDate(finalJobRequest.startDate)}",
        category: {
          "key": "requests",
          "name": "Solicitudes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {"id": "", "name": "", "type_key": "", "type_name": ""},
        date: DateTime.now(),
      );

      await ActivityService.saveChange(params);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, runCloneAction error: $e",
        );
      }
      return false;
    }
  }

  @override
  Future<void> getActiveEvents(
      String clientId, GetRequestsProvider provider) async {
    try {
      List<Event> events = [];
      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("events")
          .where("client_info.id", isEqualTo: clientId)
          .where("details.status", isLessThan: 4)
          .get();

      for (DocumentSnapshot eventDoc in querySnapshot.docs) {
        Map<String, dynamic> eventData =
            eventDoc.data() as Map<String, dynamic>;
        eventData["id"] = eventDoc.id;
        events.add(EventModel.fromMap(eventData));
      }
      provider.updateActiveEvents(events);
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, getActiveEvents error: $e",
        );
      }
    }
  }

  @override
  Future<bool> runEditAction(Map<String, dynamic> actionInfo,
      {bool fromClone = false}) async {
    try {
      String clonedRequestID = "";

      if (fromClone) {
        clonedRequestID = FirebaseServices.db.collection("requests").doc().id;
      }

      //Event no changed, just update indications///
      if (!fromClone && actionInfo["event"].id == actionInfo["new_event"].id) {
        await FirebaseServices.db
            .collection("requests")
            .doc(actionInfo["request"].id)
            .update({"details.indications": actionInfo["new_indications"]});
        return true;
      }

      actionInfo["start_date"] = DateTime(
        actionInfo["start_date"].year,
        actionInfo["start_date"].month,
        actionInfo["start_date"].day,
        actionInfo["start_date"].hour,
        actionInfo["start_date"].minute,
      );

      actionInfo["end_date"] = actionInfo["start_date"].add(
        Duration(
          minutes: (actionInfo["request"].details.totalHours * 60).toInt(),
        ),
      );

      actionInfo['job_request'].startDate = actionInfo["start_date"];

      actionInfo['job_request'].endDate = actionInfo["end_date"];

      //Get new job fare//
      JobRequest finalJobRequest = await JobFareService.get(
        actionInfo['job'],
        actionInfo['job_request'],
        actionInfo['start_date'],
        actionInfo['end_date'],
        actionInfo['has_dynamic_rate'],
        actionInfo['client_id'],
        actionInfo['country_info'],
      );
      Map<String, dynamic> employeeInfo =
          (actionInfo["request"].details.status == 0)
              ? {}
              : {
                  "doc_number": actionInfo["request"].employeeInfo.docNumber,
                  "doc_type": actionInfo["request"].employeeInfo.docType,
                  "last_names": actionInfo["request"].employeeInfo.lastNames,
                  "names": actionInfo["request"].employeeInfo.names,
                  "phone": actionInfo["request"].employeeInfo.phone,
                  "image": actionInfo["request"].employeeInfo.imageUrl,
                  "id": actionInfo["request"].employeeInfo.id,
                };

      int newStatus = fromClone
          ? actionInfo["status_new_request"]
          : actionInfo["request"].details.status;

      String jobValue = actionInfo["request"].details.job["value"];

      //Update request info//
      Map<String, dynamic> updatedRequestData = {
        "client_info": finalJobRequest.clientInfo,
        "details": {
          "arrived_date": "",
          "departed_date": "",
          "fare": {
            "fare_type": finalJobRequest.fareType,
            "client_fare": {
              "dynamic": finalJobRequest.clientFare.dynamicFare,
              "holiday": finalJobRequest.clientFare.holidayFare,
              "normal": finalJobRequest.clientFare.normalFare,
            },
            "employee_fare": {
              "dynamic": finalJobRequest.employeeFare.dynamicFare,
              "holiday": finalJobRequest.employeeFare.holidayFare,
              "normal": finalJobRequest.employeeFare.normalFare,
            },
            "total_client_pays": finalJobRequest.totalToPayClientPerEmployee,
            "total_to_pay_employee": finalJobRequest.totalToPayEmployee,
          },
          "job": finalJobRequest.job,
          "location": actionInfo["new_event"].details.location,
          "indications": actionInfo["new_indications"],
          "rate": {},
          "start_date": finalJobRequest.startDate,
          "end_date": finalJobRequest.endDate,
          "status": newStatus,
          "total_hours": finalJobRequest.employeeHours,
        },
        "employee_info": employeeInfo,
        "event_id": actionInfo["new_event"].id,
        "event_number": actionInfo["new_event"].eventName,
        "id": (fromClone) ? clonedRequestID : actionInfo["request"].id,
        "year": finalJobRequest.startDate.year,
        "month": finalJobRequest.startDate.month,
        "week_start":
            "${finalJobRequest.startDate.year}-${CodeUtils.getFormatStringNum(finalJobRequest.startDate.month)}-${CodeUtils.getFormatStringNum(finalJobRequest.startDate.day)}",
        "week_end":
            "${finalJobRequest.endDate.year}-${CodeUtils.getFormatStringNum(finalJobRequest.endDate.month)}-${CodeUtils.getFormatStringNum(finalJobRequest.endDate.day)}",
      };

      await FirebaseServices.db
          .collection("requests")
          .doc((fromClone) ? clonedRequestID : actionInfo["request"].id)
          .set(updatedRequestData);

      //Save edition to request historical -> Start//
      BuildContext? globalContext = NavigationService.getGlobalContext();
      WebUser? webUser;

      if (globalContext != null) {
        webUser =
            Provider.of<AuthProvider>(globalContext, listen: false).webUser;
      }

      await FirebaseServices.db
          .collection("requests")
          .doc((fromClone) ? clonedRequestID : actionInfo["request"].id)
          .collection("historical")
          .add({
        "event_id": actionInfo["new_event"].id,
        "event_number": actionInfo["new_event"].eventName,
        "update_date": DateTime.now(),
        "client_info": finalJobRequest.clientInfo,
        "details": {
          "job": finalJobRequest.job,
          "start_date": finalJobRequest.startDate,
          "end_date": finalJobRequest.endDate,
          "user_type": (webUser != null) ? webUser.accountInfo.type : "",
          "person_in_charge": (webUser != null)
              ? "${webUser.profileInfo.names} ${webUser.profileInfo.lastNames}"
              : "",
          "description": (fromClone)
              ? "Solicitud clonada para otro evento"
              : "Solicitud modificada"
        },
        "old_data": actionInfo["request"].toMap(),
        "new_data": updatedRequestData,
      });
      //Save edition to request historical -> End//

      if (!fromClone) {
        ///update previous request event//
        await FirebaseServices.db
            .collection("events")
            .doc(actionInfo["event"].id)
            .update(
          {
            "employees_info.employees_needed": FieldValue.increment(-1),
            "employees_info.jobs_needed.$jobValue.employees":
                FieldValue.increment(-1),
            "employees_info.jobs_needed.$jobValue.total_hours":
                FieldValue.increment(-finalJobRequest.employeeHours),
            "details.total_hours":
                FieldValue.increment(-finalJobRequest.employeeHours),
            "details.fare.total_client_pays": FieldValue.increment(
              -finalJobRequest.totalToPayClientPerEmployee,
            ),
            "details.fare.total_to_pay_employees": FieldValue.increment(
              -finalJobRequest.totalToPayEmployee,
            ),
          },
        );
      }

      //update new event info//
      bool jobAlreadyAdded = actionInfo["new_event"]
          .employeesInfo
          .neededJobs
          .containsKey(jobValue);

      if (jobAlreadyAdded) {
        actionInfo["new_event"].employeesInfo.neededJobs[jobValue]
            ["employees"] += 1;

        actionInfo["new_event"].employeesInfo.neededJobs[jobValue]
            ["total_hours"] += finalJobRequest.employeeHours;
      } else {
        actionInfo["new_event"].employeesInfo.neededJobs[jobValue] = {
          "employees": 1,
          "name": actionInfo["request"].details.job["name"],
          "total_hours": finalJobRequest.employeeHours,
          "value": jobValue,
        };
        int statusRequest = actionInfo['request'].details.status;
        if (statusRequest == 2) {
          actionInfo["new_event"].details.status == 2;
          actionInfo["new_event"].employeesInfo.employees_accepted = 1;
        }
        if (statusRequest == 3) {
          actionInfo["new_event"].details.status = 3;
          actionInfo["new_event"].employeesInfo.employees_accepted = 1;
          actionInfo["new_event"].employeesInfo.employees_arrived = 1;
        }
        if (statusRequest == 4) {
          actionInfo["new_event"].details.status = 4;
          actionInfo["new_event"].employeesInfo.employees_accepted = 1;
        }
        if (statusRequest == 5 || statusRequest == 6) {
          actionInfo["new_event"].details.status = 5;
        }
      }

      await FirebaseServices.db
          .collection("events")
          .doc(actionInfo["new_event"].id)
          .update({
        "employees_info.employees_needed": FieldValue.increment(1),
        "employees_info.jobs_needed.$jobValue":
            actionInfo["new_event"].employeesInfo.neededJobs[jobValue],
        "details.total_hours":
            FieldValue.increment(finalJobRequest.employeeHours),
        "details.fare.total_client_pays": FieldValue.increment(
          finalJobRequest.totalToPayClientPerEmployee,
        ),
        "details.fare.total_to_pay_employees": FieldValue.increment(
          finalJobRequest.totalToPayEmployee,
        ),
      });

      ActivityParams params = ActivityParams(
        description:
            "Se modificó la solicitud con id: ${actionInfo["request"].id}. del evento ${actionInfo["request"].eventName}",
        category: {
          "key": "requests",
          "name": "Solicitudes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser!.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {"id": "", "name": "", "type_key": "", "type_name": ""},
        date: DateTime.now(),
      );
      await ActivityService.saveChange(params);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, runEditAction error: $e",
        );
      }
      return false;
    }
  }

  @override
  Future<bool> runBlockAction(
      Map<String, dynamic> actionInfo, AuthProvider authProvider) async {
    try {
      bool alreadyBlocked = (actionInfo["web_user"]
          .company
          .blockedEmployees
          .any(
            (blockedEmployee) =>
                blockedEmployee.uid == actionInfo["request"].employeeInfo.id,
          ));

      if (alreadyBlocked) {
        await FirebaseServices.db
            .collection("clients")
            .doc(actionInfo["web_user"].company.id)
            .set(
          {
            "blocked_employees": {
              "${actionInfo["request"].employeeInfo.id}": FieldValue.delete(),
            }
          },
          SetOptions(merge: true),
        );
        await authProvider.getUserInfoOrFail();
        // return true;
      } else {
        DocumentSnapshot<Map<String, dynamic>> employeeDoc =
            await FirebaseServices.db
                .collection('employees')
                .doc(actionInfo['request'].employeeInfo.id)
                .get();
        if (!employeeDoc.exists) return false;

        await FirebaseServices.db
            .collection("clients")
            .doc(actionInfo["web_user"].company.id)
            .update(
          {
            "blocked_employees.${actionInfo["request"].employeeInfo.id}": {
              "fullname":
                  "${actionInfo['request'].employeeInfo.names} ${actionInfo['request'].employeeInfo.lastNames}",
              "phone": "${actionInfo['request'].employeeInfo.phone}",
              "photo": "${actionInfo['request'].employeeInfo.imageUrl}",
              "uid": "${actionInfo['request'].employeeInfo.id}",
              'jobs': employeeDoc.data()!['jobs'],
            },
          },
        );
        await authProvider.getUserInfoOrFail();
      }
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      // WebUser webUser =
      //     Provider.of<AuthProvider>(context, listen: false).webUser;
      WebUser webUser = authProvider.webUser;

      ActivityParams params = ActivityParams(
        description: !alreadyBlocked
            ? "Se bloqueó al colaborador ${actionInfo['request'].employeeInfo.names} ${actionInfo['request'].employeeInfo.lastNames} "
            : "Se desbloqueó al colaborador ${actionInfo['request'].employeeInfo.names} ${actionInfo['request'].employeeInfo.lastNames} ",
        category: {
          "key": "employees",
          "name": "Colaboradores",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {"id": "", "name": "", "type_key": "", "type_name": ""},
        date: DateTime.now(),
      );

      await ActivityService.saveChange(params);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, runBlockAction error: $e",
        );
      }
      return false;
    }
  }

  @override
  Future<bool> runFavoriteAction(
      Map<String, dynamic> actionInfo, AuthProvider authProvider) async {
    try {
      bool alreadyFavorite = (actionInfo["web_user"]
          .company
          .favoriteEmployees
          .any(
            (favoriteEmployee) =>
                favoriteEmployee.uid == actionInfo["request"].employeeInfo.id,
          ));

      if (alreadyFavorite) {
        await FirebaseServices.db
            .collection("clients")
            .doc(actionInfo["web_user"].company.id)
            .set(
          {
            "favorites": {
              "${actionInfo["request"].employeeInfo.id}": FieldValue.delete(),
            }
          },
          SetOptions(merge: true),
        );
        await authProvider.getUserInfoOrFail();
        // return true;
      } else {
        DocumentSnapshot<Map<String, dynamic>> employeeDoc =
            await FirebaseServices.db
                .collection('employees')
                .doc(actionInfo['request'].employeeInfo.id)
                .get();
        if (!employeeDoc.exists) return false;

        await FirebaseServices.db
            .collection("clients")
            .doc(actionInfo["web_user"].company.id)
            .update(
          {
            "favorites.${actionInfo["request"].employeeInfo.id}": {
              "fullname":
                  "${actionInfo['request'].employeeInfo.names} ${actionInfo['request'].employeeInfo.lastNames}",
              "phone": "${actionInfo['request'].employeeInfo.phone}",
              "photo": "${actionInfo['request'].employeeInfo.imageUrl}",
              "uid": "${actionInfo['request'].employeeInfo.id}",
              'jobs': employeeDoc.data()!['jobs'],
            },
          },
        );

        await authProvider.getUserInfoOrFail();
      }
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser = authProvider.webUser;

      ActivityParams params = ActivityParams(
        description: !alreadyFavorite
            ? "Se marcó como favorito al colaborador ${actionInfo['request'].employeeInfo.names} ${actionInfo['request'].employeeInfo.lastNames}"
            : "Se desmarcó como favorito al colaborador ${actionInfo['request'].employeeInfo.names} ${actionInfo['request'].employeeInfo.lastNames}",
        category: {
          "key": "employees",
          "name": "Colaboradores",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {"id": "", "name": "", "type_key": "", "type_name": ""},
        date: DateTime.now(),
      );

      await ActivityService.saveChange(params);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, runFavoriteAction error: $e",
        );
      }
      return false;
    }
  }

  @override
  Future<bool> runRateAction(Map<String, dynamic> actionInfo) async {
    try {
      double generalRate = 0;
      Map<String, dynamic> finalRequestRate = {};
      DocumentSnapshot doc = await FirebaseServices.db
          .collection("employees")
          .doc(actionInfo["request"].employeeInfo.id)
          .get();

      Map<String, dynamic> employeeData = doc.data() as Map<String, dynamic>;

      bool hasPreviousRate = employeeData["profile_info"].containsKey("rate");

      for (Map<String, dynamic> rateItem in actionInfo["employee_rate"]) {
        generalRate += rateItem["rate"];

        finalRequestRate[rateItem["value"]] = {
          "name": rateItem["name"],
          "value": rateItem["value"],
          "rate": rateItem["rate"],
        };

        if (hasPreviousRate) {
          if (employeeData["profile_info"]["rate"]
              .containsKey(rateItem["value"])) {
            employeeData["profile_info"]["rate"][rateItem["value"]]["rate"] +=
                rateItem["rate"];
            employeeData["profile_info"]["rate"][rateItem["value"]]["rate"] /=
                2;
          } else {
            employeeData["profile_info"]["rate"][rateItem["value"]] = {
              "name": rateItem["name"],
              "value": rateItem["value"],
              "rate": rateItem["rate"],
            };
          }
          continue;
        }

        if (employeeData["profile_info"]["rate"] == null) {
          employeeData["profile_info"]["rate"] = {};
        }

        employeeData["profile_info"]["rate"][rateItem["value"]] = {
          "name": rateItem["name"],
          "value": rateItem["value"],
          "rate": rateItem["rate"],
        };
      }

      generalRate = double.parse(
        (generalRate / actionInfo["employee_rate"].length).toStringAsFixed(1),
      );

      employeeData["profile_info"]["rate"]["general_rate"] = (hasPreviousRate)
          ? (employeeData["profile_info"]["rate"]["general_rate"] +
                  generalRate) /
              2
          : generalRate;

      finalRequestRate["general_rate"] = generalRate;

      await FirebaseServices.db
          .collection("employees")
          .doc(actionInfo["request"].employeeInfo.id)
          .update({
        "profile_info.rate": employeeData["profile_info"]["rate"],
      });

      await FirebaseServices.db
          .collection("requests")
          .doc(actionInfo["request"].id)
          .update({
        "details.rate": finalRequestRate,
      });

      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;

      await FirebaseServices.db.collection("activity").add(
        {
          "description":
              "Se calificó al colaborador ${actionInfo['request'].employeeInfo.names} ${actionInfo['request'].employeeInfo.lastNames} ",
          "category": {
            "key": "employees",
            "name": "Colaboradores",
          },
          "person_in_charge": {
            "name": CodeUtils.getFormatedName(
                webUser.profileInfo.names, webUser.profileInfo.lastNames),
            "type_key": webUser.accountInfo.type,
            "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
            "id": webUser.uid,
            "company_id": webUser.accountInfo.companyId
          },
          "affected_user": {
            "id": "",
            "name": "",
            "type_key": "",
            "type_name": ""
          },
          "date": DateTime.now(),
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, runRateAction error: $e",
        );
      }
      return false;
    }
  }

  @override
  Future<bool> runCloneToEventAction(Map<String, dynamic> actionInfo) async {
    try {
      bool resp = await runEditAction(actionInfo, fromClone: true);

      if (!resp) return resp;

      //Update Client requests count
      await FirebaseServices.db
          .collection("clients")
          .doc(actionInfo['client_id'])
          .update({"account_info.total_requests": FieldValue.increment(1)});

      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;

      await FirebaseServices.db.collection("activity").add(
        {
          "description":
              "Se clonó las solicitud con id: ${actionInfo["request"].id}. del evento ${actionInfo["event"].eventName}",
          "category": {
            "key": "requests",
            "name": "Solicitudes",
          },
          "person_in_charge": {
            "name": CodeUtils.getFormatedName(
                webUser.profileInfo.names, webUser.profileInfo.lastNames),
            "type_key": webUser.accountInfo.type,
            "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
            "id": webUser.uid,
            "company_id": webUser.accountInfo.companyId
          },
          "affected_user": {
            "id": "",
            "name": "",
            "type_key": "",
            "type_name": ""
          },
          "date": DateTime.now(),
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, runCloneToEventAction error: $e",
        );
      }
      return false;
    }
  }

  @override
  Future<bool> markArrival(String idRequest, Request request) async {
    try {
      await FirebaseServices.db.collection("requests").doc(idRequest).get();
      await FirebaseServices.db
          .collection("requests")
          .doc(idRequest)
          .update({"details.status": 3});

      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;

      await FirebaseServices.db.collection("activity").add(
        {
          "description":
              "Se marcó la llegada del colaborador: ${request.employeeInfo.names} ${request.employeeInfo.lastNames} al evento ${request.eventName}",
          "category": {
            "key": "requests",
            "name": "requests",
          },
          "person_in_charge": {
            "name": CodeUtils.getFormatedName(
                webUser.profileInfo.names, webUser.profileInfo.lastNames),
            "type_key": webUser.accountInfo.type,
            "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
            "id": webUser.uid,
            "company_id": webUser.accountInfo.companyId
          },
          "affected_user": {
            "id": request.employeeInfo.id,
            "name": request.employeeInfo.names,
            "type_key": "requests",
            "type_name": "requests"
          },
          "date": DateTime.now(),
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          "GetRequestsRemoteDatasource, markArrival error: $e",
        );
      }
      return false;
    }
  }

  @override
  Future<bool> moveRequests(
    List<Request> requestList,
    Map<String, dynamic> updateData,
    bool isEvenselected,
  ) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();
      if (context == null) return false;
      Map<String, dynamic> newEvent =
          updateData['new_event'] as Map<String, dynamic>;
      Map<String, dynamic> previousEvent =
          updateData['previous_event'] as Map<String, dynamic>;
      List<Request> previusRequestsList =
          updateData['previous_requests'].values.toList();
      String newEventId = '';
      ClientsProvider clientsProvider = context.read<ClientsProvider>();
      GeneralInfoProvider generalInfoProvider =
          context.read<GeneralInfoProvider>();
      AuthProvider authProvider = context.read<AuthProvider>();

      bool hasDynamicfare = false;
      JobRequest jobFareRequest;
      bool canDeleteEvent = false;

      if (authProvider.webUser.accountInfo.type == 'client') {
        hasDynamicfare =
            authProvider.webUser.company.accountInfo['has_dynamic_fare'];
      } else {
        int clientIndex = clientsProvider.allClients.indexWhere((element) =>
            element.accountInfo.id == requestList.first.clientInfo.id);
        if (clientIndex == -1) return false;
        hasDynamicfare =
            clientsProvider.allClients[clientIndex].accountInfo.hasDynamicFare;
      }
      Map<String, dynamic> jobs = previousEvent['employees_info']['jobs_needed']
          as Map<String, dynamic>; //Para comparar los jobs con el evento previo
      for (Request priorRequest in previusRequestsList) {
        previousEvent['details']['fare']['total_client_pays'] -=
            priorRequest.details.fare.totalClientPays;
        previousEvent['details']['fare']['total_to_pay_employees'] -=
            priorRequest.details.fare.totalToPayEmployee;
        previousEvent['details']['total_hours'] -=
            priorRequest.details.totalHours;
        previousEvent['employees_info']['employees_needed']--;
        if (priorRequest.details.status == 2) {
          previousEvent['employees_info']['employees_accepted']--;
        }
        if (priorRequest.details.status == 3) {
          previousEvent['employees_info']['employees_arrived']--;
        }
        if (jobs.containsKey(priorRequest.details.job['value'])) {
          previousEvent['employees_info']['jobs_needed']
              [priorRequest.details.job['value']]['employees']--;
          previousEvent['employees_info']['jobs_needed']
                  [priorRequest.details.job['value']]['total_hours'] -=
              priorRequest.details.totalHours;
          if (previousEvent['id'] == newEvent['id']) {
            newEvent['employees_info']['jobs_needed']
                    [priorRequest.details.job['value']]['total_hours'] -=
                priorRequest.details.totalHours;
          }
          if (previousEvent['employees_info']['jobs_needed']
                  [priorRequest.details.job['value']]['total_hours'] ==
              0) {
            previousEvent['employees_info']['jobs_needed']
                .remove(priorRequest.details.job['value']);
          }
        }

        if (previousEvent['details']['total_hours'] == 0 &&
            previousEvent['id'] != newEvent['id']) canDeleteEvent = true;

        if (previousEvent['id'] == newEvent['id']) {
          newEvent['details']['total_hours'] -= priorRequest.details.totalHours;
          newEvent['details']['fare']['total_client_pays'] -=
              priorRequest.details.fare.totalClientPays;
          newEvent['details']['fare']['total_to_pay_employees'] -=
              priorRequest.details.fare.totalToPayEmployee;
        }
      }

      if (isEvenselected) {
        jobs = newEvent['employees_info']['jobs_needed'] as Map<String,
            dynamic>; //Para comparar los jobs con el nuevo evento
      } else {
        jobs = {};
      }
      if (!isEvenselected) {
        newEvent['details']['status'] = 1;
        newEventId = FirebaseServices.db.collection("events").doc().id;
        newEvent['id'] = newEventId;
        newEvent['event_number'] = updateData['new_name_event'];
        newEvent['client_info']['id'] = requestList.first.clientInfo.id;
        newEvent['client_info']['country'] = 'Costa Rica'; //
        newEvent['client_info']['image'] =
            requestList.first.clientInfo.imageUrl;
        newEvent['details']['location'] = requestList.first.details.location;
        newEvent['client_info']['name'] = requestList.first.clientInfo.name;
        if (requestList.any((element) => element.details.status == 0)) {
          newEvent['details']['status'] = 1;
        }
        if (requestList.any((element) => element.details.status == 3) &&
            requestList.every((element) => element.details.status != 0)) {
          newEvent['details']['status'] = 3;
        }
        if (requestList.every((element) => element.details.status == 2)) {
          newEvent['details']['status'] = 2;
        }

        newEvent['year'] = requestList.first.year;
        newEvent['month'] = requestList.last.month;
      }

      await Future.forEach(
        requestList,
        (Request request) async {
          Map<String, dynamic> newRequest = request.toMap();

          newEvent['details']['end_date'] =
              newEvent['details']['end_date'].isAfter(request.details.endDate)
                  ? newEvent['details']['end_date']
                  : request.details.endDate;

          newEvent['details']['start_date'] = newEvent['details']['start_date']
                      .isBefore(request.details.startDate) &&
                  isEvenselected
              ? newEvent['details']['start_date']
              : request.details.startDate;

          newEvent['week_start'] = newEvent['details']['start_date']
                      .isBefore(request.details.startDate) &&
                  isEvenselected
              ? newEvent['week_start']
              : request.startWeek;
          newEvent['week_end'] =
              newEvent['details']['end_date'].isAfter(request.details.endDate)
                  ? newEvent['week_end']
                  : request.startWeek;
          newEvent['week_cut'] = CodeUtils().getCutOffWeek(
            newEvent['details']['start_date']
                        .isBefore(request.details.startDate) &&
                    isEvenselected
                ? newEvent['details']['start_date']
                : request.details.startDate,
          );

          if (!isEvenselected) {
            newRequest['event_number'] = newEvent['event_number'];
            newRequest['event_id'] = newEventId;
            //Update Client requests count
            await FirebaseServices.db
                .collection("clients")
                .doc(request.clientInfo.id)
                .update(
                    {"account_info.total_requests": FieldValue.increment(1)});
          } else {
            newRequest['event_id'] = newEvent['id'];
            newRequest['event_number'] = newEvent['event_number'];
          }

          newEvent['details']['total_hours'] += request.details.totalHours;

          if (previousEvent['id'] != newEvent['id']) {
            newEvent['employees_info']['employees_needed']++;
          }

          if (request.details.status == 0) {
            newRequest['employee_info'] = {};
          }
          if (request.details.status == 2) {
            newEvent['employees_info']['employees_accepted']++;
          }

          if (request.details.status == 3) {
            newEvent['employees_info']['employees_arrived']++;
          }
          if (jobs.containsKey(request.details.job['value'])) {
            if (previousEvent['id'] != newEvent['id']) {
              newEvent['employees_info']['jobs_needed']
                  [request.details.job['value']]['employees']++;
            }
            newEvent['employees_info']['jobs_needed']
                    [request.details.job['value']]['total_hours'] +=
                request.details.totalHours;
          } else {
            newEvent['employees_info']['jobs_needed']
                [request.details.job['value']] = {
              'employees': 1,
              'total_hours': request.details.totalHours,
              'name': request.details.job['name'],
              'value': request.details.job['value'],
            };
          }

          newRequest['year'] = newEvent['year'];
          newRequest['month'] = newEvent['month'];

          JobRequest newJob = JobRequest(
            clientInfo: request.clientInfo.toMap(),
            eventId: request.eventId,
            eventName: request.eventName,
            startDate: request.details.startDate,
            endDate: request.details.endDate,
            location: request.details.location,
            fareType: "",
            job: {
              "name": request.details.job["name"],
              "value": request.details.job["value"],
            },
            employeeHours: request.details.totalHours,
            totalHours: request.details.totalHours,
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
            totalToPayClient: 0,
            totalToPayClientPerEmployee: 0,
            totalToPayAllEmployees: 0,
            totalClientNightSurcharge: 0,
            totalEmployeeNightSurcharge: 0,
            employeesNumber: 1,
            indications: request.details.indications,
            references: request.details.references,
          );

          int indexRequestJob = generalInfoProvider.jobsFares.indexWhere(
              (element) => element['value'] == request.details.job['value']);

          if (indexRequestJob == -1) return false;

          Map<String, dynamic> fares = {};
          if (authProvider.webUser.accountInfo.type == 'client') {
            fares = authProvider.webUser.company.jobs
                .firstWhere((element) => element.value == newJob.job['value'])
                .fares;
          } else {
            ClientEntity client = clientsProvider.allClients.firstWhere(
                (element) => element.accountInfo.id == request.clientInfo.id);
            fares = client.jobs.values.firstWhere(
                (element) => element['value'] == newJob.job['value'])['fares'];
          }

          Job jobInfo = Job(
            name: newJob.job['name'],
            value: newJob.job['value'],
            fares: fares,
          );

          jobFareRequest = await JobFareService.get(
            jobInfo,
            newJob,
            request.details.startDate,
            request.details.endDate,
            hasDynamicfare,
            request.clientInfo.id,
            generalInfoProvider.generalInfo.countryInfo,
          );

          newRequest['details']['fare']['employee_fare'] =
              jobFareRequest.employeeFare.toMap();

          newRequest['details']['fare']['client_fare'] =
              jobFareRequest.clientFare.toMap();

          newRequest['details']['fare']['total_client_pays'] =
              jobFareRequest.totalToPayClient;
          newRequest['details']['fare']['total_to_pay_employee'] =
              jobFareRequest.totalToPayEmployee;

          newEvent['details']['fare']['total_client_pays'] +=
              jobFareRequest.totalToPayClient;
          newRequest['details']['fare']['total_client_night_surcharge'] =
              jobFareRequest.totalClientNightSurcharge;

          newRequest['details']['fare']['total_employee_night_surcharge'] =
              jobFareRequest.totalEmployeeNightSurcharge;
          newEvent['details']['fare']['total_to_pay_employees'] +=
              jobFareRequest.totalToPayEmployee;

          newRequest['details']['arrived_date'] = '';
          newRequest['details']['departed_date'] = '';

          await FirebaseServices.db
              .collection('requests')
              .doc(request.id)
              .update(newRequest);

          WebUser webUser =
              Provider.of<AuthProvider>(context, listen: false).webUser;

          String complement = !isEvenselected
              ? 'Se movió la solicitud con id ${request.id} del evento ${previousEvent['event_number']} a un nuevo evento, nombre del evento: ${newEvent['event_number']}'
              : 'Se movió la solicitud con id ${request.id} del evento ${previousEvent['event_number']} a un evento existente, nombre del evento ${newEvent['event_number']}';
          // String startDate = CodeUtils.formatDateWithoutHour(
          //     newRequest['details']['start_date']);
          // String endDate = CodeUtils.formatDateWithoutHour(
          //     newRequest['details']['end_date']);
          ActivityParams params = ActivityParams(
            description: complement,
            category: {
              "key": "requests",
              "name": "Solicitudes",
            },
            personInCharge: {
              "name": CodeUtils.getFormatedName(
                  webUser.profileInfo.names, webUser.profileInfo.lastNames),
              "type_key": webUser.accountInfo.type,
              "type_name":
                  CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
              "id": webUser.uid,
              "company_id": webUser.accountInfo.companyId
            },
            affectedUser: {
              "id": "",
              "name": "",
              "type_key": "",
              "type_name": ""
            },
            date: DateTime.now(),
          );

          await ActivityService.saveChange(params);
        },
      );
      if (isEvenselected && newEvent['id'] == previousEvent['id']) {
        await FirebaseServices.db
            .collection('events')
            .doc(newEvent['id'])
            .update(newEvent);
      } else {
        await FirebaseServices.db
            .collection('events')
            .doc(newEvent['id'])
            .set(newEvent);

        await FirebaseServices.db
            .collection('events')
            .doc(previousEvent['id'])
            .update(previousEvent);
      }
      if (canDeleteEvent) {
        await FirebaseServices.db
            .collection("deleted_events")
            .doc(previousEvent['id'])
            .set(previousEvent);
        await FirebaseServices.db
            .collection('events')
            .doc(previousEvent['id'])
            .delete();
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }
}
