import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/features/activity/data/datasources/activity_remote_datasource.dart';
import 'package:huts_web/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:huts_web/features/activity/domain/entities/activity_report.dart';
import 'package:huts_web/features/activity/domain/use_cases/activity_crud.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';

class ActivityProvider with ChangeNotifier {
  List<ActivityReport> employeeActivity = [];
  List<ActivityReport> employeeFilteredActivity = [];

  List<ActivityReport> clientActivity = [];
  List<ActivityReport> clientFilteredActivity = [];

  List<ActivityReport> allActivity = [];
  List<ActivityReport> filteredAllActivity = [];

  ActivityRepositoryImpl repository =
      ActivityRepositoryImpl(datasource: ActivityRemoteDatasourceImpl());

  TextEditingController generalSearchController = TextEditingController();

  Future<void> getEmployeeActivity({
    required String id,
    required String category,
    bool fromStart = false,
  }) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    final resp = await ActivityCrud(repository: repository).getByEmployee(
      id: id,
      category: category,
    );
    resp.fold((Failure failure) {
      if (!fromStart) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al obtener la actividad",
          icon: Icons.error_outline,
        );
      }
    }, (List<ActivityReport> reports) {
      employeeActivity = [...reports];
      employeeFilteredActivity = [...employeeActivity];
      if (!fromStart) notifyListeners();
    });
  }

  Future<void> getClientActivity({
    required String id,
    required DateTime startDate,
    required DateTime endDate,
    bool fromStart = false,
  }) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    final resp = await ActivityCrud(repository: repository).getByClient(
      id: id,
      startDate: startDate,
      endDate: endDate,
    );
    resp.fold((Failure failure) {
      if (!fromStart) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al obtener la actividad",
          icon: Icons.error_outline,
        );
      }
    }, (List<ActivityReport> reports) {
      clientActivity = [...reports];
      clientFilteredActivity = [...clientActivity];
      if (!fromStart) notifyListeners();
    });
  }

  void filterEmployeeActivity(String query) {
    if (query.isEmpty) {
      employeeFilteredActivity = [...employeeActivity];
      notifyListeners();
      return;
    }
    employeeFilteredActivity.clear();

    for (ActivityReport report in employeeActivity) {
      if (report.description.toLowerCase().contains(query)) {
        employeeFilteredActivity.add(report);
        continue;
      }
      if (report.personInCharge["name"].toLowerCase().contains(query)) {
        employeeFilteredActivity.add(report);
        continue;
      }
      if (report.personInCharge["type_name"].toLowerCase().contains(query)) {
        employeeFilteredActivity.add(report);
        continue;
      }
      if (report.category["key"].toLowerCase().contains(query)) {
        employeeFilteredActivity.add(report);
        continue;
      }
    }
    notifyListeners();
  }

  void filterClientActivity(String query) {
    if (query.isEmpty) {
      clientFilteredActivity = [...clientActivity];
      notifyListeners();
      return;
    }

    query = query.toLowerCase().trim();

    clientFilteredActivity.clear();

    for (ActivityReport report in clientActivity) {
      if (report.description.toLowerCase().contains(query)) {
        clientFilteredActivity.add(report);
        continue;
      }
      if (report.personInCharge["name"].toLowerCase().contains(query)) {
        clientFilteredActivity.add(report);
        continue;
      }
      if (report.personInCharge["type_name"].toLowerCase().contains(query)) {
        clientFilteredActivity.add(report);
        continue;
      }
      if (report.category["key"].toLowerCase().contains(query)) {
        clientFilteredActivity.add(report);
        continue;
      }
    }
    notifyListeners();
  }

  void filterGeneralActivity(String query) {
    if (query.isEmpty) {
      filteredAllActivity = [...allActivity];
      notifyListeners();
      return;
    }
    filteredAllActivity.clear();

    query = query.toLowerCase().trim();

    for (ActivityReport report in allActivity) {
      if (report.description.toLowerCase().contains(query)) {
        filteredAllActivity.add(report);
        continue;
      }
      if (report.personInCharge["name"].toLowerCase().contains(query)) {
        filteredAllActivity.add(report);
        continue;
      }
      if (report.personInCharge["type_name"].toLowerCase().contains(query)) {
        filteredAllActivity.add(report);
        continue;
      }
      if (report.category["key"].toLowerCase().contains(query)) {
        filteredAllActivity.add(report);
        continue;
      }
    }

    notifyListeners();
  }

  Future<void> getGeneralActivity(
      DateTime startDate, DateTime endDate, WebUser webUser) async {
    bool isAdmin = webUser.accountInfo.type == "admin";

    final resp = isAdmin
        ? await ActivityCrud(repository: repository)
            .getGeneral(startDate: startDate, endDate: endDate)
        : await ActivityCrud(repository: repository).getByClient(
            id: webUser.company.id,
            startDate: startDate,
            endDate: endDate,
          );

    resp.fold((Failure failure) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al obtener la actividad",
        icon: Icons.error_outline,
      );
    }, (List<ActivityReport> reports) {
      reports.sort((a, b) => b.date.compareTo(a.date));
      allActivity = [...reports];
      filteredAllActivity = [...allActivity];
    });

    notifyListeners();
  }
}
