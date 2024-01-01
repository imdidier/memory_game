// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:huts_web/features/employees/data/models/employee_change_model.dart';
import 'package:huts_web/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';
import 'package:huts_web/features/employees/domain/use_cases/employees_crud.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/available_day_model.dart';
import '../../data/repositories/update_availability_repository_impl.dart';
import '../../domain/entities/available_day.dart';
import '../../domain/use_cases/update_availability.dart';

class EmployeesProvider with ChangeNotifier {
  List<Employee> employees = [];
  List<Employee> filteredEmployees = [];
  List<EmployeeChange> filteredPerJobEmployees = [];

  Employee? selectedEmployee;
  int indexSelectEmployee = -1;

  List<Map<String, dynamic>> employeesPayments = [];
  List<Map<String, dynamic>> filteredEmployeesPayments = [];

  List<int> paymentsMonths = [];
  List<int> paymentsYears = [];

  List<String> employeesPaymentsHeaders = [];
  StreamSubscription? employeesStream;
  StreamSubscription? detailsEmployeeStream;

  bool isUpdating = false;
  List<AvailableDay> availabilityDays = [];
  List<int> locksOrFavsToEditIndexes = [];

  TextEditingController searchController = TextEditingController();

  setInitialDaysValues() {
    availabilityDays = [];
    selectedEmployee!.availability.forEach((key, value) {
      value["id"] = key;
      availabilityDays.add(AvailabilityDayModel.fromMap(value));
    });
  }

  void updateLocksOrFavsToEditIndexes(List<int> newIndexes) {
    locksOrFavsToEditIndexes = [...newIndexes];
    notifyListeners();
  }

  void setDynamicHeaders(String type) {
    employeesPaymentsHeaders = [
      "Imagen",
      "Id",
      "Nombre",
      "Teléfono",
    ];

    if (type == "months") {
      List<String> months = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];

      for (int item in paymentsMonths) {
        employeesPaymentsHeaders.add(months[item - 1]);
      }
    }

    if (type == "years") {
      employeesPaymentsHeaders.addAll(
        paymentsYears.map((e) => "$e").toList(),
      );
    }

    employeesPaymentsHeaders.add("Total horas");
    employeesPaymentsHeaders.add("Total pagar");
    employeesPaymentsHeaders.add("Acciones");

    //print(employeesPaymentsHeaders.length);
  }

  Future<void> getEmployees(EmployeesProvider provider) async {
    EmployeesRepositoryImpl repository = EmployeesRepositoryImpl(
      EmoployeesRemoteDataSourseImpl(),
    );

    EmployeesCrud(repository).getEmployees(provider);

    (List<Employee> employeesResp) {
      employees = [...employeesResp];
      filteredEmployees = [...employeesResp];

      notifyListeners();
    };
  }

  Future<bool> updateEmployees({
    required String idEmployee,
    required Map<String, dynamic> data,
  }) async {
    EmployeesRepositoryImpl repository = EmployeesRepositoryImpl(
      EmoployeesRemoteDataSourseImpl(),
    );

    bool resp =
        await EmployeesCrud(repository).updateEmployees(idEmployee, data);

    if (resp) {
      showEmployeeDetails(employee: selectedEmployee!);
      LocalNotificationService.showSnackBar(
        type: 'success',
        message: 'Se ha actualizado la información del colaborador',
        icon: Icons.check,
        duration: 2,
      );
    } else {
      showEmployeeDetails(employee: selectedEmployee!);
      LocalNotificationService.showSnackBar(
        type: 'fail',
        message: 'No se pudo actualizar la información del colaborador',
        icon: Icons.warning,
        duration: 2,
      );
    }
    notifyListeners();
    return resp;
  }

  Future<void> updateDayValue({
    required bool newValue,
    required int dayIndex,
    required int shift,
    required BuildContext context,
    required Employee employee,
  }) async {
    isUpdating = true;
    await Future.delayed(const Duration(milliseconds: 700));
    switch (shift) {
      case 0:
        availabilityDays[dayIndex].morningShiftEnabled = newValue;
        break;
      case 1:
        availabilityDays[dayIndex].afternoonShiftEnabled = newValue;
        break;
      case 2:
        availabilityDays[dayIndex].nightShiftEnabled = newValue;
        break;
    }

    UpdateAvailabilityRepositoryImpl repositoryImpl =
        UpdateAvailabilityRepositoryImpl(EmoployeesRemoteDataSourseImpl());
    bool isSuccesUpdate = await UpdateDayAvailabilty(repositoryImpl)
        .call(availabilityDays[dayIndex], employee);
    if (!isSuccesUpdate) {
      UiMethods().hideLoadingDialog(context: context);
      LocalNotificationService.showSnackBar(
        type: 'fail',
        message: 'Ocurrió un error al actualizar la disponibilidad',
        icon: Icons.warning_rounded,
        duration: 4,
      );

      switch (shift) {
        case 0:
          availabilityDays[dayIndex].morningShiftEnabled = !newValue;
          break;
        case 1:
          availabilityDays[dayIndex].afternoonShiftEnabled = !newValue;
          break;
        case 2:
          availabilityDays[dayIndex].nightShiftEnabled = !newValue;
          break;
      }
    } else {
      UiMethods().hideLoadingDialog(context: context);
      LocalNotificationService.showSnackBar(
        type: 'success',
        message: 'Se actualizó la disponibilidad correctamente',
        icon: Icons.check,
        duration: 4,
      );
    }

    isUpdating = false;
    notifyListeners();
  }

  Future<void> getDetailsEmployee(
      String idEmployee, BuildContext context) async {
    EmployeesRepositoryImpl repository = EmployeesRepositoryImpl(
      EmoployeesRemoteDataSourseImpl(),
    );
    EmployeesProvider provider = Provider.of<EmployeesProvider>(
      context,
      listen: false,
    );

    EmployeesCrud(repository).getDetailsEmployee(idEmployee, provider);

    (List<Employee> employeesResp) {
      employees = [...employeesResp];
      filteredEmployees = [...employeesResp];

      notifyListeners();
    };
  }

  void updateEmployee(List<Employee> newEmployee) {
    employees = [...newEmployee];
    filteredEmployees = [...employees];
    updateFilteredEmployeesByStatus(0, notify: false);

    if (searchController.text.isNotEmpty) {
      filterEmployees(searchController.text);
      return;
    }

    notifyListeners();
  }

  int selectedEmployeesTabStatus = 0;
  bool isFilteringEmployees = false;

  Future<void> filterEmployees(String query) async {
    try {
      if (isFilteringEmployees) return;

      isFilteringEmployees = true;

      // await Future.delayed(const Duration(milliseconds: 300));

      List<Employee> filteredEmployeesCopy = [];
      if (selectedEmployeesTabStatus == 0) {
        filteredEmployeesCopy = [
          ...employees.where(
            (element) => element.accountInfo.status > 0,
          )
        ];
      } else {
        filteredEmployeesCopy = [
          ...employees.where(
            (element) =>
                element.accountInfo.status == selectedEmployeesTabStatus,
          )
        ];
      }

      filteredEmployees.clear();
      query = query.toLowerCase();
      currentEmployeesTextFieldValue = query;
      if (query.isEmpty) {
        filteredEmployees = [...filteredEmployeesCopy];
      } else {
        for (Employee employee in filteredEmployeesCopy) {
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
      }
      isFilteringEmployees = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("EmployeesProvider, filterEmployees error: $e");
      }
    }
  }

  void filterPerJobEmployees(
    String query,
    List<EmployeeChange> listEmployees,
  ) {
    query = query.toLowerCase();
    filteredPerJobEmployees.clear();

    if (query.isEmpty) {
      filteredPerJobEmployees = [...listEmployees];
    } else {
      for (EmployeeChange employee in listEmployees) {
        String name = CodeUtils.getFormatedName(
          employee.names,
          employee.lastNames,
        );

        if (name.toLowerCase().contains(query)) {
          filteredPerJobEmployees.add(employee);
          continue;
        }
      }
    }
    notifyListeners();
  }

  void filterEmployeesPayments(String query) {
    filteredEmployeesPayments.clear();

    query = query.toLowerCase();

    for (Map<String, dynamic> payment in employeesPayments) {
      if (payment["employee_info"]["id"].toLowerCase().contains(query)) {
        filteredEmployeesPayments.add(payment);
        continue;
      }

      if (payment["employee_info"]["fullname"].toLowerCase().contains(query)) {
        filteredEmployeesPayments.add(payment);
        continue;
      }

      if (payment["employee_info"]["phone"].toLowerCase().contains(query)) {
        filteredEmployeesPayments.add(payment);
        continue;
      }
    }

    notifyListeners();
  }

  void showEmployeeDetails({required Employee employee}) {
    selectedEmployee = employee;
    //notifyListeners();
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

  onEmployeeSelection(int index, bool newValue) {
    filteredPerJobEmployees[index].isSelected = newValue;
    int generalIndex = filteredPerJobEmployees.indexWhere(
        (EmployeeChange item) => item.id == filteredPerJobEmployees[index].id);
    if (generalIndex != indexSelectEmployee && indexSelectEmployee != -1) {
      filteredPerJobEmployees[indexSelectEmployee].isSelected = false;
    }
    if (generalIndex != -1) {
      indexSelectEmployee = generalIndex;
      filteredPerJobEmployees[generalIndex].isSelected = newValue;
    }
    notifyListeners();
  }

  void updateLocalEmployeeData(Employee newEmployee) {
    int index =
        filteredEmployees.indexWhere((element) => element.id == newEmployee.id);
    if (index == -1) return;
    filteredEmployees[index] = newEmployee;
    notifyListeners();
  }

  void updateLocalEmployeesList(
      {int? index, Employee? employee, required bool isDelete}) {
    (isDelete)
        ? filteredEmployees.removeAt(index!)
        : filteredEmployees.add(employee!);
    notifyListeners();
  }

  Future<void> getPayments(
    DateTime? start,
    DateTime? end,
  ) async {
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

    employeesPayments.clear();

    EmployeesRepositoryImpl repository = EmployeesRepositoryImpl(
      EmoployeesRemoteDataSourseImpl(),
    );

    String type = "days";

    if (end.difference(start).inDays > 31 &&
        end.difference(start).inDays <= 365) type = "months";

    if (end.difference(start).inDays > 365) type = "years";

    Either<Failure, List<Map<String, dynamic>>> resp =
        await EmployeesCrud(repository).getEmployeesPayments(start, end, type);

    resp.fold((Failure serverFailure) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: serverFailure.errorMessage!,
        icon: Icons.error_outline,
      );
    }, (List<Map<String, dynamic>> list) {
      employeesPayments = [...list];
      filteredEmployeesPayments = [...employeesPayments];

      setDynamicHeaders(
        (filteredEmployeesPayments.isEmpty)
            ? "days"
            : filteredEmployeesPayments[0]["type"],
      );

      notifyListeners();
    });
  }

  void updateFilteredEmployeesByStatus(int status, {bool notify = true}) {
    if (status == 0) {
      filteredEmployees = [
        ...employees.where(
          (element) => element.accountInfo.status > 0,
        )
      ];
    } else {
      filteredEmployees = [
        ...employees.where(
          (element) => element.accountInfo.status == status,
        )
      ];
    }

    if (notify) notifyListeners();
  }

  String currentEmployeesTextFieldValue = "";
}
