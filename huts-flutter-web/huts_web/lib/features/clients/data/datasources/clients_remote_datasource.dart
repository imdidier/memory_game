// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/features/clients/data/models/client_model.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/activity_service.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/use_cases_params/activity_params.dart';
import '../../../../core/utils/code/code_utils.dart';
import '../../../auth/display/providers/auth_provider.dart';
import '../../../auth/domain/entities/web_user_entity.dart';
import '../../display/provider/clients_provider.dart';

abstract class ClientsRemoteDatasource {
  Future<void> listenClients();

  Future<bool> deleteClient({required String clientId});

  Future<bool> enableDisabled(String id, int status, bool isAdmin,
      [bool enabledWebUser = false]);

  Future<bool> createClient({required Map<String, dynamic> client});

  Future<bool> updateGeneralInfo(
      {required String clientId, required Map<String, dynamic> updateInfo});

  Future<bool> updateLegalInfo(
      {required String clientId, required Map<String, dynamic> updateInfo});

  Future<bool> updateFavs(
      {required String clientId, required Map<String, dynamic> updateInfo});

  Future<bool> updateWebUsers(
      {required String clientId, required Map<String, dynamic> updateInfo});

  Future<bool> updateLocks(
      {required String clientId, required Map<String, dynamic> updateInfo});

  Future<bool> updateDynamicFareAvailability(
      {required String clientId, required Map<String, dynamic> updateInfo});

  Future<bool> updateJobs(
      {required String clientId, required Map<String, dynamic> updateInfo});

  Future<bool> updateLocation(
      {required String clientId, required Map<String, dynamic> updateInfo});
}

class ClientsRemoteDatasourceImpl implements ClientsRemoteDatasource {
  @override
  Future<void> listenClients() async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) {
        throw const ServerException("El contexto es nulo");
      }
      StreamSubscription stream =
          FirebaseServices.db.collection("clients").snapshots().listen(
        (QuerySnapshot querySnapshot) async {
          List<ClientModel> clients = [];

          for (DocumentSnapshot doc in querySnapshot.docs) {
            clients
                .add(ClientModel.fromMap(doc.data() as Map<String, dynamic>));
          }

          Provider.of<ClientsProvider>(globalContext, listen: false)
              .updateClients(clients);
          clients;
        },
      );

      int index = FirebaseServices.streamSubscriptions
          .indexWhere((addedStream) => addedStream.id == "listen_clients");

      if (index != -1) {
        await FirebaseServices.streamSubscriptions[index].streamSubscription
            ?.cancel();
        FirebaseServices.streamSubscriptions.removeAt(index);
      }

      FirebaseServices.streamSubscriptions.add(
        FirestoreStream(
          id: "listen_clients",
          streamSubscription: stream,
        ),
      );
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> enableDisabled(String id, int status, bool isAdmin,
      [bool enabledWebUser = false]) async {
    try {
      isAdmin && !enabledWebUser
          ? await FirebaseServices.db.collection("clients").doc(id).update(
              {
                "account_info.status": status,
              },
            )
          : await FirebaseServices.db.collection("web_users").doc(id).update(
              {
                "account_info.enabled": status == 0 ? false : true,
              },
            );
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      ActivityParams activityParams = ActivityParams(
        description: isAdmin && !enabledWebUser
            ? "Se ${status == 0 ? 'deshabilito' : 'habilito'} el cliente con id $id"
            : "Se ${status == 0 ? 'deshabilito' : 'habilito'} al usuario con id $id del cliente ${webUser.company.name}",
        category: {
          //TODO: colocar nombre de categoría
          "key": "web_users",
          "name": "Web Users",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {
          "id": "",
          "name": "",
          "type_key": "",
          "type_name": "",
        },
        date: DateTime.now(),
      );
      await ActivityService.saveChange(activityParams);

      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> deleteClient({
    required String clientId,
  }) async {
    try {
      await FirebaseServices.db.collection("clients").doc(clientId).delete();
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      ActivityParams activityParams = ActivityParams(
        description: "Se elimino al cliente con id $clientId",
        category: {
          //TODO: verificar la categoría
          "key": "client",
          "name": "Clientes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {
          "id": "",
          "name": "",
          "type_key": "",
          "type_name": "",
        },
        date: DateTime.now(),
      );
      await ActivityService.saveChange(activityParams);
      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> createClient({
    required Map<String, dynamic> client,
  }) async {
    try {
      client["night_workshift"] = {
        "surcharge": 0.08,
        "start_hour": 22,
        "start_minutes": 0,
        "end_hour": 6,
        "end_minutes": 0,
      };

      await FirebaseServices.db
          .collection("clients")
          .doc(client["account_info"]["id"])
          .set(client);

      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      ActivityParams activityParams = ActivityParams(
        description:
            "Se creo el cliente con id ${client["account_info"]["id"]}",
        category: {
          //TODO: verificar la categoría
          "key": "client",
          "name": "Clientes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {
          "id": "",
          "name": "",
          "type_key": "",
          "type_name": "",
        },
        date: DateTime.now(),
      );
      await ActivityService.saveChange(activityParams);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateGeneralInfo(
      {required String clientId,
      required Map<String, dynamic> updateInfo}) async {
    try {
      await FirebaseServices.db.collection("clients").doc(clientId).update(
        {
          "name": updateInfo["name"],
          "email": updateInfo["email"],
          "legal_info.phone": updateInfo["phone"],
          "account_info.min_request_hours": updateInfo["minRequestHours"],
        },
      );
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      ActivityParams activityParams = ActivityParams(
        description:
            "Se actualizo la información general del cliente con id $clientId",
        category: {
          //TODO: verificar la categoría
          "key": "client",
          "name": "Clientes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {
          "id": "",
          "name": "",
          "type_key": "",
          "type_name": "",
        },
        date: DateTime.now(),
      );
      await ActivityService.saveChange(activityParams);
      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> updateLegalInfo(
      {required String clientId,
      required Map<String, dynamic> updateInfo}) async {
    try {
      await FirebaseServices.db.collection("clients").doc(clientId).update({
        "legal_info.company_legal_id": clientId,
        "legal_info.legal_representative": updateInfo["legal_representative"],
        "legal_info.email": updateInfo["email"],
        "legal_info.legal_representative_document":
            updateInfo["legal_representative_document"],
        // "account_info.min_request_hours": updateInfo["minRequestHours"],
      });
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      ActivityParams activityParams = ActivityParams(
        description:
            "Se actualizo la información legal del cliente con id $clientId}",
        category: {
          //TODO: verificar la categoría
          "key": "client",
          "name": "Clientes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {
          "id": "",
          "name": "",
          "type_key": "",
          "type_name": "",
        },
        date: DateTime.now(),
      );
      await ActivityService.saveChange(activityParams);
      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> updateFavs(
      {required String clientId,
      required Map<String, dynamic> updateInfo}) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      if (updateInfo["action"] == "add") {
        await FirebaseServices.db
            .collection("clients")
            .doc(clientId)
            .update({"favorites": updateInfo["employees"]});
      } else {
        await FirebaseServices.db.collection("clients").doc(clientId).update(
          {
            "favorites.${updateInfo["employee"]["uid"]}": FieldValue.delete(),
          },
        );
      }
      List<Map<String, dynamic>> employees = [];
      if (updateInfo["action"] != "add") {
        employees.add(updateInfo["employee"]);
      }
      await Future.forEach(
          List<Map<String, dynamic>>.from(updateInfo["action"] == "add"
              ? updateInfo["employees"].values
              : employees), (Map<String, dynamic> employee) async {
        ActivityParams activityParams = ActivityParams(
          description: updateInfo["action"] == "add"
              ? "Se marcó como favorito al colaborador ${employee['fullname']}"
              : "Se desmarcó como favorito al colaborador ${employee['fullname']}",
          category: {
            "key": "employees",
            "name": "Colaboradores",
          },
          personInCharge: {
            "name": CodeUtils.getFormatedName(
                webUser.profileInfo.names, webUser.profileInfo.lastNames),
            "type_key": webUser.accountInfo.type,
            "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
            "id": webUser.uid,
            "company_id": webUser.accountInfo.companyId
          },
          affectedUser: {
            "id": "",
            "name": "",
            "type_key": "",
            "type_name": "",
          },
          date: DateTime.now(),
        );
        await ActivityService.saveChange(activityParams);
      });
      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> updateWebUsers(
      {required String clientId,
      required Map<String, dynamic> updateInfo}) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();
      if (context == null) return true;
      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      if (updateInfo["action"] == "add" ||
          updateInfo["action"] == "edit" ||
          updateInfo["action"] == "enabled") {
        await FirebaseServices.db.collection("clients").doc(clientId).update(
          {
            "web_users.${updateInfo["employee"]["uid"]}": updateInfo["employee"]
          },
        );
      } else {
        // if (updateInfo["action"] == "delete") {
        await FirebaseServices.db.collection("clients").doc(clientId).update(
          {
            "web_users.${updateInfo["employee"]["uid"]}": FieldValue.delete(),
          },
        );
      }
      if (updateInfo["action"] != "enabled") {
        ActivityParams activityParams = ActivityParams(
          description: updateInfo["action"] == "add"
              ? "Se creo un nuevo usuario para el cliente ${webUser.company.name}"
              : updateInfo["action"] == "edit"
                  ? "Se edito el usuario con id${updateInfo["employee"]["uid"]} del cliente ${webUser.company.name}"
                  : "Se elimino el usuario con id${updateInfo["employee"]['uid']} del cliente ${webUser.company.name}",
          category: {
            "key": "web_users",
            "name": "Web users",
          },
          personInCharge: {
            "name": CodeUtils.getFormatedName(
                webUser.profileInfo.names, webUser.profileInfo.lastNames),
            "type_key": webUser.accountInfo.type,
            "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
            "id": webUser.uid,
            "company_id": webUser.accountInfo.companyId
          },
          affectedUser: {
            "id": "",
            "name": "",
            "type_key": "",
            "type_name": "",
          },
          date: DateTime.now(),
        );
        await ActivityService.saveChange(activityParams);
      }
      return true;
      // }
      // await FirebaseServices.db.collection("clients").doc(clientId).update(
      //   {
      //     "web_users.${updateInfo["employee"]["uid"]}": updateInfo['employee'],
      //   },
      // );
      // return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> updateLocks(
      {required String clientId,
      required Map<String, dynamic> updateInfo}) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();
      if (context == null) return true;
      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      if (updateInfo["action"] == "add") {
        await FirebaseServices.db.collection("clients").doc(clientId).update(
          {"blocked_employees": updateInfo["employees"]},
        );
      } else {
        await FirebaseServices.db.collection("clients").doc(clientId).update(
          {
            "blocked_employees.${updateInfo["employee"]["uid"]}":
                FieldValue.delete(),
          },
        );
      }
      List<Map<String, dynamic>> employees = [];
      if (updateInfo["action"] != "add") {
        employees.add(updateInfo["employee"]);
      }
      await Future.forEach(
        List<Map<String, dynamic>>.from(
          updateInfo["action"] == "add"
              ? updateInfo["employees"].values
              : employees,
        ),
        (Map<String, dynamic> employee) async {
          ActivityParams activityParams = ActivityParams(
            description: updateInfo["action"] == "add"
                ? "Se bloqueó al colaborador ${employee['fullname']}"
                : "Se desbloqueó al colaborador ${employee['fullname']}",
            category: {
              "key": "employees",
              "name": "Colaboradores",
            },
            personInCharge: {
              "name": CodeUtils.getFormatedName(
                  webUser.profileInfo.names, webUser.profileInfo.lastNames),
              "type_key": webUser.accountInfo.type,
              "type_name":
                  CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
              "id": webUser.uid,
              "company_id": webUser.accountInfo.companyId
            },
            affectedUser: {
              "id": "",
              "name": "",
              "type_key": "",
              "type_name": "",
            },
            date: DateTime.now(),
          );
          await ActivityService.saveChange(activityParams);
        },
      );
      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> updateDynamicFareAvailability(
      {required String clientId,
      required Map<String, dynamic> updateInfo}) async {
    try {
      await FirebaseServices.db.collection("clients").doc(clientId).update(
        {
          "account_info.has_dynamic_fare": updateInfo["new_value"],
        },
      );
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      ActivityParams activityParams = ActivityParams(
        description:
            "Se ${updateInfo["new_value"] == true ? 'habilito' : 'deshabilito'} la tarifa dinámica del cliente con id $clientId}",
        category: {
          //TODO: verificar la categoría
          "key": "client",
          "name": "Clientes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {
          "id": "",
          "name": "",
          "type_key": "",
          "type_name": "",
        },
        date: DateTime.now(),
      );
      await ActivityService.saveChange(activityParams);
      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> updateJobs(
      {required String clientId,
      required Map<String, dynamic> updateInfo}) async {
    try {
      if (updateInfo["type"] == "add") {
        await FirebaseServices.db.collection("clients").doc(clientId).update(
          {
            "jobs.${updateInfo["job_info"]["value"]}": updateInfo["job_info"],
          },
        );
      } else {
        await FirebaseServices.db.collection("clients").doc(clientId).update(
          {
            "jobs.${updateInfo["job_info"]["value"]}": FieldValue.delete(),
          },
        );
      }
      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      ActivityParams activityParams = ActivityParams(
        description:
            "Se ${updateInfo["type"] == "add" ? 'agregó' : 'eliminó'} un cargo para el cliente con id $clientId}",
        category: {
          //TODO: verificar la categoría
          "key": "client",
          "name": "Clientes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {
          "id": "",
          "name": "",
          "type_key": "",
          "type_name": "",
        },
        date: DateTime.now(),
      );
      await ActivityService.saveChange(activityParams);

      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> updateLocation(
      {required String clientId,
      required Map<String, dynamic> updateInfo}) async {
    try {
      await FirebaseServices.db.collection("clients").doc(clientId).update(
        {
          "location": updateInfo,
        },
      );

      BuildContext? context = NavigationService.getGlobalContext();

      if (context == null) return true;

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      ActivityParams activityParams = ActivityParams(
        description: "Se modificó la ubicación del cliente con id $clientId}",
        category: {
          //TODO: verificar la categoría
          "key": "client",
          "name": "Clientes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {
          "id": "",
          "name": "",
          "type_key": "",
          "type_name": "",
        },
        date: DateTime.now(),
      );
      await ActivityService.saveChange(activityParams);

      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }
}
