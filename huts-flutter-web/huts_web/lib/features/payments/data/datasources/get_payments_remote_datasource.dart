// ignore_for_file: avoid_web_libraries_in_flutter, use_build_context_synchronously

import 'dart:developer';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:huts_web/core/config.dart' as config;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/payments/data/models/payment_model.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/domain/entities/month_jobs_entity.dart';
import 'package:huts_web/features/payments/domain/entities/payment_entity.dart';
import 'package:huts_web/features/payments/domain/entities/payment_result_entity.dart';
import 'package:huts_web/features/requests/data/models/request_model.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

import '../../../../core/use_cases_params/export_payments_excel_params.dart';
import '../../../auth/display/providers/auth_provider.dart';

abstract class GetPaymentsRemoteDatasource {
  Future<PaymentResult?> getGeneralPayments({
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<PaymentResult?> getPaymentsByClient({
    required String clientId,
    required DateTime startDate,
  });
  Future<PaymentResult?> getRangePaymentsByClient({
    required String clientId,
    required DateTime startDate,
    required DateTime? endDate,
  });

  Future<bool> exportPaymentsToExcel({
    required ExportPaymentsToExcelParams params,
    required bool forClient,
  });

  void downloadFile(
    List<int> bytes,
    String fileName,
  );
}

class GetPaymentsRemoteDatasourceImpl implements GetPaymentsRemoteDatasource {
  List<Map<String, dynamic>> headers = [
    {
      "key": "employee",
      "display_name": "Colaborador",
      "width": 200,
    },
  ];
  @override
  Future<PaymentResult?> getGeneralPayments(
      {required DateTime startDate, required DateTime endDate}) async {
    try {
      List<Payment> individualPayments = [];
      List<Payment> groupPayments = [];
      List<DateJob> jobs = [];

      double totalAllHours = 0;
      double totalAllHoursNormal = 0;
      double totalAllHoursHoliday = 0;
      double totalAllHoursDynamic = 0;
      double totalAllClientPays = 0;
      double totalAllToPayEmployee = 0;

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseServices
          .db
          .collection('requests')
          .where("details.start_date", isGreaterThan: startDate)
          .where("details.start_date", isLessThanOrEqualTo: endDate)
          .get();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        Map<dynamic, dynamic> requestData = doc.data() as Map;
        Request request = RequestModel.fromMap(requestData);

        bool requestWithValidStatus =
            request.details.status >= 1 && request.details.status <= 4;

        if (requestWithValidStatus) {
          double hoursWorked = request.details.totalHours;
          double totalClientPays = request.details.fare.totalClientPays;
          double totalToPayEmployee = request.details.fare.totalToPayEmployee;
          String jobType = request.details.job["value"];
          String namesEmployee =
              "${request.employeeInfo.names.trim()} ${request.employeeInfo.lastNames.trim()}";

          if (namesEmployee != " ") {
            individualPayments.add(PaymentModel.fromMap(requestData));
            DateJob? monthJobToFind =
                jobs.firstWhereOrNull((element) => element.jobType == jobType);
            var indexToFind =
                jobs.indexWhere((element) => element.jobType == jobType);

            if (monthJobToFind == null && indexToFind == -1) {
              DateJob newMonthJob =
                  DateJob(jobType: jobType, employeesList: [namesEmployee]);
              jobs.add(newMonthJob);
            }

            if (monthJobToFind != null) {
              String? employeeToFind = monthJobToFind.employeesList
                  .firstWhereOrNull((element) => element == namesEmployee);
              if (employeeToFind == null) {
                jobs[indexToFind].employeesList.add(namesEmployee);
              }
            }
          }

          int paymentIndex = groupPayments.indexWhere((element) =>
              element.requestInfo.employeeInfo.id == request.employeeInfo.id);

          if (paymentIndex == -1) {
            groupPayments.add(PaymentModel.fromMap(requestData));
          } else {
            groupPayments[paymentIndex].totalHours += hoursWorked;
            groupPayments[paymentIndex].totalHoursNormal +=
                request.details.fare.clientFare.normalFare.hours;

            groupPayments[paymentIndex].totalHoursHoliday +=
                request.details.fare.clientFare.holidayFare.hours;

            groupPayments[paymentIndex].totalHoursDynamic +=
                request.details.fare.clientFare.dynamicFare.hours;

            groupPayments[paymentIndex].totalClientPays += totalClientPays;

            groupPayments[paymentIndex].totalToPayEmployee +=
                totalToPayEmployee;
            groupPayments[paymentIndex]
                .employeeRequests
                .add(RequestModel.fromMap(requestData));
          }

          totalAllHours += hoursWorked;

          totalAllHoursNormal +=
              request.details.fare.clientFare.normalFare.hours;

          totalAllHoursHoliday +=
              request.details.fare.clientFare.holidayFare.hours;

          totalAllHoursDynamic +=
              request.details.fare.clientFare.dynamicFare.hours;

          totalAllClientPays += totalClientPays;
          totalAllToPayEmployee += totalToPayEmployee;
        }
      }

      PaymentResult paymentResult = PaymentResult(
        week: '',
        month: '',
        totalHours: totalAllHours,
        totalHoursNormal: totalAllHoursNormal,
        totalHoursHoliday: totalAllHoursHoliday,
        totalHoursDynamic: totalAllHoursDynamic,
        totalClientPays: totalAllClientPays,
        totalToPayEmployee: totalAllToPayEmployee,
        individualPayments: individualPayments,
        groupPayments: groupPayments,
        jobs: jobs,
      );

      return paymentResult;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<PaymentResult?> getPaymentsByClient(
      {required String clientId, required DateTime startDate}) async {
    try {
      startDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        00,
        00,
      );
      List<Payment> individualPayments = [];
      List<Payment> groupPayments = [];
      List<DateJob> jobs = [];
      String week = CodeUtils().getCutOffWeek(startDate);
      String month = CodeUtils().formatYearMonthDate(startDate);
      List datesOfWeek = CodeUtils.getDatesByWeek(week, startDate);
      DateTime dateWeekStart = datesOfWeek[0];
      DateTime dateWeekEnd = datesOfWeek[1];
      DateTime dateMonthStart = datesOfWeek[2];
      DateTime dateMonthEnd = datesOfWeek[3];

      double totalAllHours = 0;
      double totalAllHoursNormal = 0;
      double totalAllHoursHoliday = 0;
      double totalAllHoursDynamic = 0;
      double totalAllClientPays = 0;
      double totalAllToPayEmployee = 0;

      // double totalAllHoursMonth = 0;
      // double totalAllHoursMonthNormal = 0;
      // double totalAllHoursMonthHoliday = 0;
      // double totalAllHoursMonthDynamic = 0;
      // double totalAllClientPaysMonth = 0;
      // double totalAllToPayEmployeeMonth = 0;

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseServices
          .db
          .collection('requests')
          .where("client_info.id", isEqualTo: clientId)
          .where("details.start_date", isGreaterThan: dateWeekStart)
          .where("details.start_date", isLessThan: dateWeekEnd)
          .get();
      QuerySnapshot<Map<String, dynamic>> querySnapshotMonth =
          await FirebaseServices.db
              .collection('requests')
              .where("client_info.id", isEqualTo: clientId)
              .where("details.start_date", isGreaterThan: dateMonthStart)
              .where("details.start_date", isLessThan: dateMonthEnd)
              .get();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        Map<dynamic, dynamic> requestData = doc.data() as Map;
        Request request = RequestModel.fromMap(requestData);
        double hoursWorked = request.details.totalHours;
        double totalClientPays = request.details.fare.totalClientPays;
        double totalToPayEmployee = request.details.fare.totalToPayEmployee;
        individualPayments.add(PaymentModel.fromMap(requestData));

        PaymentModel paymentModel = PaymentModel.fromMap(requestData);
        paymentModel.employeeRequests.add(request);

        if (groupPayments.isNotEmpty) {
          int indexPayment = groupPayments.indexWhere((payment) =>
              payment.requestInfo.employeeInfo.id == request.employeeInfo.id);
          Payment? paymentToFind = groupPayments.firstWhereOrNull((payment) =>
              payment.requestInfo.employeeInfo.id == request.employeeInfo.id);

          if (indexPayment != -1 && paymentToFind != null) {
            paymentToFind.totalHours = paymentToFind.totalHours + hoursWorked;

            if (request.details.fare.clientFare.normalFare.fare != 0) {
              paymentToFind.totalHoursNormal = paymentToFind.totalHoursNormal +
                  request.details.fare.clientFare.normalFare.hours;
            }
            if (request.details.fare.clientFare.holidayFare.fare != 0) {
              paymentToFind.totalHoursHoliday =
                  paymentToFind.totalHoursHoliday +
                      request.details.fare.clientFare.holidayFare.hours;
            }
            if (request.details.fare.clientFare.dynamicFare.fare != 0) {
              paymentToFind.totalHoursDynamic =
                  paymentToFind.totalHoursDynamic +
                      request.details.fare.clientFare.dynamicFare.hours;
            }

            paymentToFind.totalClientPays =
                paymentToFind.totalClientPays + totalClientPays;

            paymentToFind.totalToPayEmployee =
                paymentToFind.totalToPayEmployee + totalToPayEmployee;
            paymentToFind.employeeRequests.add(request);
            groupPayments[indexPayment] = paymentToFind;
          } else {
            groupPayments.add(paymentModel);
          }
        } else {
          groupPayments.add(paymentModel);
        }

        totalAllHours = totalAllHours + hoursWorked;
        if (request.details.fare.clientFare.normalFare.fare != 0) {
          totalAllHoursNormal = totalAllHoursNormal +
              request.details.fare.clientFare.normalFare.hours;
        }
        if (request.details.fare.clientFare.holidayFare.fare != 0) {
          totalAllHoursHoliday = totalAllHoursHoliday +
              request.details.fare.clientFare.holidayFare.hours;
        }
        if (request.details.fare.clientFare.dynamicFare.fare != 0) {
          totalAllHoursDynamic = totalAllHoursDynamic +
              request.details.fare.clientFare.dynamicFare.hours;
        }
        totalAllClientPays = totalAllClientPays + totalClientPays;
        totalAllToPayEmployee = totalAllToPayEmployee + totalToPayEmployee;
      }

      PaymentResult paymentResult = PaymentResult(
        week: week,
        month: month,
        totalHours: totalAllHours,
        totalHoursNormal: totalAllHoursNormal,
        totalHoursHoliday: totalAllHoursHoliday,
        totalHoursDynamic: totalAllHoursDynamic,
        totalClientPays: totalAllClientPays,
        totalToPayEmployee: totalAllToPayEmployee,
        individualPayments: individualPayments,
        groupPayments: groupPayments,
        jobs: jobs,
      );
      return paymentResult;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      throw ServerException("$e");
    }
  }

  @override
  Future<PaymentResult?> getRangePaymentsByClient(
      {required String clientId,
      required DateTime startDate,
      required DateTime? endDate}) async {
    try {
      List<Payment> individualPayments = [];
      List<Payment> groupPayments = [];
      List<DateJob> jobs = [];

      double totalAllHours = 0;
      double totalAllHoursNormal = 0;
      double totalAllHoursHoliday = 0;
      double totalAllHoursDynamic = 0;
      double totalAllClientPays = 0;
      double totalAllToPayEmployee = 0;

      endDate ??=
          DateTime(startDate.year, startDate.month, startDate.day, 23, 59);

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseServices
          .db
          .collection('requests')
          .where("client_info.id", isEqualTo: clientId)
          .where("details.start_date", isGreaterThan: startDate)
          .where("details.start_date", isLessThanOrEqualTo: endDate)
          .get();

      List<Map<String, dynamic>> requiredJobs = [];

      for (DocumentSnapshot doc in querySnapshot.docs) {
        Map<dynamic, dynamic> requestData = doc.data() as Map;
        Request request = RequestModel.fromMap(requestData);

        bool requestWithValidStatus =
            request.details.status >= 1 && request.details.status <= 4;

        if (requestWithValidStatus) {
          double hoursWorked = request.details.totalHours;
          double totalClientPays = request.details.fare.totalClientPays;
          double totalToPayEmployee = request.details.fare.totalToPayEmployee;
          String jobType = request.details.job["value"];
          String namesEmployee =
              "${request.employeeInfo.names.trim()} ${request.employeeInfo.lastNames.trim()}";

          if (namesEmployee != " ") {
            individualPayments.add(PaymentModel.fromMap(requestData));
            DateJob? monthJobToFind =
                jobs.firstWhereOrNull((element) => element.jobType == jobType);
            var indexToFind =
                jobs.indexWhere((element) => element.jobType == jobType);

            if (monthJobToFind == null && indexToFind == -1) {
              DateJob newMonthJob =
                  DateJob(jobType: jobType, employeesList: [namesEmployee]);
              jobs.add(newMonthJob);
            }

            if (monthJobToFind != null) {
              String? employeeToFind = monthJobToFind.employeesList
                  .firstWhereOrNull((element) => element == namesEmployee);
              if (employeeToFind == null) {
                jobs[indexToFind].employeesList.add(namesEmployee);
              }
            }
          }

          int paymentIndex = groupPayments.indexWhere((element) =>
              element.requestInfo.employeeInfo.id == request.employeeInfo.id);

          if (paymentIndex == -1) {
            groupPayments.add(PaymentModel.fromMap(requestData));
          } else {
            groupPayments[paymentIndex].totalHours += hoursWorked;
            groupPayments[paymentIndex].totalHoursNormal +=
                request.details.fare.clientFare.normalFare.hours;

            groupPayments[paymentIndex].totalHoursHoliday +=
                request.details.fare.clientFare.holidayFare.hours;

            groupPayments[paymentIndex].totalHoursDynamic +=
                request.details.fare.clientFare.dynamicFare.hours;

            groupPayments[paymentIndex].totalClientPays += totalClientPays;

            groupPayments[paymentIndex].totalToPayEmployee +=
                totalToPayEmployee;
            groupPayments[paymentIndex]
                .employeeRequests
                .add(RequestModel.fromMap(requestData));
          }

          totalAllHours += hoursWorked;

          totalAllHoursNormal +=
              request.details.fare.clientFare.normalFare.hours;

          totalAllHoursHoliday +=
              request.details.fare.clientFare.holidayFare.hours;

          totalAllHoursDynamic +=
              request.details.fare.clientFare.dynamicFare.hours;

          totalAllClientPays += totalClientPays;
          totalAllToPayEmployee += totalToPayEmployee;

          if (request.employeeInfo.id.isNotEmpty) {
            int jobIndex = requiredJobs.indexWhere(
                (element) => element["job_key"] == request.details.job["key"]);

            if (jobIndex == -1) {
              requiredJobs.add({
                "job_key": request.details.job["key"],
                "job_name": request.details.job["name"],
                "employees_ids": [request.employeeInfo.id],
                "counter": 1,
              });
              continue;
            }
            if (!requiredJobs[jobIndex]["employees_ids"]
                .contains(request.employeeInfo.id)) {
              requiredJobs[jobIndex]["counter"] += 1;
            }
          }
        }
      }

      //return payments;
      PaymentResult paymentResult = PaymentResult(
        week: '',
        month: '',
        totalHours: totalAllHours,
        totalHoursNormal: totalAllHoursNormal,
        totalHoursHoliday: totalAllHoursHoliday,
        totalHoursDynamic: totalAllHoursDynamic,
        totalClientPays: totalAllClientPays,
        totalToPayEmployee: totalAllToPayEmployee,
        individualPayments: individualPayments,
        groupPayments: groupPayments,
        jobs: jobs,
      );

      BuildContext? context = NavigationService.getGlobalContext();

      if (context != null) {
        PaymentsProvider paymentsProvider = context.read<PaymentsProvider>();
        paymentsProvider.updateRequiredJobsByRange(requiredJobs);
      }

      return paymentResult;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> exportPaymentsToExcel(
      {required ExportPaymentsToExcelParams params,
      required bool forClient}) async {
    try {
      Map<String, dynamic> otherInfo = {
        "Total horas": params.totalHours,
        "Total horas - Regular": params.totalHoursNormal,
        "Total horas - Festivo": params.totalHoursHoliday,
        "Total horas - Dinámica": params.totalHoursDynamic,
        "Total a pagar": params.totalToPay,
      };

      List<Map<String, dynamic>> headersSheetEvent = [];
      List<Map<String, dynamic>> paymentsListEvent = [];
      if (forClient && params.isIndividual) {
        headersSheetEvent = _getExcelEventHeaders();
        paymentsListEvent =
            _getExcelPaymentsDataEvent(params.payments, params.isClient);
      }
      List<Map<String, dynamic>> headers =
          _getExcelHeaders(params.isIndividual);
      List<Map<String, dynamic>> paymentsList = _getExcelPaymentsData(
          params.isIndividual, params.payments, params.isClient);

      var url =
          Uri.parse('${config.urlFunctions}/${config.endpointExportToExcel}');

      http.Response res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            "headers": headers,
            "headers_for_client": headersSheetEvent,
            "data": paymentsList,
            "other_info": otherInfo,
            "file_name": forClient && params.isIndividual
                ? params.payments.first.requestInfo.clientInfo.name
                : "",
            "for_client": forClient && params.isIndividual,
            "data_event": paymentsListEvent
          },
        ),
      );

      if (res.statusCode == 500) {
        return false;
      } else if (res.statusCode == 200) {
        dynamic decodedResp = jsonDecode(res.body);
        log(decodedResp['report'].toString());

        downloadFile(
          List<int>.from(decodedResp['report']['data']),
          "${params.fileName}.xlsx",
        );
        return true;
      }

      return true;
    } catch (e) {
      log('Error GetPaymentsRemoteDatasourceImpl exportPaymentsToExcel $e');
      return false;
    }
  }

  @override
  void downloadFile(List<int> bytes, String fileName) {
    try {
      final String base64 = base64Encode(bytes);
      final AnchorElement anchorElement =
          AnchorElement(href: 'data:application/octet-stream;base64,$base64')
            ..target = "blank";

      anchorElement.download = fileName;
      document.body!.append(anchorElement);
      anchorElement.click();
      anchorElement.remove();
    } catch (e) {
      log('GetPaymentsRemoteDatasourceImpl, downloadFile error: $e');
    }
  }

  List<Map<String, dynamic>> _getExcelHeaders(bool isIndividual) {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return [];

    bool isAdmin =
        globalContext.read<AuthProvider>().webUser.accountInfo.type == 'admin';

    if (isIndividual) {
      headers.addAll([
        {
          "key": "job",
          "display_name": "Cargo",
          "width": 250,
        },
        {
          "key": "start_date",
          "display_name": "Fecha inicio",
          "width": 130,
        },
        {
          "key": "end_date",
          "display_name": "Fecha fin",
          "width": 130,
        },
        {
          'key': 'description',
          'display_name': 'Descripción',
          'width': 380,
        },
        {
          "key": "total_hours_normal",
          "display_name": "Total horas - Regular",
          "width": 150,
        },
        {
          "key": "fare_normal",
          "display_name": "Tarifa - Regular",
          "width": 130,
        },
        {
          "key": "total_hours_holiday",
          "display_name": "Total horas - Festivo",
          "width": 150,
        },
        {
          "key": "fare_holiday",
          "display_name": "Tarifa - Festivo",
          "width": 130,
        },
        {
          "key": "total_hours_dynamic",
          "display_name": "Total horas - Dinámica",
          "width": 150,
        },
        {
          "key": "fare_dynamic",
          "display_name": "Tarifa - Dinámica",
          "width": 130,
        },
        {
          "key": "total_hours",
          "display_name": "Total horas",
          "width": 90,
        },
        {
          "key": "total",
          "display_name": "Total sin recargo nocturno",
          "width": 190,
        },
        {
          "key": "total_night_surcharge",
          "display_name": "Recargo nocturno",
          "width": 140,
        },
        {
          "key": "total_to_pay",
          "display_name": "Total a pagar",
          "width": 110,
        },
      ]);
      return headers;
    }

    headers.addAll(
      [
        {
          "key": "jobs",
          "display_name": "Cargos",
          "width": 250,
        },
        {
          "key": "total_hours_normal",
          "display_name": "Total horas - Regular",
          "width": 150,
        },
        {
          "key": "total_hours_holiday",
          "display_name": "Total horas - Festivo",
          "width": 150,
        },
        {
          "key": "total_hours_dynamic",
          "display_name": "Total horas - Dinámica",
          "width": 150,
        },
        {
          "key": "total_hours",
          "display_name": "Total horas",
          "width": 90,
        },
        {
          "key": "total",
          "display_name": "Total sin recargo nocturno",
          "width": 190,
        },
        {
          "key": "total_night_surcharge",
          "display_name": "Recargo nocturno",
          "width": 140,
        },
        if (isAdmin)
          {
            "key": "advances",
            "display_name": "Anticipos",
            "width": 100,
          },
        if (isAdmin)
          {
            "key": "ccss",
            "display_name": "CCSS",
            "width": 100,
          },
        {
          "key": "total_to_pay",
          "display_name": "Total a pagar",
          "width": 110,
        },
      ],
    );

    return headers;
  }

  List<Map<String, dynamic>> _getExcelEventHeaders() {
    headers.addAll([
      {
        "key": "job",
        "display_name": "Cargo",
        "width": 250,
      },
      {
        "key": "start_date",
        "display_name": "Fecha inicio",
        "width": 130,
      },
      {
        "key": "end_date",
        "display_name": "Fecha fin",
        "width": 130,
      },
      {
        'key': 'description',
        'display_name': 'Descripción',
        'width': 380,
      },
      {
        "key": "total_hours_normal",
        "display_name": "Total horas - Regular",
        "width": 150,
      },
      {
        "key": "fare_normal",
        "display_name": "Tarifa - Regular",
        "width": 130,
      },
      {
        "key": "total_hours_holiday",
        "display_name": "Total horas - Festivo",
        "width": 150,
      },
      {
        "key": "fare_holiday",
        "display_name": "Tarifa - Festivo",
        "width": 130,
      },
      {
        "key": "total_hours_dynamic",
        "display_name": "Total horas - Dinámica",
        "width": 150,
      },
      {
        "key": "fare_dynamic",
        "display_name": "Tarifa - Dinámica",
        "width": 130,
      },
      {
        "key": "total_hours",
        "display_name": "Total horas",
        "width": 90,
      },
      {
        "key": "total",
        "display_name": "Total sin recargo nocturno",
        "width": 190,
      },
      {
        "key": "total_night_surcharge",
        "display_name": "Recargo nocturno",
        "width": 140,
      },
      {
        "key": "total_to_pay",
        "display_name": "Total a pagar",
        "width": 110,
      },
    ]);
    return headers;
  }

  List<Map<String, dynamic>> _getExcelPaymentsDataEvent(
      List<Payment> payments, bool isClient) {
    List<Map<String, dynamic>> paymentsData = [];
    payments.sort(
        (a, b) => a.requestInfo.eventName.compareTo(b.requestInfo.eventName));
    payments.sort((a, b) => a.requestInfo.details.startDate
        .compareTo(b.requestInfo.details.startDate));
    if (payments.every((element) =>
        element.requestInfo.details.fare.clientFare.normalFare.hours == 0)) {
      headers.removeWhere((element) => element['key'] == 'total_hours_normal');
      headers.removeWhere((element) => element['key'] == 'fare_normal');
    }
    if (payments.every((element) =>
        element.requestInfo.details.fare.clientFare.holidayFare.hours == 0)) {
      headers.removeWhere((element) => element['key'] == 'total_hours_holiday');
      headers.removeWhere((element) => element['key'] == 'fare_holiday');
    }
    if (payments.every((element) =>
        element.requestInfo.details.fare.clientFare.dynamicFare.hours == 0)) {
      headers.removeWhere((element) => element['key'] == 'total_hours_dynamic');
      headers.removeWhere((element) => element['key'] == 'fare_dynamic');
    }

    if (payments.every((element) =>
        element.requestInfo.details.fare.totalEmployeeNightSurcharge == 0)) {
      headers
          .removeWhere((element) => element['key'] == 'total_night_surcharge');
      headers.removeWhere((element) => element['key'] == 'total');
    }

    for (Payment payment in payments) {
      Map<String, dynamic> data = {};

      data = {
        "employee":
            "${payment.requestInfo.employeeInfo.names} ${payment.requestInfo.employeeInfo.lastNames}",
        'description': payment.requestInfo.eventName,
        "total_hours": payment.requestInfo.details.totalHours,
        "total_hours_normal":
            payment.requestInfo.details.fare.clientFare.normalFare.hours,
        "total_hours_holiday":
            payment.requestInfo.details.fare.clientFare.holidayFare.hours,
        "total_hours_dynamic":
            payment.requestInfo.details.fare.clientFare.dynamicFare.hours,
        "total_to_pay":
            isClient ? payment.totalClientPays : payment.totalToPayEmployee,
      };
      data["job"] = payment.requestInfo.details.job["name"];
      data["start_date"] =
          CodeUtils.formatDate(payment.requestInfo.details.startDate);
      data["end_date"] =
          CodeUtils.formatDate(payment.requestInfo.details.endDate);
      data["fare_normal"] = isClient
          ? payment.requestInfo.details.fare.clientFare.normalFare.fare
          : payment.requestInfo.details.fare.employeeFare.normalFare.fare;
      data["fare_holiday"] = isClient
          ? payment.requestInfo.details.fare.clientFare.holidayFare.fare
          : payment.requestInfo.details.fare.employeeFare.holidayFare.fare;
      data["fare_dynamic"] = isClient
          ? payment.requestInfo.details.fare.clientFare.dynamicFare.fare
          : payment.requestInfo.details.fare.employeeFare.dynamicFare.fare;
      data["total"] = isClient
          ? payment.requestInfo.details.fare.totalClientPays -
              payment.requestInfo.details.fare.totalClientNightSurcharge
          : payment.requestInfo.details.fare.totalToPayEmployee -
              payment.requestInfo.details.fare.totalEmployeeNightSurcharge;
      data['total_night_surcharge'] = isClient
          ? payment.requestInfo.details.fare.totalClientNightSurcharge
          : payment.requestInfo.details.fare.totalEmployeeNightSurcharge;

      paymentsData.add(data);
    }

    return paymentsData;
  }

  List<Map<String, dynamic>> _getExcelPaymentsData(
      bool isIndividual, List<Payment> payments, bool isClient) {
    List<Map<String, dynamic>> paymentsData = [];
    if (isIndividual) {
      for (Payment payment in payments) {
        payment.employeeRequests.sort((a, b) {
          String aName = a.details.job["name"].trim().toLowerCase();
          String bName = b.details.job["name"].trim().toLowerCase();
          return aName.compareTo(bName);
        });
      }

      payments.sort(
        (a, b) {
          String aName =
              a.employeeRequests[0].details.job["name"].trim().toLowerCase();
          String bName =
              b.employeeRequests[0].details.job["name"].trim().toLowerCase();
          int nameComparison = aName.compareTo(bName);

          if (nameComparison != 0) {
            // If first values are not equals, sort by job
            return nameComparison;
          } else {
            // If first values are equals, sort by total to pay
            return b.totalClientPays.compareTo(a.totalClientPays);
          }
        },
      );
    } else {
      payments.sort(
        (a, b) => a.requestInfo.employeeInfo.names
            .compareTo(b.requestInfo.employeeInfo.names),
      );
    }

    if (payments.every((element) =>
        element.requestInfo.details.fare.clientFare.normalFare.hours == 0)) {
      headers.removeWhere((element) => element['key'] == 'total_hours_normal');
      headers.removeWhere((element) => element['key'] == 'fare_normal');
    }
    if (payments.every((element) =>
        element.requestInfo.details.fare.clientFare.holidayFare.hours == 0)) {
      headers.removeWhere((element) => element['key'] == 'total_hours_holiday');
      headers.removeWhere((element) => element['key'] == 'fare_holiday');
    }
    if (payments.every((element) =>
        element.requestInfo.details.fare.clientFare.dynamicFare.hours == 0)) {
      headers.removeWhere((element) => element['key'] == 'total_hours_dynamic');
      headers.removeWhere((element) => element['key'] == 'fare_dynamic');
    }

    if (payments.every((element) =>
        element.requestInfo.details.fare.totalEmployeeNightSurcharge == 0)) {
      headers
          .removeWhere((element) => element['key'] == 'total_night_surcharge');
      headers.removeWhere((element) => element['key'] == 'total');
    }

    for (Payment payment in payments) {
      Map<String, dynamic> data = {};
      if (isIndividual) {
        data = {
          "employee":
              "${payment.requestInfo.employeeInfo.names} ${payment.requestInfo.employeeInfo.lastNames}",
          'description': payment.requestInfo.eventName,
          "total_hours": payment.requestInfo.details.totalHours,
          "total_hours_normal":
              payment.requestInfo.details.fare.clientFare.normalFare.hours,
          "total_hours_holiday":
              payment.requestInfo.details.fare.clientFare.holidayFare.hours,
          "total_hours_dynamic":
              payment.requestInfo.details.fare.clientFare.dynamicFare.hours,
          "total_to_pay":
              isClient ? payment.totalClientPays : payment.totalToPayEmployee,
        };
        data["job"] = payment.requestInfo.details.job["name"];
        data["start_date"] =
            CodeUtils.formatDate(payment.requestInfo.details.startDate);
        data["end_date"] =
            CodeUtils.formatDate(payment.requestInfo.details.endDate);
        data["fare_normal"] = isClient
            ? payment.requestInfo.details.fare.clientFare.normalFare.fare
            : payment.requestInfo.details.fare.employeeFare.normalFare.fare;
        data["fare_holiday"] = isClient
            ? payment.requestInfo.details.fare.clientFare.holidayFare.fare
            : payment.requestInfo.details.fare.employeeFare.holidayFare.fare;
        data["fare_dynamic"] = isClient
            ? payment.requestInfo.details.fare.clientFare.dynamicFare.fare
            : payment.requestInfo.details.fare.employeeFare.dynamicFare.fare;
        data["total"] = isClient
            ? payment.requestInfo.details.fare.totalClientPays -
                payment.requestInfo.details.fare.totalClientNightSurcharge
            : payment.requestInfo.details.fare.totalToPayEmployee -
                payment.requestInfo.details.fare.totalEmployeeNightSurcharge;
        data['total_night_surcharge'] = isClient
            ? payment.requestInfo.details.fare.totalClientNightSurcharge
            : payment.requestInfo.details.fare.totalEmployeeNightSurcharge;
      } else {
        // data = {
        //   "employee":
        //       "${payment.requestInfo.employeeInfo.names} ${payment.requestInfo.employeeInfo.lastNames}",
        //   'description': payment.requestInfo.eventName,
        //   "total_hours": payment.totalHours,
        //   "total_hours_normal": payment.totalHoursNormal,
        //   "total_hours_holiday": payment.totalHoursHoliday,
        //   "total_hours_dynamic": payment.totalHoursDynamic,
        //   'total': payment.totalHours,
        //   'total_night_surcharge': payment.totalHours,
        //   "total_to_pay":
        //       isClient ? payment.totalClientPays : payment.totalToPayEmployee,
        // };
        List<String> jobs = [];
        double totalNightSurcharge = 0;
        for (Request request in payment.employeeRequests) {
          totalNightSurcharge += isClient
              ? request.details.fare.totalClientNightSurcharge
              : request.details.fare.totalEmployeeNightSurcharge;
          if (jobs.contains(request.details.job["name"])) continue;
          jobs.add(request.details.job["name"]);
        }
        data = {
          "employee":
              "${payment.requestInfo.employeeInfo.names} ${payment.requestInfo.employeeInfo.lastNames}",
          "total_hours": payment.totalHours,
          "total_hours_normal": payment.totalHoursNormal,
          "total_hours_holiday": payment.totalHoursHoliday,
          "total_hours_dynamic": payment.totalHoursDynamic,
          'total': isClient
              ? payment.totalClientPays - totalNightSurcharge
              : payment.totalToPayEmployee - totalNightSurcharge,
          'total_night_surcharge': totalNightSurcharge,
          "total_to_pay":
              isClient ? payment.totalClientPays : payment.totalToPayEmployee,
        };
        data["jobs"] = jobs.join(", ");
      }

      paymentsData.add(data);
    }

    return paymentsData;
  }
}
