// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/activity_service.dart';
import 'package:huts_web/core/use_cases_params/activity_params.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/employees/data/models/employee_model.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/requests/data/models/request_model.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/employee_services/docs_services.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../general_info/display/providers/general_info_provider.dart';
import '../../../general_info/domain/entities/country_info_entity.dart';
import '../../domain/entities/available_day.dart';
import '../../domain/entities/employee_entity.dart';
import '../models/available_day_model.dart';

abstract class EmoployeesRemoteDataSourse {
  Future<bool> updateDayAvailibity(
      AvailableDay avaliableDayEntity, Employee employee);
  Future<bool> updateEmployees(
    String idEmployee,
    Map<String, dynamic> data,
  );
  Future<void> listenEmployees(EmployeesProvider provider);
  Future<void> listenDetailsEmployee(
      String idEmployee, EmployeesProvider provider);
  Future<List<Map<String, dynamic>>> getEmployeesPayments(
      DateTime startDate, DateTime endDate, String type);
}

class EmoployeesRemoteDataSourseImpl implements EmoployeesRemoteDataSourse {
  @override
  Future<void> listenDetailsEmployee(
      String idEmployee, EmployeesProvider provider) async {
    try {
      await provider.detailsEmployeeStream?.cancel();
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) {
        throw const ServerException("El contexto es nulo");
      }
      provider.detailsEmployeeStream = FirebaseServices.db
          .collection("employees")
          .where("uid", isEqualTo: idEmployee)
          .snapshots()
          .listen(
        (QuerySnapshot querySnapshot) async {
          late Employee employee;
          late EmployeeModel newEmployee;

          CountryInfo? countryInfo;

          countryInfo =
              Provider.of<GeneralInfoProvider>(globalContext, listen: false)
                  .generalInfo
                  .countryInfo;

          for (DocumentSnapshot doc in querySnapshot.docs) {
            newEmployee =
                EmployeeModel.fromMap(doc.data() as Map<String, dynamic>);
            newEmployee.docsStatus =
                DocsServices.getStatus(newEmployee, countryInfo);
          }
          employee = newEmployee;
          provider.showEmployeeDetails(employee: employee);
          employee;
        },
      );

      int index = FirebaseServices.streamSubscriptions.indexWhere(
          (addedStream) => addedStream.id == "listen_details_employee");

      if (index != -1) {
        await FirebaseServices.streamSubscriptions[index].streamSubscription
            ?.cancel();
        FirebaseServices.streamSubscriptions.removeAt(index);
      }
      EmployeesProvider employeesProvider =
          Provider.of<EmployeesProvider>(globalContext, listen: false);
      FirebaseServices.streamSubscriptions.add(
        FirestoreStream(
          id: "listen_details_employee",
          streamSubscription: employeesProvider.employeesStream,
        ),
      );
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<void> listenEmployees(EmployeesProvider provider) async {
    try {
      await provider.employeesStream?.cancel();
      provider.updateEmployee([]);
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) {
        throw const ServerException("El contexto es nulo");
      }

      provider.employeesStream = FirebaseServices.db
          .collection("employees")
          .where("account_info.status", isGreaterThan: 0)
          .snapshots()
          .listen(
        (QuerySnapshot querySnapshot) async {
          List<Employee> employees = [];

          CountryInfo? countryInfo;

          countryInfo =
              Provider.of<GeneralInfoProvider>(globalContext, listen: false)
                  .generalInfo
                  .countryInfo;

          for (DocumentSnapshot doc in querySnapshot.docs) {
            EmployeeModel employee =
                EmployeeModel.fromMap(doc.data() as Map<String, dynamic>);
            employee.docsStatus = DocsServices.getStatus(employee, countryInfo);
            employees.add(employee);
          }

          provider.updateEmployee(employees);
          // Provider.of<EmployeesProvider>(globalContext, listen: false)
          //     .updateEmployee(employees);
        },
      );

      int index = FirebaseServices.streamSubscriptions
          .indexWhere((addedStream) => addedStream.id == "listen_employees");

      if (index != -1) {
        await FirebaseServices.streamSubscriptions[index].streamSubscription
            ?.cancel();
        FirebaseServices.streamSubscriptions.removeAt(index);
      }
      // EmployeesProvider employeesProvider =
      //     Provider.of<EmployeesProvider>(globalContext, listen: false);
      FirebaseServices.streamSubscriptions.add(
        FirestoreStream(
          id: "listen_employees",
          streamSubscription: provider.employeesStream,
        ),
      );
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEmployeesPayments(
      DateTime startDate, DateTime endDate, String type) async {
    try {
      EmployeesProvider employeesProvider =
          Provider.of(NavigationService.getGlobalContext()!, listen: false);

      employeesProvider.paymentsMonths.clear();
      employeesProvider.paymentsYears.clear();

      Map<String, dynamic> employeesMap = {};

      QuerySnapshot query = await FirebaseServices.db
          .collection("requests")
          .where("details.start_date", isGreaterThanOrEqualTo: startDate)
          .where("details.start_date", isLessThanOrEqualTo: endDate)
          .get();

      for (DocumentSnapshot requestDoc in query.docs) {
        Request request =
            RequestModel.fromMap(requestDoc.data() as Map<String, dynamic>);

        String employeeId = request.employeeInfo.id;
        int status = request.details.status;
        if (status >= 1 && status <= 4) {
          //If the employee is already added
          if (employeesMap.containsKey(employeeId)) {
            employeesMap[employeeId]["requests"].add(request);
            employeesMap[employeeId]["total_hours"] +=
                request.details.totalHours;
            employeesMap[employeeId]["total_to_pay"] +=
                request.details.fare.totalToPayEmployee;

            //If payment values have to be shown by months ranges
            if (type == "months") {
              int monthNumber = request.details.startDate.month;
              if (employeesMap[employeeId]["range_requests"]
                  .containsKey("$monthNumber")) {
                employeesMap[employeeId]["range_requests"]["$monthNumber"]
                        ["requests"]
                    .add(request);

                employeesMap[employeeId]["range_requests"]["$monthNumber"]
                    ["total_hours"] += request.details.totalHours;

                employeesMap[employeeId]["range_requests"]["$monthNumber"]
                    ["total_to_pay"] += request.details.fare.totalToPayEmployee;
              } else {
                employeesMap[employeeId]["range_requests"]["$monthNumber"] = {
                  "requests": List<Request>.from([request]),
                  "total_hours": request.details.totalHours,
                  "total_to_pay": request.details.fare.totalToPayEmployee,
                };
              }
              continue;
            }

            if (type == "years") {
              int yearNumber = request.details.startDate.year;
              if (employeesMap[employeeId]["range_requests"]
                  .containsKey("$yearNumber")) {
                employeesMap[employeeId]["range_requests"]["$yearNumber"]
                        ["requests"]
                    .add(request);

                employeesMap[employeeId]["range_requests"]["$yearNumber"]
                    ["total_hours"] += request.details.totalHours;

                employeesMap[employeeId]["range_requests"]["$yearNumber"]
                    ["total_to_pay"] += request.details.fare.totalToPayEmployee;
              } else {
                employeesMap[employeeId]["range_requests"]["$yearNumber"] = {
                  "requests": List<Request>.from([request]),
                  "total_hours": request.details.totalHours,
                  "total_to_pay": request.details.fare.totalToPayEmployee,
                };
              }
              continue;
            }
          } else {
            String firstRangeItemKey = type == "years"
                ? request.details.startDate.year.toString()
                : type == "months"
                    ? request.details.startDate.month.toString()
                    : request.details.startDate.day.toString();

            employeesMap[request.employeeInfo.id] = {
              "type": type,
              "requests": List<Request>.from([request]),
              "total_hours": request.details.totalHours,
              "total_to_pay": request.details.fare.totalToPayEmployee,
              "employee_info": {
                "id": request.employeeInfo.id,
                "fullname": CodeUtils.getFormatedName(
                  request.employeeInfo.names,
                  request.employeeInfo.lastNames,
                ),
                "image": request.employeeInfo.imageUrl,
                "phone": request.employeeInfo.phone,
              },
              "range_requests": {
                firstRangeItemKey: {
                  "requests": List<Request>.from([request]),
                  "total_hours": request.details.totalHours,
                  "total_to_pay": request.details.fare.totalToPayEmployee,
                },
              },
            };
          }

          if (type == "months") {
            if (!employeesProvider.paymentsMonths
                .contains(request.details.startDate.month)) {
              employeesProvider.paymentsMonths
                  .add(request.details.startDate.month);
            }
          } else if (type == "years") {
            if (!employeesProvider.paymentsYears
                .contains(request.details.startDate.year)) {
              employeesProvider.paymentsYears
                  .add(request.details.startDate.year);
            }
          }
        }
      }
      return employeesMap.values
          .map((data) => Map<String, dynamic>.from(data))
          .toList();
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> updateDayAvailibity(
      AvailableDay avaliableDayEntity, Employee employee) async {
    try {
      String dayToUpdate = 'availability.${avaliableDayEntity.id}';

      await FirebaseServices.db.collection('employees').doc(employee.id).update(
        {
          dayToUpdate: AvailabilityDayModel.toMap(avaliableDayEntity),
        },
      );

      String employeeName = CodeUtils.getFormatedName(
          employee.profileInfo.names, employee.profileInfo.lastNames);

      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser admin = context.read<AuthProvider>().webUser;

      ActivityParams params = ActivityParams(
        description:
            "Se modificó la disponibilidad de $employeeName del ${avaliableDayEntity.name}",
        category: {
          "key": "availability",
          "name": "Disponibilidad",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              admin.profileInfo.names, admin.profileInfo.lastNames),
          "type_key": "admin",
          "type_name": "Administrador",
          "id": admin.uid,
          "company_id": admin.accountInfo.companyId
        },
        affectedUser: {
          "id": employee.id,
          "name": employeeName,
          "type_key": "employee",
          "type_name": "Colaborador"
        },
        date: DateTime.now(),
      );

      await ActivityService.saveChange(params);

      return true;
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        print('$error');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print("EmoployeesRemoteDataSourse, updateDayAvailibity error: $e");
      }
      return false;
    }
  }

  @override
  Future<bool> updateEmployees(
      String idEmployee, Map<String, dynamic> data) async {
    try {
      await FirebaseServices.db
          .collection('employees')
          .doc(idEmployee)
          .update(data);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("EmoployeesRemoteDataSourse, updateEmployees error: $e");
      }
      return false;
    }
  }
}
