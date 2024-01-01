// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

abstract class SettingsRemoteDatasourse {
  Future<bool> updateRoles(List<Map<String, dynamic>> updateRoles, String type);
  Future<bool> createRole(
    List<Map<String, dynamic>> enabledRoutes,
    String rolType,
    String rolName,
    String clientId,
  );

  Future<String> deleteRol(Map<String, dynamic> toDeleteRol, String rolType);

  Future<bool> updateHoliday(
    Map<String, dynamic> updateHoliday,
  );
  Future<bool> createHoliday(
    Map<String, dynamic> newHoliday,
  );

  Future<String> deleteHoliday(
    Map<String, dynamic> holiday,
  );
}

class SettingsRemoteDatasourseImpl implements SettingsRemoteDatasourse {
  @override
  Future<bool> updateRoles(
      List<Map<String, dynamic>> updateRoles, String type) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();

      if (globalContext == null) return false;

      Map<String, dynamic> webRoutes =
          Provider.of<GeneralInfoProvider>(globalContext, listen: false)
              .otherInfo
              .webRoutes;

      for (Map<String, dynamic> role in updateRoles) {
        role["routes"].forEach(
          (routeKey, routeValue) {
            webRoutes[routeKey]["visibility"][type][role["key"]] =
                routeValue["is_enabled"];
          },
        );
      }

      await FirebaseServices.db
          .collection("info")
          .doc("other_info")
          .update({"web_routes": webRoutes});

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("SettingsRemoteDatasourseImpl, updateClientRoles error: $e");
      }
      return false;
    }
  }

  @override
  Future<bool> createRole(
    List<Map<String, dynamic>> enabledRoutes,
    String rolType,
    String rolName,
    String clientId,
  ) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return false;

      String rolKey = rolName.toLowerCase().replaceAll(" ", "_");

      Map<String, dynamic> webRoutes =
          context.read<GeneralInfoProvider>().otherInfo.webRoutes;

      webRoutes.forEach((key, value) {
        if (enabledRoutes.any((element) => element["key"] == key)) {
          webRoutes[key]["visibility"][rolType][rolKey] = true;
        } else {
          webRoutes[key]["visibility"][rolType][rolKey] = false;
        }
      });

      Map<String, dynamic> systemRolesUpdateMap = {};

      if (rolType == "admin") {
        systemRolesUpdateMap = {
          "system_roles.$rolType.$rolKey": {
            "name": rolName,
            "value": rolKey,
            "has_client_association": clientId.isNotEmpty,
            if (clientId.isNotEmpty) "client_id": clientId.split("-")[0],
            if (clientId.isNotEmpty) "client_name": clientId.split("-")[1],
          },
          "web_user_subtypes.$rolKey": rolName,
          "web_routes": webRoutes,
        };
      } else {
        systemRolesUpdateMap = {
          "system_roles.$rolType.$rolKey": {
            "name": rolName,
            "value": rolKey,
          },
          "web_user_subtypes.$rolKey": rolName,
          "web_routes": webRoutes,
        };
      }

      await FirebaseServices.db
          .collection("info")
          .doc("other_info")
          .update(systemRolesUpdateMap);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("SettingsRemoteDatasourseImpl, createRole error: $e");
      }
      return false;
    }
  }

  @override
  Future<String> deleteRol(
      Map<String, dynamic> toDeleteRol, String rolType) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return "fail";

      //Get web users with the rol
      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("web_users")
          .where("account_info.type", isEqualTo: rolType)
          .where("account_info.subtype", isEqualTo: toDeleteRol["key"])
          .get();

      if (querySnapshot.size > 0) return "inUse";

      GeneralInfoProvider generalInfoProvider =
          context.read<GeneralInfoProvider>();

      Map<String, dynamic> systemRoles =
          generalInfoProvider.otherInfo.systemRoles;

      Map<String, dynamic> webUserSubtypes =
          generalInfoProvider.otherInfo.webUserSubtypes;

      Map<String, dynamic> webRoutes = generalInfoProvider.otherInfo.webRoutes;

      systemRoles[rolType].remove(toDeleteRol["key"]);

      webUserSubtypes.remove(toDeleteRol["key"]);

      webRoutes.forEach((key, value) {
        if (webRoutes[key]["visibility"][rolType]
            .containsKey(toDeleteRol["key"])) {
          webRoutes[key]["visibility"][rolType].remove(toDeleteRol["key"]);
        }
      });

      await FirebaseServices.db.collection("info").doc("other_info").update({
        "system_roles": systemRoles,
        "web_user_subtypes": webUserSubtypes,
        "web_routes": webRoutes,
      });

      return "success";
    } catch (e) {
      if (kDebugMode) {
        print("SettingsRemoteDatasourseImpl, deleteRol error: $e");
      }
      return "fail";
    }
  }

  @override
  Future<bool> createHoliday(Map<String, dynamic> newHoliday) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return false;

      GeneralInfoProvider generalInfoProvider =
          context.read<GeneralInfoProvider>();
      bool repeatNameHoliday = false;

      Map<String, dynamic> holidays = generalInfoProvider.listHolidays;
      for (Map<String, dynamic> element in holidays.values) {
        final holiday = element;
        if (holiday['name'].trim().toLowerCase() ==
            newHoliday['name'].trim().toLowerCase()) {
          repeatNameHoliday = true;
        }
      }
      String key =
          '${newHoliday['day'] < 10 ? '0${newHoliday['day']}' : newHoliday['day']}-${newHoliday['month'] < 10 ? '0${newHoliday['month']}' : newHoliday['month']}';
      if (holidays.containsKey(key) || repeatNameHoliday) {
        return false;
      }

      holidays[key] = Map<String, dynamic>.from(newHoliday);

      holidays;

      await FirebaseServices.db
          .collection("countries_info")
          .doc('costa_rica')
          .update(
        {
          "holidays": holidays,
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("SettingsRemoteDatasourseImpl, createHoliday error: $e");
      }
      return false;
    }
  }

  @override
  Future<String> deleteHoliday(Map<String, dynamic> holiday) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return "fail";

      GeneralInfoProvider generalInfoProvider =
          context.read<GeneralInfoProvider>();
      String key = '${holiday['day']}-${holiday['month']}';
      Map<String, dynamic> holidays = generalInfoProvider.listHolidays;
      MapEntry<String, dynamic> deletedHoliday =
          holidays.entries.firstWhere((element) => element.key == key);
      deletedHoliday;
      holidays.remove(deletedHoliday.key);
      holidays;
      await FirebaseServices.db
          .collection("countries_info")
          .doc("costa_rica")
          .update(
        {
          "holidays": holidays,
        },
      );

      return "success";
    } catch (e) {
      if (kDebugMode) {
        print("SettingsRemoteDatasourseImpl, deleteHoliday error: $e");
      }
      return "fail";
    }
  }

  @override
  Future<bool> updateHoliday(Map<String, dynamic> updateHoliday) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return false;
      bool repeatNameHoliday = false;

      GeneralInfoProvider generalInfoProvider =
          context.read<GeneralInfoProvider>();

      Map<String, dynamic> holidays = generalInfoProvider.listHolidays;
      String key =
          '${updateHoliday['day'] < 10 ? '0${updateHoliday['day']}' : updateHoliday['day']}-${updateHoliday['month'] < 10 ? '0${updateHoliday['month']}' : updateHoliday['month']}';

      MapEntry<String, dynamic> holiday = holidays.entries.firstWhere(
          (element) => element.key == updateHoliday['old_holiday']['key']);

      for (Map<String, dynamic> element in holidays.values) {
        final holiday = element;
        if (holiday['name'].trim().toLowerCase() ==
            updateHoliday['name'].trim().toLowerCase()) {
          repeatNameHoliday = true;
        }
      }
      if (holidays.containsKey(key) || repeatNameHoliday) {
        return false;
      }
      holidays.remove(holiday.key);

      holidays[key] = Map<String, dynamic>.from({
        'name': updateHoliday['name'],
        'month': updateHoliday['month'],
        'day': updateHoliday['day'],
      });

      holidays;
      await FirebaseServices.db
          .collection("countries_info")
          .doc("costa_rica")
          .update(
        {
          "holidays": holidays,
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("SettingsRemoteDatasourseImpl, updateHoliday error: $e");
      }
      return false;
    }
  }
}
