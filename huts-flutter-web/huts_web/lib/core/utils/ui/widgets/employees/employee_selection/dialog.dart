import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/employees/employee_selection/dialog_content.dart';

import '../../../../../../features/employees/domain/entities/employee_entity.dart';
import '../../../../../services/navigation_service.dart';

class EmployeeSelectionDialog {
  static Future<List<Employee?>> show({
    required List<Employee> employees,
    List<int>? indexesList,
    bool isAddFavOrLocks = false,
  }) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) return [];
      List<Employee> selectedEmployees = await _buildDialog(
        globalContext,
        employees,
        indexesList!,
        isAddFavOrLocks,
      );

      return selectedEmployees;
    } catch (e) {
      if (kDebugMode) print("EmployeeSelectionDialog, show error: $e");
      return [];
    }
  }

  static Future<List<Employee>> _buildDialog(
      BuildContext context,
      List<Employee> employees,
      List<int> indexesList,
      bool isAddFavOrLocks) async {
    return showDialog(
      context: context,
      builder: (_) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: const EdgeInsets.all(0),
            title: DialogContent(
              employees: employees,
              indexesList: indexesList,
              isAddFavOrLocks: isAddFavOrLocks,
            ),
          ),
        );
      },
    ).then((value) => value);
  }
}
