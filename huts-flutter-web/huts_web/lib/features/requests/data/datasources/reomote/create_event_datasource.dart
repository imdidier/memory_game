// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/requests/data/models/event_model.dart';
import 'package:huts_web/features/requests/display/providers/create_event_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/activity_service.dart';
import '../../../../../core/use_cases_params/activity_params.dart';
import '../../../domain/entities/request_entity.dart';

abstract class CreateEventDatasource {
  Future<String> createEvent(EventModel event, bool isAdmin);
  Future<bool> updateNameEvent(String eventId, String nameEvent);
  Future<bool> deleteEvent(EventModel event, List<Request> requests);
  Future<bool> createRequests(List<JobRequest> jobsRequests);
}

class CreateEventDatasourceImpl implements CreateEventDatasource {
  @override
  Future<String> createEvent(EventModel event, bool isAdmin) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("events")
          .where("id", isEqualTo: event.id)
          .get();

      if (querySnapshot.size > 0) return event.id;

      await FirebaseServices.db
          .collection("events")
          .doc(event.id)
          .set(event.toMap());

      await FirebaseServices.db
          .collection("clients")
          .doc(event.clientInfo.id)
          .update({
        "account_info.total_requests":
            FieldValue.increment(event.employeesInfo.neededEmployees)
      });

      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return "created";

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;

      await FirebaseServices.db.collection("activity").add(
        {
          "description":
              "Se creó el evento ${event.eventName} con ${event.employeesInfo.neededEmployees} solicitudes para el cliente: ${event.clientInfo.name}",
          "category": {
            "key": "events",
            "name": "Eventos",
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

      return "created";
    } catch (e) {
      if (kDebugMode) {
        print("CreateEventDatasource, createEvent error: $e");
      }
      return "fail";
    }
  }

  @override
  Future<bool> createRequests(List<JobRequest> jobsRequests) async {
    try {
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
                "total_client_night_surcharge":
                    jobRequest.totalClientNightSurcharge,
                "total_employee_night_surcharge":
                    jobRequest.totalEmployeeNightSurcharge,
              },
              "job": jobRequest.job,
              "location": jobRequest.location,
              "indications": jobRequest.indications,
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
            "CreateEventDatasource, createRequests, batch error: $error",
          );
        }
      });
      return itsOk;
    } catch (e) {
      if (kDebugMode) {
        print("CreateEventDatasource, createRequests error: $e");
      }
      return false;
    }
  }

  @override
  Future<bool> updateNameEvent(String eventId, String nameEvent) async {
    try {
      WriteBatch batch = FirebaseServices.db.batch();
      await FirebaseServices.db
          .collection('events')
          .doc(eventId)
          .update({"event_number": nameEvent});

      QuerySnapshot query = await FirebaseServices.db
          .collection('requests')
          .where('event_id', isEqualTo: eventId)
          .get();
      for (DocumentSnapshot requestDoc in query.docs) {
        DocumentReference docRef =
            FirebaseServices.db.collection('requests').doc(requestDoc.id);

        batch.update(docRef, {'event_number': nameEvent});
      }
      await batch.commit();
      return true;
    } catch (e) {
      if (kDebugMode) print('CreateEventDataSource, updateNameEvent error: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteEvent(EventModel event, List<Request> requests) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser = context.read<AuthProvider>().webUser;

      await Future.forEach(
        requests,
        (Request request) async {
          await FirebaseServices.db
              .collection("deleted_requests")
              .doc(request.id)
              .set(request.toMap());

          await FirebaseServices.db
              .collection("requests")
              .doc(request.id)
              .delete();

          await FirebaseServices.db
              .collection("clients")
              .doc(event.clientInfo.id)
              .update(
                  {"account_info.total_requests": FieldValue.increment(-1)});

          ActivityParams params = ActivityParams(
            description:
                "Se eliminó la solicitud con id: ${request.id}. Del evento: ${event.eventName}",
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

      await FirebaseServices.db
          .collection("deleted_events")
          .doc(event.id)
          .set(event.toMap());

      await FirebaseServices.db.collection('events').doc(event.id).delete();
      ActivityParams params = ActivityParams(
        description:
            "Se eliminó el evento ${event.eventName} con id: ${event.id}, del cliente ${event.clientInfo.name}",
        category: {
          "key": "events",
          "name": "Eventos",
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
      if (kDebugMode) print('CreateEventDataSource, deleteEvent error: $e');
      return false;
    }
  }
}
