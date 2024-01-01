// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/pre_registered/data/datasources/pre_registered_remote_datasource.dart';
import 'package:huts_web/features/pre_registered/data/repositories/pre_registered_repository_impl.dart';
import 'package:huts_web/features/pre_registered/domain/use_cases/pre_registered_crud.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/code/code_utils.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/domain/entities/employee_entity.dart';

class PreRegisteredProvider with ChangeNotifier {
  PreRegisteredRepositoryImpl repository = PreRegisteredRepositoryImpl(
    PreRegisteredRemoteDatasourceImpl(),
  );
  Employee? selectedEmployee;
  List<Employee> employees = [];
  List<Employee> filteredEmployees = [];
  StreamSubscription? requestsStream;
  TextEditingController searchController = TextEditingController();

  Future<void> listenEmployees(DateTime? start, DateTime? end) async {
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

    final resp =
        PreRegisteredCrud(repository).listenPreRegisteredEmployees(start, end);

    (List<Employee> gottenEmployees) {
      employees = [...gottenEmployees];
      filteredEmployees = [...employees];
      notifyListeners();
    };
  }

  void updatePreEmployee(List<EmployeeModel> newEmployees) {
    employees = [...newEmployees];
    filteredEmployees = [...employees];
    if (searchController.text.isNotEmpty) {
      filterEmployees(searchController.text);
      return;
    }

    notifyListeners();
  }

  void filterEmployees(String query) {
    filteredEmployees.clear();

    query = query.toLowerCase();

    for (Employee employee in employees) {
      String status =
          CodeUtils.getEmployeeStatusName(employee.accountInfo.status);

      EmployeeProfileInfo profileInfo = employee.profileInfo;

      String name = CodeUtils.getFormatedName(
        profileInfo.names,
        profileInfo.lastNames,
      );

      String jobs = UiMethods.getJobsNamesBykeys(employee.jobs);

      if (name.toLowerCase().contains(query)) {
        filteredEmployees.add(employee);
        continue;
      }

      if (profileInfo.docNumber.toLowerCase().contains(query)) {
        filteredEmployees.add(employee);
        continue;
      }

      if (profileInfo.phone.toLowerCase().contains(query)) {
        filteredEmployees.add(employee);
        continue;
      }
      if (jobs.toLowerCase().contains(query)) {
        filteredEmployees.add(employee);
        continue;
      }

      if (status.toLowerCase().contains(query)) {
        filteredEmployees.add(employee);
        continue;
      }
    }
    notifyListeners();
  }

  void showEmployeeDetails({required Employee employee}) {
    selectedEmployee = employee;
    notifyListeners();
  }

  void unselectEmployee() {
    selectedEmployee = null;
    notifyListeners();
  }

  void updateSelectedEmployee(String type, Map<String, dynamic> data) {
    switch (type) {
      case "jobs":
        if (data["to_enable"]) {
          selectedEmployee!.jobs.add(data["job"]);
          notifyListeners();
          return;
        }
        selectedEmployee!.jobs.removeWhere((element) => element == data["job"]);
        notifyListeners();
        break;
      default:
    }
  }

  Future<void> approveEmployee(
      String employeeId, String employeeName, BuildContext context) async {
    try {
      bool resp = await PreRegisteredCrud(repository)
          .approveEmployee(employeeId, employeeName);

      if (!resp) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al aprobar el colaborador",
          icon: Icons.error_outline,
        );
        return;
      }

      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Colaborador aprobado correctamente",
        icon: Icons.check_outlined,
      );

      int index =
          filteredEmployees.indexWhere((element) => element.id == employeeId);

      if (index == -1) return;

      filteredEmployees[index].accountInfo.status = 1;
      Provider.of<EmployeesProvider>(context, listen: false)
          .filteredEmployees
          .add(filteredEmployees[index]);
      filteredEmployees.removeWhere((item) => item.id == employeeId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("PreRegisteredProvider, approveEmployee error: $e");
      }
    }
  }
}
