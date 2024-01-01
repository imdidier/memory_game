// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/admins/data/repositories/admins_actions_repository_impl.dart';
import 'package:huts_web/features/admins/domain/use_cases/admins_actions.dart';
import 'package:huts_web/features/auth/data/models/web_user_model.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import '../../data/datasources/admins_remote_datasource.dart';
import '../../data/repositories/get_admins_repository_impl.dart';
import '../../domain/use_cases/get_admins.dart';

class AdminProvider with ChangeNotifier {
  int adminsPerPage = 10;
  List<WebUser> allAdmins = [];
  List<WebUser> allCompanies = [];
  int currentPage = 0;
  List<WebUser> filteredAdmins = [];
  List<WebUser> filteredCompanies = [];
  TextEditingController nameController = TextEditingController();
  TextEditingController lastNamesController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  DateTime? birthdayAdmin;
  String? adminSubtype;
  StreamSubscription? requestsStream;

  AdminsActionsRepositoryImpl actionsRepository =
      AdminsActionsRepositoryImpl(AdminsRemoteDataSourceImpl());

  TextEditingController searchController = TextEditingController();

  Future<void> eitherFailOrGetAdmins(String uid) async {
    allAdmins.clear();
    GetAdminsRepositoryImpl repository =
        GetAdminsRepositoryImpl(AdminsRemoteDataSourceImpl());

    GetAdmins(repository).getAdmins(uid);
  }

  void updateAdmin(List<WebUser> newAdmin) {
    allAdmins = newAdmin;
    filteredAdmins = [...allAdmins];

    if (searchController.text.isNotEmpty) {
      filterAdmins(searchController.text);
      return;
    }
    notifyListeners();
  }

  void updateCompanies(List<WebUser> newCompany) {
    allCompanies = newCompany;
    filteredCompanies = [...allCompanies];
    notifyListeners();
  }

  Future<void> eitherFailOrGetCompanies(String uid) async {
    allCompanies.clear();
    GetAdminsRepositoryImpl repository =
        GetAdminsRepositoryImpl(AdminsRemoteDataSourceImpl());

    GetAdmins(repository).getCompanies(uid);
    (List<WebUser>? allCompaniesResult) async {
      if (allCompaniesResult == null) return;
      allCompanies = allCompaniesResult;
      filteredCompanies = [...allCompanies];
      notifyListeners();
    };
  }

  void filterAdmins(String query) {
    filteredAdmins.clear();
    for (WebUser admin in allAdmins) {
      String status =
          admin.accountInfo.enabled ? "Habilitado" : "Deshabilitado";

      if (admin.profileInfo.email.contains(query)) {
        filteredAdmins.add(admin);
        continue;
      }
      if (admin.profileInfo.names.contains(query)) {
        filteredAdmins.add(admin);
        continue;
      }

      if (admin.profileInfo.lastNames.contains(query)) {
        filteredAdmins.add(admin);
        continue;
      }

      if (admin.accountInfo.subtype.contains(query)) {
        filteredAdmins.add(admin);
        continue;
      }

      if (admin.uid.contains(query)) {
        filteredAdmins.add(admin);
        continue;
      }
      if (status.contains(query)) {
        filteredAdmins.add(admin);
        continue;
      }
    }
    notifyListeners();
  }

  void filterCompanies(String query) {
    filteredCompanies.clear();
    for (WebUser company in allCompanies) {
      String status =
          company.accountInfo.enabled ? "Habilitado" : "Deshabilitado";

      if (company.profileInfo.email.contains(query)) {
        filteredCompanies.add(company);
        continue;
      }
      if (company.profileInfo.names.contains(query)) {
        filteredCompanies.add(company);
        continue;
      }

      if (company.profileInfo.lastNames.contains(query)) {
        filteredCompanies.add(company);
        continue;
      }

      if (company.accountInfo.subtype.contains(query)) {
        filteredCompanies.add(company);
        continue;
      }

      if (company.uid.contains(query)) {
        filteredCompanies.add(company);
        continue;
      }
      if (status.contains(query)) {
        filteredCompanies.add(company);
        continue;
      }
    }
    notifyListeners();
  }

  Future<void> enableDisableAdmin(int adminIndex, bool toEnable) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    UiMethods().showLoadingDialog(context: globalContext!);
    bool itsOk = await AdminActions(actionsRepository).enableDisable(
      id: filteredAdmins[adminIndex].uid,
      toEnable: toEnable,
    );
    UiMethods().hideLoadingDialog(context: globalContext);

    if (!itsOk) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al cambiar el estado del admin",
        icon: Icons.check_outlined,
      );
      return;
    }
    LocalNotificationService.showSnackBar(
      type: "success",
      message: "Esado del admin modificado correctamente",
      icon: Icons.check_outlined,
    );
    filteredAdmins[adminIndex].accountInfo.enabled = toEnable;

    int generalIndex = allAdmins
        .indexWhere((element) => element.uid == filteredAdmins[adminIndex].uid);

    if (generalIndex != -1) {
      allAdmins[generalIndex].accountInfo.enabled = toEnable;
    }
    notifyListeners();
  }

  Future<String> createAdmin(Map<String, dynamic> data,
      [bool isFromClient = false]) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) return '';

      UiMethods().showLoadingDialog(context: globalContext);
      String resp = await AdminActions(actionsRepository).create(data);
      UiMethods().hideLoadingDialog(context: globalContext);
      if (resp == "repeated_email") {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "El correo ingresado ya se encuentra registrado",
          icon: Icons.error_outline,
        );
        return resp;
      }

      if (resp == "error") {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: !isFromClient
              ? "Ocurrió un error al registrar al admin"
              : "Ocurrió un error al registrar al usuario del cliente",
          icon: Icons.error_outline,
        );
        return resp;
      }

      data["account_info"]["creation_date"] =
          Timestamp.fromDate(DateTime.now());
      data["id"] = resp;
      if (!isFromClient) {
        data['company_info'] = Map<String, dynamic>.from({});
        WebUser newAdmin = WebUserModel.fromMap(data);
        allAdmins.add(newAdmin);
        filteredAdmins.add(newAdmin);
        Navigator.of(globalContext).pop();
        LocalNotificationService.showSnackBar(
          type: "success",
          message: "Administrador creado correctamente",
          icon: Icons.check_outlined,
        );
      } else {
        Navigator.of(globalContext).pop();
        // LocalNotificationService.showSnackBar(
        //   type: "success",
        //   message: "Cliente creado correctamente",
        //   icon: Icons.check_outlined,
        // );
        return resp;
      }
      notifyListeners();
      return resp;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return "error";
    }
  }

  Future<void> deleteAdmin(
    String uid, [
    bool isFromUserClient = false,
    bool isAdmin = true,
  ]) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;
    String resp = '';
    UiMethods().showLoadingDialog(context: globalContext);

    resp = await AdminActions(actionsRepository).delete(uid);
    UiMethods().hideLoadingDialog(context: globalContext);

    if (resp == "error") {
      if (!isFromUserClient && isAdmin) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al eliminar al admin",
          icon: Icons.error_outline,
        );
        return;
      } else {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al eliminar al usuario del cliente",
          icon: Icons.error_outline,
        );
        return;
      }
    }

    if (!isFromUserClient && isAdmin) {
      filteredAdmins.removeWhere((element) => element.uid == uid);
      allAdmins.removeWhere((element) => element.uid == uid);
    }

    if (!isFromUserClient && isAdmin) {
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Admin eliminado correctamente",
        icon: Icons.check_outlined,
      );
    } else {
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Usuario del cliente eliminado correctamente",
        icon: Icons.check_outlined,
      );
    }
    notifyListeners();
  }

  Future<void> editAdmin(Map<String, dynamic> data,
      [bool isFromAdmin = false]) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;

    UiMethods().showLoadingDialog(context: globalContext);
    String resp = await AdminActions(actionsRepository).edit(data, isFromAdmin);
    UiMethods().hideLoadingDialog(context: globalContext);

    if (resp == "repeated_email") {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "El correo ingresado ya se encuentra registrado",
        icon: Icons.error_outline,
      );
      return;
    }
    if (isFromAdmin) {
      if (resp == "error") {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al editar el admin",
          icon: Icons.error_outline,
        );
        return;
      }
    }
    int filteredIndex =
        filteredAdmins.indexWhere((element) => element.uid == data["id"]);
    filteredAdmins[filteredIndex].accountInfo.subtype =
        data["user_info"]["subtype"];
    filteredAdmins[filteredIndex].profileInfo.email =
        data["user_info"]["email"];
    filteredAdmins[filteredIndex].profileInfo.names =
        data["user_info"]["names"];
    filteredAdmins[filteredIndex].profileInfo.lastNames =
        data["user_info"]["last_names"];
    filteredAdmins[filteredIndex].profileInfo.phone =
        data["user_info"]["phone"];

    int generalIndex =
        allAdmins.indexWhere((element) => element.uid == data["id"]);
    allAdmins[generalIndex].accountInfo.subtype = data["user_info"]["subtype"];
    allAdmins[generalIndex].profileInfo.email = data["user_info"]["email"];
    allAdmins[generalIndex].profileInfo.names = data["user_info"]["names"];
    allAdmins[generalIndex].profileInfo.lastNames =
        data["user_info"]["last_names"];
    allAdmins[generalIndex].profileInfo.phone = data["user_info"]["phone"];

    Navigator.of(globalContext).pop();

    LocalNotificationService.showSnackBar(
      type: "success",
      message: "Admin editado correctamente",
      icon: Icons.check_outlined,
    );
    notifyListeners();
  }

  // String textCleaned(String textToClean) {
  //   textToClean = removeDiacritics(textToClean)
  //       .toLowerCase()
  //       .trim()
  //       .replaceAll(' ', '')
  //       .toString();
  //   return textToClean;
  // }
}
