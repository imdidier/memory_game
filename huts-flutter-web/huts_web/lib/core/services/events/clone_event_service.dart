import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/features/auth/domain/entities/company.dart';
import 'package:huts_web/features/clients/data/models/client_model.dart';
import 'package:huts_web/features/general_info/domain/entities/country_info_entity.dart';
import 'package:huts_web/features/requests/display/providers/create_event_provider.dart';
import '../../../features/clients/domain/entities/client_entity.dart';
import '../../../features/requests/domain/entities/request_entity.dart';
import '../../utils/code/code_utils.dart';
import '../employee_services/employee_availability_service.dart';
import '../fares/job_fare_service.dart';

class CloneEventService {
  static late Map<String, dynamic> _newEventData;
  static late ClientEntity? _client;
  static DateTime _newDate = DateTime.now();
  static late CountryInfo _countryInfo;

  static Future<Either<ServerException, bool>> run(
    String eventName,
    List<Request> requests,
    CountryInfo countryInfo,
    DateTime newDate,
  ) async {
    try {
      _newEventData = {
        "id": FirebaseServices.db.collection("events").doc().id,
        "event_number": eventName,
        "details": {"total_hours": 0},
      };

      _newDate = newDate;
      _countryInfo = countryInfo;
      await _getClient(requests[0].clientInfo.id);
      if (_client == null) {
        return const Left(
          ServerException("No se pudo obtener la información del cliente"),
        );
      }

      bool allJobsAvaliable = true;

      for (Request request in requests) {
        bool isIn =
            _client!.jobs.keys.toList().contains(request.details.job["value"]);
        if (!isIn) {
          allJobsAvaliable = false;
          break;
        }
      }

      if (!allJobsAvaliable) {
        return const Left(
          ServerException(
              "Un cargo del evento a clonar ya no está disponible para el cliente"),
        );
      }

      WriteBatch batch = FirebaseServices.db.batch();

      bool allRequestsDataGotten = true;

      await Future.forEach(
        requests,
        (Request eventRequest) async {
          Map<String, dynamic>? requestData =
              await _getNewRequestdata(eventRequest);
          if (requestData == null) {
            allRequestsDataGotten = false;
            return;
          }
          DocumentReference docRef =
              FirebaseServices.db.collection("requests").doc(requestData["id"]);

          batch.set(docRef, requestData);
        },
      );

      if (!allRequestsDataGotten) {
        return const Left(
          ServerException("Ocurrió un error al clonar una solicitud"),
        );
      }

      await FirebaseServices.db
          .collection("events")
          .doc(_newEventData["id"])
          .set(_newEventData);

      await batch.commit();

      return const Right(true);
    } catch (e) {
      if (kDebugMode) print("CloneEventService, run error: $e");
      return const Left(
          ServerException("Ocurrió un error al clonar el evento"));
    }
  }

  static Future<void> _getClient(String id) async {
    try {
      DocumentSnapshot clientDoc =
          await FirebaseServices.db.collection("clients").doc(id).get();
      _client = ClientModel.fromMap(clientDoc.data() as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print("CloneEventService, _getClient error: $e");
      _client = null;
    }
  }

  static Future<JobRequest?> _getJobRequest(
      DateTime startDate, DateTime endDate, Request request) async {
    try {
      return JobRequest(
        clientInfo: {
          "id": _client!.accountInfo.id,
          "image": _client!.imageUrl,
          "name": _client!.name,
          "country": "Costa Rica",
        },
        eventId: _newEventData["id"],
        eventName: _newEventData["event_number"],
        startDate: startDate,
        endDate: endDate,
        location: request.details.location,
        fareType: "",
        job: {
          "name": request.details.job["name"]!,
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
    } catch (e) {
      if (kDebugMode) print("CloneEventService, _getJobRequest error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _getNewRequestdata(
    Request request,
  ) async {
    try {
      DateTime startRequestDate = DateTime(
        _newDate.year,
        _newDate.month,
        _newDate.day,
        request.details.startDate.hour,
        request.details.startDate.minute,
      );

      DateTime endRequestDate = startRequestDate.add(
        Duration(minutes: (request.details.totalHours * 60).toInt()),
      );

      //Get job request
      JobRequest? jobRequest =
          await _getJobRequest(startRequestDate, endRequestDate, request);
      if (jobRequest == null) return null;

      //Get new job fare//
      Map<String, dynamic> jobMap = _client!.jobs[request.details.job["value"]];
      Job job = Job(
        name: jobMap["name"],
        value: jobMap["value"],
        fares: jobMap["fares"],
      );

      JobRequest finalJobRequest = await JobFareService.get(
        job,
        jobRequest,
        startRequestDate,
        endRequestDate,
        _client!.accountInfo.hasDynamicFare,
        _client!.accountInfo.id,
        _countryInfo,
      );

      Map<String, dynamic> employeeInfo = {
        "doc_number": request.employeeInfo.docNumber,
        "doc_type": request.employeeInfo.docType,
        "last_names": request.employeeInfo.lastNames,
        "names": request.employeeInfo.names,
        "phone": request.employeeInfo.phone,
        "image": request.employeeInfo.imageUrl,
        "id": request.employeeInfo.id,
      };

      int newStatus = request.details.status;

      //If request is already assigned, validate employee availability //
      if (request.details.status > 0) {
        (bool, double)? isAvaliable = await EmployeeAvailabilityService.get(
          startRequestDate,
          endRequestDate,
          request.employeeInfo.id,
        );

        if (isAvaliable == null) return null;

        if (!isAvaliable.$1) {
          newStatus = 0;
          employeeInfo = {};
        }
      }

      String newRequestId = FirebaseServices.db.collection("requests").doc().id;

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
          "status": newStatus != 0 ? 1 : 0,
          "total_hours": finalJobRequest.employeeHours,
        },
        "employee_info": employeeInfo,
        "event_id": _newEventData["id"],
        "event_number": finalJobRequest.eventName,
        "id": newRequestId,
        "year": finalJobRequest.startDate.year,
        "month": finalJobRequest.startDate.month,
        "week_start":
            "${finalJobRequest.startDate.year}-${CodeUtils.getFormatStringNum(finalJobRequest.startDate.month)}-${CodeUtils.getFormatStringNum(finalJobRequest.startDate.day)}",
        "week_end": newWeekEnd,
      };

      String jobValue = finalJobRequest.job["value"];
      String jobName = finalJobRequest.job["name"];

      if (_newEventData["details"]["total_hours"] == 0) {
        _newEventData = {
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
                "name": jobName,
                "value": jobValue,
                "employees": 1,
                "total_hours": finalJobRequest.totalHours,
              },
            },
          },
          "week_end": newWeekEnd,
          "week_start": requestData["week_start"],
          "event_number": "${requestData['event_number']}",
          "id": _newEventData["id"],
          "month": requestData["month"],
          "year": requestData["year"],
          "week_cut": CodeUtils().getCutOffWeek(finalJobRequest.startDate),
        };
      } else {
        Map<String, dynamic> newEventFare = {
          "total_client_pays": _newEventData["details"]["fare"]
                  ["total_client_pays"] +
              finalJobRequest.totalToPayClient,
          "total_to_pay_employees": _newEventData["details"]["fare"]
                  ["total_to_pay_employees"] +
              finalJobRequest.totalToPayEmployee,
        };

        DateTime newEventStartDate = _newEventData["details"]["start_date"];
        if (finalJobRequest.startDate.isBefore(newEventStartDate)) {
          newEventStartDate = finalJobRequest.startDate;
        }

        DateTime newEventEndDate = _newEventData["details"]["end_date"];
        if (finalJobRequest.endDate.isAfter(newEventEndDate)) {
          newEventEndDate = finalJobRequest.endDate;
        }
        String weekStart =
            "${newEventStartDate.year}-${CodeUtils.getFormatStringNum(newEventStartDate.month)}-${CodeUtils.getFormatStringNum(newEventStartDate.day)}";

        String weekEnd =
            "${newEventEndDate.year}-${CodeUtils.getFormatStringNum(newEventEndDate.month)}-${CodeUtils.getFormatStringNum(newEventEndDate.day)}";

        _newEventData["details"]["start_date"] = newEventStartDate;
        _newEventData["details"]["end_date"] = newEventEndDate;
        _newEventData["week_start"] = weekStart;
        _newEventData["week_end"] = weekEnd;
        _newEventData["details"]["fare"] = newEventFare;
        _newEventData["details"]["total_hours"] = _newEventData["details"]
            ["total_hours"] += finalJobRequest.employeeHours;

        if (!_newEventData["employees_info"]["jobs_needed"]
            .containsKey(jobValue)) {
          _newEventData["employees_info"]["jobs_needed"][jobValue] = {
            "name": jobName,
            "value": jobValue,
            "emloyees": 0,
            "total_hours": 0,
          };
        }
        _newEventData["employees_info"]["jobs_needed"][jobValue]
            ["total_hours"] += finalJobRequest.employeeHours;
        _newEventData["employees_info"]["jobs_needed"][jobValue]["emloyees"]++;
        _newEventData["employees_info"]["employees_needed"]++;
      }
      return requestData;
    } catch (e) {
      if (kDebugMode) print("CloneEventService, _getNewRequestdata error: $e");
      return null;
    }
  }
}
