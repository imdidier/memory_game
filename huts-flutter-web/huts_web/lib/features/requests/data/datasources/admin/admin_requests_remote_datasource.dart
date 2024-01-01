// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/requests/data/models/event_model.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/domain/entities/event_entity.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/activity_service.dart';
import '../../../../../core/services/employee_services/employee_availability_service.dart';
import '../../../../../core/services/fares/job_fare_service.dart';
import '../../../../../core/services/navigation_service.dart';
import '../../../../../core/use_cases_params/activity_params.dart';
import '../../../../../core/utils/code/code_utils.dart';
import '../../../../auth/display/providers/auth_provider.dart';
import '../../../../auth/domain/entities/company.dart';
import '../../../../auth/domain/entities/web_user_entity.dart';
import '../../../../clients/display/provider/clients_provider.dart';
import '../../../display/providers/create_event_provider.dart';
import '../../../domain/entities/request_entity.dart';

abstract class AdminRequestsRemoteDatasource {
  Future<bool> addRequests(List<JobRequest> jobsRequests, String eventId);
  Future<bool> deleteRequest(Request request);
  Future<bool> updateRequest(
    Map<String, dynamic> updateMap,
    bool isEventSelected,
  );
  Future<String> cloneOrEditRequestsByEvent(
    List<Request> requestsList,
    String type,
    bool isEventSelected,
    Event event,
  );
  Future<Event> getEvent(String eventId);
  Future<List<Map<String, dynamic>>> getRequestHistorical(String requestId);
}

class AdminRequestsRemoteDatasourceImpl
    implements AdminRequestsRemoteDatasource {
  @override
  Future<bool> addRequests(
      List<JobRequest> jobsRequests, String eventId) async {
    try {
      DocumentSnapshot eventDoc =
          await FirebaseServices.db.collection("events").doc(eventId).get();

      EventModel event =
          EventModel.fromMap(eventDoc.data() as Map<String, dynamic>);

      for (JobRequest item in jobsRequests) {
        if (item.endDate.isAfter(event.details.endDate)) {
          event.details.endDate = item.endDate;
        }

        item.eventId = eventId;
        if (event.employeesInfo.neededJobs.containsKey(item.job["value"])) {
          event.employeesInfo.neededJobs[item.job["value"]]["employees"] +=
              item.employeesNumber;
          event.employeesInfo.neededJobs[item.job["value"]]["total_hours"] +=
              item.totalHours;
        } else {
          event.employeesInfo.neededJobs[item.job["value"]] = {
            "employees": item.employeesNumber,
            "total_hours": item.totalHours,
            "name": item.job["name"],
            "value": item.job["value"],
          };
        }

        event.details.totalHours += item.totalHours;
        event.details.fare.totalClientPays += item.totalToPayClient;
        event.details.fare.totalToPayEmployees +=
            item.totalToPayEmployee * item.employeesNumber;
        event.employeesInfo.neededEmployees += item.employeesNumber;
      }

      await FirebaseServices.db
          .collection("events")
          .doc(eventId)
          .set(event.toMap());

      await FirebaseServices.db
          .collection("clients")
          .doc(event.clientInfo.id)
          .update({
        "account_info.total_requests":
            FieldValue.increment(event.employeesInfo.neededEmployees)
      });

      bool itsOk = true;
      WriteBatch writeBatch = FirebaseServices.db.batch();

      for (JobRequest jobRequest in jobsRequests) {
        for (int i = 0; i < jobRequest.employeesNumber; i++) {
          DocumentReference docReference =
              FirebaseServices.db.collection("requests").doc();

          Map<String, dynamic> employeeRequestData = {
            "client_info": jobRequest.clientInfo,
            "details": {
              "arrived_date": "",
              "departed_date": "",
              "fare": {
                "fare_type": jobRequest.fareType,
                "client_fare": {
                  "dynamic": jobRequest.clientFare.dynamicFare,
                  "holiday": jobRequest.clientFare.holidayFare,
                  "normal": jobRequest.clientFare.normalFare,
                },
                "employee_fare": {
                  "dynamic": jobRequest.employeeFare.dynamicFare,
                  "holiday": jobRequest.employeeFare.holidayFare,
                  "normal": jobRequest.employeeFare.normalFare,
                },
                "total_client_pays": jobRequest.totalToPayClientPerEmployee,
                "total_to_pay_employee": jobRequest.totalToPayEmployee,
              },
              "job": jobRequest.job,
              "location": jobRequest.location,
              "indications": jobRequest.indications,
              "references": jobRequest.references,
              "rate": {},
              "start_date": jobRequest.startDate,
              "end_date": jobRequest.endDate,
              "status": 0,
              "total_hours": jobRequest.employeeHours,
            },
            "employee_info": {},
            "event_id": jobRequest.eventId,
            "event_number": jobRequest.eventName,
            "id": docReference.id,
            "year": jobRequest.startDate.year,
            "month": jobRequest.startDate.month,
            "week_start":
                "${jobRequest.startDate.year}-${CodeUtils.getFormatStringNum(jobRequest.startDate.month)}-${CodeUtils.getFormatStringNum(jobRequest.startDate.day)}",
            "week_end":
                "${jobRequest.endDate.year}-${CodeUtils.getFormatStringNum(jobRequest.endDate.month)}-${CodeUtils.getFormatStringNum(jobRequest.endDate.day)}",
          };
          writeBatch.set(
            docReference,
            employeeRequestData,
          );
        }
      }
      await writeBatch.commit().catchError((dynamic error) {
        itsOk = false;
        if (kDebugMode) {
          print(
            "AdminRequestsRemoteDatasource, addRequests, batch error: $error",
          );
        }
      });

      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return itsOk;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;

      await FirebaseServices.db.collection("activity").add(
        {
          "description":
              "Se agregaron ${jobsRequests.length} solicitudes al evento ${event.eventName}",
          "category": {
            "key": "requests",
            "name": "solicitudes",
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

      return itsOk;
    } catch (e) {
      if (kDebugMode) {
        print("AdminRequestsRemoteDatasource, addRequests error:  $e");
      }
      return false;
    }
  }

  @override
  Future<bool> deleteRequest(Request request) async {
    try {
      DocumentSnapshot eventDoc = await FirebaseServices.db
          .collection("events")
          .doc(request.eventId)
          .get();

      EventModel event =
          EventModel.fromMap(eventDoc.data() as Map<String, dynamic>);

      bool deleteEvent =
          event.details.totalHours - request.details.totalHours == 0;

      if (!deleteEvent) {
        event.employeesInfo.neededJobs[request.details.job["value"]]
            ["employees"]--;

        event.employeesInfo.neededJobs[request.details.job["value"]]
            ["total_hours"] -= request.details.totalHours;

        event.details.totalHours -= request.details.totalHours;
        event.details.fare.totalClientPays -=
            request.details.fare.totalClientPays;

        event.details.fare.totalToPayEmployees -=
            request.details.fare.totalToPayEmployee;

        event.employeesInfo.neededEmployees--;

        if (request.details.status >= 1) {
          event.employeesInfo.acceptedEmployees--;
        }
      }

      await FirebaseServices.db
          .collection("deleted_requests")
          .doc(request.id)
          .set(request.toMap());

      await FirebaseServices.db.collection("requests").doc(request.id).delete();

      await FirebaseServices.db
          .collection("clients")
          .doc(event.clientInfo.id)
          .update({"account_info.total_requests": FieldValue.increment(-1)});

      if (deleteEvent) {
        await FirebaseServices.db
            .collection("deleted_events")
            .doc(request.eventId)
            .set(event.toMap());

        await FirebaseServices.db
            .collection("events")
            .doc(request.eventId)
            .delete();
      } else {
        await FirebaseServices.db
            .collection("events")
            .doc(request.eventId)
            .set(event.toMap());
      }

      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;

      await FirebaseServices.db.collection("activity").add(
        {
          "description":
              "Se eliminó la solicitud con id: ${request.id}. Del evento: ${event.eventName}",
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
          "AdminRequestsRemoteDatasource, deleteRequest, error: $e",
        );
      }

      return false;
    }
  }

  @override
  Future<Event> getEvent(String eventId) async {
    try {
      DocumentSnapshot eventDoc =
          await FirebaseServices.db.collection("events").doc(eventId).get();
      return EventModel.fromMap(eventDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  void updateNameEvent(String eventId, String nameEvent) async {}

  @override
  Future<bool> updateRequest(
    Map<String, dynamic> updateMap,
    bool isEventSelected,
  ) async {
    try {
      Event newEvent = updateMap["new_event"];
      Map<String, dynamic> newEventMoveRequest = {};
      String uidNewEvent = '';
      // String uidNewRequest = '';
      Request previousRequest = updateMap["previous_request"];

      if (!isEventSelected) {
        newEventMoveRequest = updateMap["move_request_new_event"];

        uidNewEvent = FirebaseServices.db.collection("events").doc().id;
        newEventMoveRequest['id'] = uidNewEvent;
        await FirebaseServices.db
            .collection('events')
            .doc(uidNewEvent)
            .set(newEventMoveRequest);
        updateMap['new_data']['event_id'] = uidNewEvent;
        updateMap['new_data']['event_number'] =
            newEventMoveRequest['event_number'];
      }

      DocumentSnapshot oldRequestDoc = await FirebaseServices.db
          .collection("requests")
          .doc(previousRequest.id)
          .get();

      //Update status employee
      if (updateMap["new_data"]['details.status'] != 0 &&
          previousRequest.details.status != 0 &&
          previousRequest.employeeInfo.id.isNotEmpty) {
        await FirebaseServices.db
            .collection('employees')
            .doc(updateMap["new_data"]["employee_info"]['id'])
            .update({
          'account_info.status':
              updateMap["new_data"]["details.status"] != 3 ? 1 : 2
        });
      }
      Map<String, dynamic> oldRequestData =
          oldRequestDoc.data() as Map<String, dynamic>;

      //Update Request
      await FirebaseServices.db
          .collection("requests")
          .doc(previousRequest.id)
          .update(Map<String, Object?>.from(updateMap["new_data"]));

      //Save edition to request historical -> Start//
      BuildContext? globalContext = NavigationService.getGlobalContext();
      WebUser? webUser;

      if (globalContext != null) {
        webUser =
            Provider.of<AuthProvider>(globalContext, listen: false).webUser;
      }

      await FirebaseServices.db
          .collection("requests")
          .doc(previousRequest.id)
          .collection("historical")
          .add({
        "event_id": newEvent.id,
        "event_number": newEvent.eventName,
        "update_date": DateTime.now(),
        "client_info": {
          "id": newEvent.clientInfo.id,
          "name": newEvent.clientInfo.name,
          "image": newEvent.clientInfo.imageUrl,
          "country": newEvent.clientInfo.country,
        },
        "details": {
          "job": previousRequest.details.job,
          "start_date": previousRequest.details.startDate,
          "end_date": previousRequest.details.endDate,
          "user_type": (webUser != null) ? webUser.accountInfo.type : "",
          "person_in_charge": (webUser != null)
              ? "${webUser.profileInfo.names} ${webUser.profileInfo.lastNames}"
              : "",
          "description": "Solicitud modificada"
        },
        "old_data": oldRequestData,
        "new_data": updateMap["new_data"],
      });
      //Save edition to request historical -> End//

      //Set new info and update event//

      //If the request start date is before that the event start date, update event date
      if (updateMap["new_data"]["details.start_date"]
          .isBefore(newEvent.details.startDate)) {
        newEvent.details.startDate =
            updateMap["new_data"]["details.start_date"];
        newEvent.year = updateMap["new_data"]["year"];
        newEvent.month = updateMap["new_data"]["month"];
        newEvent.startWeek = updateMap["new_data"]["week_start"];
      }

      //If the request end date is after that the event end date, update event date
      if (updateMap["new_data"]["details.end_date"]
          .isAfter(newEvent.details.endDate)) {
        newEvent.details.endDate = updateMap["new_data"]["details.end_date"];
        newEvent.year = updateMap["new_data"]["year"];
        newEvent.month = updateMap["new_data"]["month"];
        newEvent.endWeek = updateMap["new_data"]["week_end"];
      }

      int newRequestStatus = updateMap["new_data"]["details.status"];
      String newJobKey = updateMap["new_data"]["details.job"]["value"];
      String previousJobKey = updateMap["new_data"]["details.job"]["value"];

      //If the request event was not changed
      if (isEventSelected) {
        if (newEvent.id == previousRequest.eventId) {
          newEvent.details.totalHours -= previousRequest.details.totalHours;

          newEvent.details.fare.totalClientPays -=
              previousRequest.details.fare.totalClientPays;
          newEvent.details.fare.totalToPayEmployees -=
              previousRequest.details.fare.totalToPayEmployee;

          newEvent.details.totalHours +=
              updateMap["new_data"]["details.total_hours"];

          newEvent.details.fare.totalClientPays +=
              updateMap["new_data"]["details.fare"]["total_client_pays"];
          newEvent.details.fare.totalToPayEmployees +=
              updateMap["new_data"]["details.fare"]["total_to_pay_employee"];

          //If the request status was changed
          if (newRequestStatus != previousRequest.details.status) {
            // if (newRequestStatus > 1 ||
            //     newEvent.employeesInfo.acceptedEmployees > 0 &&
            //         newEvent.employeesInfo.arrivedEmployees > 0) {
            //   newEvent.employeesInfo.acceptedEmployees--;
            //   newEvent.employeesInfo.arrivedEmployees--;
            // }

            // if (newRequestStatus >= 2 && newRequestStatus < 5) {
            //   newEvent.employeesInfo.acceptedEmployees++;
            //   if (newRequestStatus == 3 || newRequestStatus == 4) {
            //     newEvent.employeesInfo.arrivedEmployees++;
            //   }
            // }
            if (newRequestStatus < 5 && previousRequest.details.status >= 5) {
              // isEventSelected
              // ?
              newEvent.employeesInfo.neededEmployees++;
              // : newEvent.employeesInfo.neededEmployees--;
              // isEventSelected
              // ?
              newEvent.employeesInfo.neededJobs[previousJobKey]['employees']++;
              // : newEvent.employeesInfo.neededJobs[previousJobKey]
              // ['employees']--;
              // isEventSelected
              // ?
              newEvent.employeesInfo.neededJobs[previousJobKey]
                      ["total_hours"] +=
                  updateMap["new_data"]["details.total_hours"];
              // : newEvent.employeesInfo.neededJobs[previousJobKey]
              // ["total_hours"] -=
              // updateMap["new_data"]["details.total_hours"];
            }

            if (newRequestStatus == 2) {
              newEvent.employeesInfo.acceptedEmployees++;
              if (previousRequest.details.status == 3 ||
                  previousRequest.details.status == 4) {
                newEvent.employeesInfo.acceptedEmployees--;
              }
            }

            if (newRequestStatus == 3 || newRequestStatus == 4) {
              newEvent.employeesInfo.arrivedEmployees++;
              if (previousRequest.details.status < 2 ||
                  previousRequest.details.status > 4) {
                isEventSelected
                    ? newEvent.employeesInfo.acceptedEmployees++
                    : newEvent.employeesInfo.acceptedEmployees--;
              }
            }

            if (previousRequest.details.status == 3 ||
                previousRequest.details.status == 4 &&
                    (newRequestStatus < 3 || newRequestStatus > 4)) {
              newEvent.employeesInfo.arrivedEmployees--;
            }
            if (previousRequest.details.status >= 2 &&
                previousRequest.details.status < 5 &&
                (newRequestStatus < 2 || newRequestStatus > 4)) {
              newEvent.employeesInfo.acceptedEmployees--;
            }
            if (newRequestStatus > 4) {
              newEvent.employeesInfo.neededEmployees--;
              newEvent.employeesInfo.neededJobs[previousJobKey]['employees']--;
              newEvent.employeesInfo.neededJobs[previousJobKey]
                      ["total_hours"] -=
                  updateMap["new_data"]["details.total_hours"];
            }
          }

          //If the request job was changed
          if (previousJobKey != newJobKey) {
            //If there are more than one employee in the previous job
            if (newEvent.employeesInfo.neededJobs[previousJobKey]["employees"] >
                1) {
              newEvent.employeesInfo.neededJobs[previousJobKey]["employees"]--;
              newEvent.employeesInfo.neededJobs[previousJobKey]
                      ["total_hours"] -=
                  updateMap["new_data"]["details.total_hours"];
            } else {
              newEvent.employeesInfo.neededJobs.remove(previousJobKey);
            }
          }
        } else {
          // Start changes to the event to which the request to move belonged
          DocumentSnapshot queryPreviousRequestEvent = await FirebaseServices.db
              .collection('events')
              .doc(previousRequest.eventId)
              .get();

          Map<String, dynamic> previousRequestEvent =
              queryPreviousRequestEvent.data() as Map<String, dynamic>;

          previousRequestEvent['details']['fare']['total_client_pays'] -=
              previousRequest.details.fare.totalClientPays;
          previousRequestEvent['details']['fare']['total_to_pay_employees'] -=
              previousRequest.details.fare.totalToPayEmployee;

          previousRequestEvent['details']['total_hours'] -=
              previousRequest.details.totalHours;

          previousRequestEvent['employees_info']['employees_needed']--;

          if (previousRequest.details.status == 2) {
            previousRequestEvent['employees_info']['employees_accepted']--;
          }

          if (previousRequest.details.status == 3) {
            previousRequestEvent['employees_info']['employees_arrived']--;
          }

          previousRequestEvent['employees_info']['jobs_needed'][newJobKey]
              ['employees']--;

          previousRequestEvent['employees_info']['jobs_needed'][newJobKey]
              ['total_hours'] -= previousRequest.details.totalHours;

          if (previousRequestEvent['employees_info']['jobs_needed'][newJobKey]
                  ['employees'] ==
              0) {
            previousRequestEvent['employees_info']['jobs_needed']
                .remove(newJobKey);
          }

          await FirebaseServices.db
              .collection('events')
              .doc(previousRequest.eventId)
              .update(previousRequestEvent);
          if (previousRequestEvent['details']['total_hours'] == 0) {
            await FirebaseServices.db
                .collection("deleted_events")
                .doc(previousRequest.eventId)
                .set(previousRequestEvent);

            await FirebaseServices.db
                .collection('events')
                .doc(previousRequest.eventId)
                .delete();
          }

          //End changes to the event to which the request to move belonged

          newEvent.details.totalHours +=
              updateMap["new_data"]["details.total_hours"];

          newEvent.details.fare.totalClientPays +=
              updateMap["new_data"]["details.fare"]["total_client_pays"];

          newEvent.details.fare.totalToPayEmployees +=
              updateMap["new_data"]["details.fare"]["total_to_pay_employee"];

          if (previousRequest.details.status >= 0 &&
              previousRequest.details.status < 5) {
            newEvent.employeesInfo.neededEmployees++;
          }

          if (previousRequest.details.status == 2) {
            newEvent.employeesInfo.acceptedEmployees++;
          }

          if (previousRequest.details.status == 3) {
            newEvent.employeesInfo.arrivedEmployees++;
          }

          if (newEvent.employeesInfo.neededJobs.containsKey(newJobKey)) {
            newEvent.employeesInfo.neededJobs[newJobKey]["employees"] += 1;
            newEvent.employeesInfo.neededJobs[newJobKey]["total_hours"] +=
                updateMap["new_data"]["details.total_hours"];
          } else {
            newEvent.employeesInfo.neededJobs[newJobKey] = {
              "name": updateMap["new_data"]["details.job"]["name"],
              "value": newJobKey,
              "employees": 1,
              "total_hours": updateMap["new_data"]["details.total_hours"],
            };
          }
        }
      }
      //If the request event was changed
      else {
        isEventSelected
            ? newEvent.details.totalHours +=
                updateMap["new_data"]["details.total_hours"]
            : newEvent.details.totalHours -=
                updateMap["new_data"]["details.total_hours"];

        isEventSelected
            ? newEvent.details.fare.totalClientPays +=
                updateMap["new_data"]["details.fare"]["total_client_pays"]
            : newEvent.details.fare.totalClientPays -=
                updateMap["new_data"]["details.fare"]["total_client_pays"];
        isEventSelected
            ? newEvent.details.fare.totalToPayEmployees +=
                updateMap["new_data"]["details.fare"]["total_to_pay_employee"]
            : newEvent.details.fare.totalToPayEmployees -=
                updateMap["new_data"]["details.fare"]["total_to_pay_employee"];

        if (newRequestStatus >= 2 && newRequestStatus < 5) {
          isEventSelected
              ? newEvent.employeesInfo.acceptedEmployees++
              : newEvent.employeesInfo.acceptedEmployees--;
          if (newRequestStatus == 3 || newRequestStatus == 4) {
            isEventSelected
                ? newEvent.employeesInfo.arrivedEmployees++
                : newEvent.employeesInfo.arrivedEmployees--;
          }
        }

        if (!isEventSelected) newEvent.employeesInfo.neededEmployees--;
        //If the new event contain the new job
        if (newEvent.employeesInfo.neededJobs.containsKey(newJobKey)) {
          isEventSelected
              ? newEvent.employeesInfo.neededJobs[newJobKey]["employees"]++
              : newEvent.employeesInfo.neededJobs[newJobKey]["employees"]--;

          isEventSelected
              ? newEvent.employeesInfo.neededJobs[newJobKey]["total_hours"] +=
                  updateMap["new_data"]["details.total_hours"]
              : newEvent.employeesInfo.neededJobs[newJobKey]["total_hours"] -=
                  updateMap["new_data"]["details.total_hours"];
          if (newEvent.employeesInfo.neededJobs[newJobKey]["employees"] == 0) {
            newEvent.employeesInfo.neededJobs.remove(newJobKey);
          }
        } else {
          newEvent.employeesInfo.neededJobs[newJobKey] = {
            "name": updateMap["new_data"]["details.job"]["name"],
            "value": newJobKey,
            "employees": 1,
            "total_hours": updateMap["new_data"]["details.total_hours"],
          };
        }
      }

      await FirebaseServices.db.collection("events").doc(newEvent.id).update({
        "details.start_date": newEvent.details.startDate,
        "details.end_date": newEvent.details.endDate,
        "details.total_hours": newEvent.details.totalHours,
        "details.fare": {
          "total_client_pays": newEvent.details.fare.totalClientPays,
          "total_to_pay_employees": newEvent.details.fare.totalToPayEmployees,
        },
        "employees_info": {
          "employees_accepted": newEvent.employeesInfo.acceptedEmployees,
          "employees_arrived": newEvent.employeesInfo.arrivedEmployees,
          "employees_needed": newEvent.employeesInfo.neededEmployees,
          "jobs_needed": newEvent.employeesInfo.neededJobs,
        },
        "year": newEvent.year,
        "month": newEvent.month,
        "week_end": newEvent.endWeek,
        "week_start": newEvent.startWeek,
        "week_cut": CodeUtils().getCutOffWeek(newEvent.details.startDate),
      });

      if (newEvent.details.totalHours == 0) {
        await FirebaseServices.db
            .collection("deleted_events")
            .doc(previousRequest.eventId)
            .set((newEvent as EventModel).toMap());
        await FirebaseServices.db
            .collection('events')
            .doc(previousRequest.eventId)
            .delete();
      }

      await FirebaseServices.db.collection("activity").add(
        {
          "description":
              "Se modificó la solicitud con id: ${previousRequest.id}. Del evento: ${newEvent.eventName}",
          "category": {
            "key": "requests",
            "name": "Solicitudes",
          },
          "person_in_charge": {
            "name": CodeUtils.getFormatedName(
                webUser!.profileInfo.names, webUser.profileInfo.lastNames),
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
          "AdminRequestsRemoteDatasource, updateRequest, error: $e",
        );
      }
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRequestHistorical(
      String requestId) async {
    try {
      List<Map<String, dynamic>> changesList = [];

      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("requests")
          .doc(requestId)
          .collection("historical")
          .get();

      changesList = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return changesList;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<String> cloneOrEditRequestsByEvent(List<Request> requestsList,
      String type, bool isEventSelected, Event event) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();
      if (context == null) return 'null-context';
      Map<String, dynamic> newEvent = {};
      Map<String, dynamic> newRequest = {};
      Map<String, dynamic> jobs =
          !isEventSelected ? {} : event.employeesInfo.neededJobs;
      String newRequestId = '';
      String newEventId = event.id;
      ClientsProvider clientsProvider = context.read<ClientsProvider>();
      GeneralInfoProvider generalInfoProvider =
          context.read<GeneralInfoProvider>();
      List<Request> allRequests =
          context.read<GetRequestsProvider>().allRequests;
      AuthProvider authProvider = context.read<AuthProvider>();

      bool hasDynamicfare = false;

      if (authProvider.webUser.accountInfo.type == 'client') {
        hasDynamicfare =
            authProvider.webUser.company.accountInfo['has_dynamic_fare'];
      } else {
        int clientIndex = clientsProvider.allClients.indexWhere((element) =>
            element.accountInfo.id == requestsList.first.clientInfo.id);
        if (clientIndex == -1) return 'client-not-exists';
        hasDynamicfare =
            clientsProvider.allClients[clientIndex].accountInfo.hasDynamicFare;
      }
      event = event as EventModel;
      newEvent = !isEventSelected && type == 'clone-requests'
          ? EventModel.emptyEvent().toMap()
          : event.toMap();
      if (type != 'clone-requests') {
        for (Request request in requestsList) {
          Request previousRequestData =
              allRequests.firstWhere((element) => element.id == request.id);
          newEvent['details']['total_hours'] = newEvent['details']
                  ['total_hours'] -
              previousRequestData.details.totalHours;
          newEvent['details']['fare']['total_client_pays'] = newEvent['details']
                  ['fare']['total_client_pays'] -
              previousRequestData.details.fare.totalClientPays;
          newEvent['details']['fare']['total_to_pay_employees'] =
              newEvent['details']['fare']['total_to_pay_employees'] -
                  previousRequestData.details.fare.totalToPayEmployee;
        }
      }

      if (type == 'clone-requests') {
        if (!isEventSelected) {
          newEventId = FirebaseServices.db.collection('events').doc().id;
          newEvent['client_info']['id'] = requestsList.first.clientInfo.id;
          newEvent['client_info']['country'] = 'Costa Rica'; //
          newEvent['client_info']['image'] =
              requestsList.first.clientInfo.imageUrl;
          newEvent['client_info']['name'] = requestsList.first.clientInfo.name;
          newEvent['event_number'] = event.eventName;
          newEvent['employees_info']['employees_needed'] = requestsList.length;
          newEvent['details']['location'] = requestsList.first.details.location;
          newEvent['details']['total_hours'] = 0;

          if (requestsList.any((element) => element.details.status == 0)) {
            newEvent['details']['status'] = 1;
          }
          if (requestsList.any((element) => element.details.status == 3) &&
              requestsList.every((element) => element.details.status != 0)) {
            newEvent['details']['status'] = 3;
          }
          if (requestsList.every((element) => element.details.status == 2)) {
            newEvent['details']['status'] = 2;
          }
          newEvent['year'] = requestsList.first.year;
          newEvent['month'] = requestsList.last.month;
        }
        newEvent['id'] = newEventId;
      }
      Map<String, dynamic> job =
          !isEventSelected ? requestsList.first.details.job : jobs.values.first;

      int contEmployees = 1;

      double totalHours = 0;

      await Future.forEach(
        requestsList,
        (Request request) async {
          newRequest = request.toMap();

          newEvent['details']['end_date'] =
              event.details.endDate.isAfter(requestsList.last.details.endDate)
                  ? event.details.endDate
                  : requestsList.last.details.endDate;
          newEvent['details']['start_date'] = event.details.startDate
                      .isBefore(requestsList.first.details.startDate) &&
                  isEventSelected
              ? event.details.startDate
              : requestsList.first.details.startDate;

          newEvent['month'] = requestsList.last.month;
          newEvent['year'] = requestsList.last.year;
          newEvent['week_end'] =
              event.details.endDate.isAfter(requestsList.last.details.endDate)
                  ? event.endWeek
                  : requestsList.last.endWeek;
          newEvent['week_start'] = event.details.startDate
                      .isBefore(requestsList.last.details.startDate) &&
                  isEventSelected
              ? event.startWeek
              : requestsList.first.startWeek;
          newEvent['week_cut'] = CodeUtils().getCutOffWeek(
            event.details.startDate
                        .isBefore(requestsList.last.details.startDate) &&
                    isEventSelected
                ? event.details.startDate
                : requestsList.first.details.startDate,
          );

          newEvent['details']['total_hours'] += request.details.totalHours;
          if (type == 'clone-requests' && !isEventSelected) {
            //Update Client requests count
            await FirebaseServices.db
                .collection("clients")
                .doc(request.clientInfo.id)
                .update(
                    {"account_info.total_requests": FieldValue.increment(1)});
          }
          if (type == 'clone-requests' && isEventSelected) {
            newEvent['employees_info']['employees_needed'] += 1;
          }

          newRequest['event_number'] = newEvent['event_number'];

          (bool, double)? isEmployeeAvailability = (false, 0);
          if (request.details.status > 0) {
            isEmployeeAvailability = await EmployeeAvailabilityService.get(
              request.details.startDate,
              request.details.endDate,
              request.employeeInfo.id,
              request.id,
            );
          }
          if (isEmployeeAvailability!.$1 != true &&
              type != 'clone-requests' &&
              newEvent['employees_info']['employees_arrived'] > 0 &&
              newEvent['employees_info']['employees_accepted'] > 0) {
            newEvent['employees_info']['employees_arrived'] =
                newEvent['employees_info']['employees_arrived'] - 1;
            newEvent['employees_info']['employees_accepted'] =
                newEvent['employees_info']['employees_accepted'] - 1;
            newEvent['details']['status'] = 1;
          }

          if (isEmployeeAvailability.$1 != true) {
            newRequest['details']['status'] = 0;
            newRequest['employee_info'] = {};
          } else {
            newRequest['details']['status'] = type != 'clone-requests'
                ? request.details.status
                : type == 'clone-requests'
                    ? request.details.status
                    : 1;
          }

          if (request.details.job['name'] == job['name']) {
            job = {
              'employees':
                  !isEventSelected ? contEmployees++ : job['employees'] += 1,
              'name': job['name'],
              'total_hours': !isEventSelected
                  ? totalHours += request.details.totalHours
                  : job['total_hours'] += request.details.totalHours,
              'value': request.details.job['value'],
            };
            jobs[job['value']] = job;
          } else {
            job = {
              'employees': 1,
              'name': request.details.job['name'],
              'total_hours': request.details.totalHours,
              'value': request.details.job['value'],
            };
            jobs[job['value']] = job;
          }

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
            totalToPayAllEmployees: 0,
            totalToPayClient: 0,
            totalToPayClientPerEmployee: 0,
            totalClientNightSurcharge: 0,
            totalEmployeeNightSurcharge: 0,
            employeesNumber: 1,
            indications: request.details.indications,
            references: request.details.references,
          );

          int indexRequestJob = generalInfoProvider.jobsFares.indexWhere(
              (element) => element['value'] == request.details.job['value']);

          if (indexRequestJob == -1) return 'job-not-exists';
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

          JobRequest jobFareRequest = await JobFareService.get(
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

          newRequest['details']['fare']['total_client_night_surcharge'] =
              jobFareRequest.totalClientNightSurcharge;

          newRequest['details']['fare']['total_employee_night_surcharge'] =
              jobFareRequest.totalEmployeeNightSurcharge;
          newRequest['details']['fare']['total_to_pay_employee'] =
              jobFareRequest.totalToPayEmployee;

          newEvent['details']['fare']['total_client_pays'] +=
              jobFareRequest.totalToPayClient;
          newEvent['details']['fare']['total_to_pay_employees'] +=
              jobFareRequest.totalToPayEmployee;

          newRequest['details']['arrived_date'] = '';
          newRequest['details']['departed_date'] = '';
          if (type == 'clone-requests') {
            newRequestId = FirebaseServices.db.collection('requests').doc().id;
            newRequest['id'] = newRequestId;
            newRequest['event_id'] = newEventId;
            await FirebaseServices.db
                .collection('requests')
                .doc(newRequestId)
                .set(newRequest);
          } else {
            await FirebaseServices.db
                .collection('requests')
                .doc(request.id)
                .update(newRequest);
          }
          WebUser webUser =
              Provider.of<AuthProvider>(context, listen: false).webUser;

          String complement = !isEventSelected
              ? 'Se clonó la solicitud con id $newRequestId del evento ${event.eventName} a un nuevo evento'
              : 'Se clonó la solicitud con id $newRequestId al evento ${newEvent['event_number']} a un evento existente';
          String startDate = CodeUtils.formatDateWithoutHour(
              newRequest['details']['start_date']);
          String endDate = CodeUtils.formatDateWithoutHour(
              newRequest['details']['end_date']);
          ActivityParams params = ActivityParams(
            description: type != 'clone-requests'
                ? 'Se modificó el horario de la solicitud a, fecha inicio: $startDate fecha fin: $endDate'
                : complement,
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

      newEvent['employees_info']['jobs_needed'] = jobs;
      if (type == 'clone-requests') {
        newEvent['details']['status'] = 1;
        await FirebaseServices.db
            .collection('events')
            .doc(newEventId)
            .set(newEvent);
      } else {
        await FirebaseServices.db
            .collection('events')
            .doc(newEventId)
            .update(newEvent);
      }

      return 'ok';
    } catch (e) {
      if (kDebugMode) {
        print(
            'AdminRequestsRemoteDatasource, cloneOrEditRequestsByEvent error: $e');
      }
      return ("$e");
    }
  }
}
