// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/activity_service.dart';
import 'package:huts_web/core/services/employee_services/docs_services.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/use_cases_params/activity_params.dart';
import 'package:huts_web/features/employees/data/models/employee_model.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/general_info/domain/entities/country_info_entity.dart';
import 'package:huts_web/features/pre_registered/display/provider/pre_registered_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/code/code_utils.dart';
import '../../../auth/display/providers/auth_provider.dart';
import '../../../auth/domain/entities/web_user_entity.dart';

abstract class PreRegisteredRemoteDatasource {
  Future<void> listenPreRegistered(DateTime start, DateTime end);
  Future<bool> approveEmployee(String employeeID, String employeeName);
}

class PreRegisteredRemoteDatasourceImpl
    implements PreRegisteredRemoteDatasource {
  @override
  Future<void> listenPreRegistered(
    DateTime start,
    DateTime end,
  ) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) {
        throw const ServerException("El contexto es nulo");
      }
      FirebaseServices.db
          .collection("employees")
          .where("account_info.status", isEqualTo: 0)
          .where("account_info.register_date", isGreaterThanOrEqualTo: start)
          .where("account_info.register_date", isLessThanOrEqualTo: end)
          .snapshots()
          .listen(
        (QuerySnapshot querySnapshot) async {
          List<EmployeeModel> employeesResult = [];

          CountryInfo? countryInfo;

          countryInfo =
              Provider.of<GeneralInfoProvider>(globalContext, listen: false)
                  .generalInfo
                  .countryInfo;

          for (DocumentSnapshot employeeDoc in querySnapshot.docs) {
            EmployeeModel employee = EmployeeModel.fromMap(
              employeeDoc.data() as Map<String, dynamic>,
            );

            employee.docsStatus = DocsServices.getStatus(employee, countryInfo);

            employeesResult.add(employee);
          }

          Provider.of<PreRegisteredProvider>(globalContext, listen: false)
              .updatePreEmployee(employeesResult);

          employeesResult;
        },
      );

      int index = FirebaseServices.streamSubscriptions.indexWhere(
          (addedStream) => addedStream.id == "listen_pre_registered");

      if (index != -1) {
        await FirebaseServices.streamSubscriptions[index].streamSubscription
            ?.cancel();
        FirebaseServices.streamSubscriptions.removeAt(index);
      }
      PreRegisteredProvider preRegisteredProvider =
          Provider.of<PreRegisteredProvider>(globalContext, listen: false);
      FirebaseServices.streamSubscriptions.add(
        FirestoreStream(
          id: "listen_pre_registered",
          streamSubscription: preRegisteredProvider.requestsStream,
        ),
      );
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> approveEmployee(String employeeID, String employeeName) async {
    try {
      await FirebaseServices.db
          .collection("employees")
          .doc(employeeID)
          .update({"account_info.status": 1});

      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser admin = Provider.of<AuthProvider>(context, listen: false).webUser;

      ActivityParams params = ActivityParams(
        description: "Se aprobó el colaborador $employeeName",
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
          "id": employeeID,
          "name": employeeName,
          "type_key": "employee",
          "type_name": "Colaborador"
        },
        date: DateTime.now(),
      );

      await ActivityService.saveChange(params);

      return true;
    } catch (e) {
      return false;
    }
  }
}
