// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/config.dart';

import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/activity_service.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/use_cases_params/activity_params.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/clients/data/models/client_model.dart';
import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';

import 'package:huts_web/features/messages/domain/entities/message_entity.dart';
import 'package:huts_web/features/requests/data/models/request_model.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:provider/provider.dart';

import '../../../features/clients/domain/entities/client_entity.dart';
import '../../../features/employees/data/models/employee_model.dart';
import '../../../features/messages/data/models/historical_message_model.dart';
import 'package:http/http.dart' as http;

class EmployeeServices {
  static Future<bool> updateDocStatus(
      {required BuildContext context,
      required String employeeName,
      required String employeeId,
      required String docKey,
      required int newStatus,
      required String urlFile,
      bool addDoc = false,
      String dueDate = '',
      int numDocsExpired = 0}) async {
    try {
      numDocsExpired--;
      !addDoc
          ? await FirebaseServices.db
              .collection("employees")
              .doc(employeeId)
              .update(
              {"documents.$docKey.approval_status": newStatus},
            )
          : addDoc && dueDate != ''
              ? await FirebaseServices.db
                  .collection('employees')
                  .doc(employeeId)
                  .update(
                  {
                    "documents.$docKey.expired_date": DateTime.parse(dueDate),
                    "documents.$docKey.approval_status": newStatus,
                    if (numDocsExpired == 0) "account_info.status": 1
                  },
                )
              : await FirebaseServices.db
                  .collection("employees")
                  .doc(employeeId)
                  .update(
                  {
                    "documents.$docKey.file_url": urlFile,
                    "documents.$docKey.approval_status": newStatus,
                  },
                );

      WebUser admin = Provider.of<AuthProvider>(context, listen: false).webUser;

      String newStatusName = (newStatus == 0)
          ? "Pendiente"
          : (newStatus == 1)
              ? "Aprobado"
              : "Rechazado";

      ActivityParams activityParams = ActivityParams(
        description: addDoc && dueDate != ''
            ? "Se modificó la fecha de vencimiento del documento $docKey del colaborador $employeeName. La nueva fecha es ${CodeUtils.formatDateWithoutHour(DateTime.parse(dueDate))}"
            : "Se actualizó el estado del documento $docKey de $employeeName a estado: $newStatusName",
        category: {
          "key": "docs",
          "name": "Documentos",
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
          "id": employeeId,
          "name": employeeName,
          "type_key": "employee",
          "type_name": "Colaborador"
        },
        date: DateTime.now(),
      );

      await ActivityService.saveChange(activityParams);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateJobs({
    required Employee employee,
    required String jobKey,
    required bool toEnable,
  }) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();

      if (globalContext == null) return false;

      //Get job docs
      Map<String, dynamic> generalDocs =
          Provider.of<GeneralInfoProvider>(globalContext, listen: false)
              .generalInfo
              .countryInfo
              .requiredDocs;

      Map<String, dynamic> jobDocs = Map.fromEntries(
        generalDocs.entries.expand(
          (element) => [
            if (element.value["jobs"].contains(jobKey))
              MapEntry(element.key, element.value)
          ],
        ),
      );

      WebUser admin =
          Provider.of<AuthProvider>(globalContext, listen: false).webUser;

      String description = "";

      String employeeName = CodeUtils.getFormatedName(
        employee.profileInfo.names,
        employee.profileInfo.lastNames,
      );

      if (toEnable) {
        //Add new job docs to employee docs
        jobDocs.forEach((key, value) {
          if (!employee.documents.containsKey(key)) {
            employee.documents[key] = {
              "value": key,
              "can_expire": value['can_expire'],
              "expired_date": null,
              "approval_status": 0,
              "file_url": "",
              "name": value['doc_name'],
              "required": value["required"]
            };
          }
        });

        //Update employee Dbdoc
        await FirebaseServices.db
            .collection("employees")
            .doc(employee.id)
            .update(
          {
            "jobs": FieldValue.arrayUnion([jobKey]),
            "documents": employee.documents,
          },
        );

        ActivityParams activityParams = ActivityParams(
          description:
              "Se habilitó el cargo $jobKey para el colaborador $employeeName",
          category: {
            "key": "jobs",
            "name": "Cargos",
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

        await ActivityService.saveChange(activityParams);

        return true;
      }

      //Remove new job docs from employee docs
      description =
          "Se deshabilitó el cargo $jobKey para el colaborador $employeeName";
      employee.jobs.remove(jobKey);
      jobDocs.forEach((key, value) {
        if (employee.documents.containsKey(key)) {
          //Validate if other employee job needs same doc, then does not delete it
          bool neededByOtherJob = false;
          for (String employeeJob in employee.jobs) {
            if (value["jobs"].contains(employeeJob)) {
              neededByOtherJob = true;
              break;
            }
          }
          if (!neededByOtherJob) {
            employee.documents.remove(key);
          }
        }
      });

      await FirebaseServices.db.collection("employees").doc(employee.id).update(
        {
          "jobs": FieldValue.arrayRemove([jobKey]),
          "documents": employee.documents,
        },
      );

      ActivityParams activityParams = ActivityParams(
        description: description,
        category: {
          "key": "jobs",
          "name": "Cargos",
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
          "name": CodeUtils.getFormatedName(
            employee.profileInfo.names,
            employee.profileInfo.lastNames,
          ),
          "type_key": "employee",
          "type_name": "Colaborador"
        },
        date: DateTime.now(),
      );

      await ActivityService.saveChange(activityParams);

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<HistoricalMessage>?> getMessages(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      BuildContext? context = NavigationService.getGlobalContext();

      if (context != null) {
        UiMethods().showLoadingDialog(context: context);
      }

      List<HistoricalMessage> messages = [];
      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("messages")
          // .where("employees_ids", arrayContains: employeeId)
          .where("date", isGreaterThanOrEqualTo: startDate)
          .where("date", isLessThanOrEqualTo: endDate)
          .get();

      await Future.forEach(querySnapshot.docs,
          (DocumentSnapshot messageDoc) async {
        QuerySnapshot auxQuerySnapshot = await FirebaseServices.db
            .collection("messages")
            .doc(messageDoc.id)
            .collection("employees")
            .where("employee_id", isEqualTo: employeeId)
            .get();

        if (auxQuerySnapshot.size > 0) {
          Map<String, dynamic> messageData =
              messageDoc.data() as Map<String, dynamic>;
          messages.add(
            HistoricalMessageModel.fromMap(messageData),
          );
        }
      });

      if (context != null) {
        UiMethods().hideLoadingDialog(context: context);
      }

      return messages;
    } catch (e) {
      if (kDebugMode) {
        print("EmployeeServices getMessages error: $e");
      }
      return null;
    }
  }

  static Future<List<Request>?> getRequests(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      List<Request> requests = [];
      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("requests")
          .where("employee_info.id", isEqualTo: employeeId)
          .where("details.start_date", isGreaterThanOrEqualTo: startDate)
          .where("details.start_date", isLessThanOrEqualTo: endDate)
          .get();

      for (DocumentSnapshot requestDoc in querySnapshot.docs) {
        Map<String, dynamic> requestData =
            requestDoc.data() as Map<String, dynamic>;
        requests.add(
          RequestModel.fromMap(requestData),
        );
      }
      return requests;
    } catch (e) {
      if (kDebugMode) {
        print("EmployeeServices getRequests error: $e");
      }
      return null;
    }
  }

  static Future<List<Employee>?> getClientEmployees(
    String clientId, {
    Map<String, dynamic>? requestData,
  }) async {
    try {
      List<String> clientJobs = [];

      DocumentSnapshot clientDoc =
          await FirebaseServices.db.collection("clients").doc(clientId).get();

      ClientEntity client =
          ClientModel.fromMap(clientDoc.data() as Map<String, dynamic>);

      client.jobs.forEach(
        (key, value) {
          clientJobs.add(key);
        },
      );

      List<Employee> employees = [];

      //'array-contains-any' filters support a maximum of 10 elements in the value [List].//
      if (clientJobs.length > 10) {
        List<List<String>> groupList = [];
        //create a list of sublists of 10 items each//
        for (int i = 0; i < clientJobs.length; i += 10) {
          groupList.add(
            clientJobs.sublist(
              i,
              (i + 10 > clientJobs.length) ? clientJobs.length : i + 10,
            ),
          );
        }

        //Make the query with each sublist//
        await Future.forEach(groupList, (List<String> subList) async {
          //When requestData its equal to null, the method was not call from assign employee, so, get all employees
          QuerySnapshot querySnapshot = (requestData == null)
              ? await FirebaseServices.db
                  .collection("employees")
                  .where("account_info.status", isGreaterThan: 0)
                  .where("jobs", arrayContainsAny: subList)
                  .get()
              : await FirebaseServices.db
                  .collection("employees")
                  .where("account_info.status", isGreaterThan: 0)
                  .where("account_info.status", isLessThan: 3)
                  .where("jobs", arrayContainsAny: subList)
                  .get();

          if (requestData == null) {
            for (DocumentSnapshot doc in querySnapshot.docs) {
              if (employees.any((element) => element.id == doc.id)) continue;
              employees.add(
                EmployeeModel.fromMap(doc.data() as Map<String, dynamic>),
              );
            }
          } else {
            //If have to validate employee availability//
            // await Future.forEach(
            //   querySnapshot.docs,
            //   (DocumentSnapshot doc) async {
            //     if (!client.blockedEmployees.containsKey(doc.id)) {
            //       Employee employee =
            //           EmployeeModel.fromMap(doc.data() as Map<String, dynamic>);
            //       bool? isAvailable = await EmployeeAvailabilityService.get(
            //         requestData["start_date"],
            //         requestData["end_date"],
            //         employee.id,
            //       );
            //       if (isAvailable != null && isAvailable) {
            //         employees.add(employee);
            //       }
            //     }
            //   },
            // );

            for (DocumentSnapshot doc in querySnapshot.docs) {
              if (employees.any((element) => element.id == doc.id)) continue;
              if (client.blockedEmployees.containsKey(doc.id)) continue;
              Employee employee =
                  EmployeeModel.fromMap(doc.data() as Map<String, dynamic>);
              employees.add(employee);
            }
          }
        });
      } else {
        //When requestData its equal to null, the method was not call from assign employee, so, get all employees
        QuerySnapshot querySnapshot = (requestData == null)
            ? await FirebaseServices.db
                .collection("employees")
                .where("account_info.status", isGreaterThan: 0)
                .where("jobs", arrayContainsAny: clientJobs)
                .get()
            : await FirebaseServices.db
                .collection("employees")
                .where("account_info.status", isGreaterThan: 0)
                .where("account_info.status", isLessThan: 3)
                .where("jobs", arrayContainsAny: clientJobs)
                .get();

        if (requestData == null) {
          for (DocumentSnapshot doc in querySnapshot.docs) {
            if (employees.any((element) => element.id == doc.id)) continue;
            employees.add(
              EmployeeModel.fromMap(doc.data() as Map<String, dynamic>),
            );
          }
        } else {
          //If have to validate employee availability//
          // await Future.forEach(
          //   querySnapshot.docs,
          //   (DocumentSnapshot doc) async {
          //     if (!client.blockedEmployees.containsKey(doc.id)) {
          //       Employee employee =
          //           EmployeeModel.fromMap(doc.data() as Map<String, dynamic>);
          //       bool? isAvailable = await EmployeeAvailabilityService.get(
          //         requestData["start_date"],
          //         requestData["end_date"],
          //         employee.id,
          //       );
          //       if (isAvailable != null && isAvailable) {
          //         employees.add(employee);
          //       }
          //     }
          //   },
          // );

          for (DocumentSnapshot doc in querySnapshot.docs) {
            if (client.blockedEmployees.containsKey(doc.id)) continue;
            if (employees.any((element) => element.id == doc.id)) continue;
            Employee employee =
                EmployeeModel.fromMap(doc.data() as Map<String, dynamic>);
            employees.add(employee);
          }
        }
      }

      return employees;
    } catch (e) {
      if (kDebugMode) {
        print("EmployeeServices getClientEmployees error: $e");
      }
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getJobs(
      String employeeId, BuildContext context) async {
    try {
      List<Map<String, dynamic>> jobs = [];

      DocumentSnapshot employeeDoc = await FirebaseServices.db
          .collection("employees")
          .doc(employeeId)
          .get();

      Employee employee =
          EmployeeModel.fromMap(employeeDoc.data() as Map<String, dynamic>);

      GeneralInfoProvider generalInfoProvider =
          Provider.of<GeneralInfoProvider>(
        context,
        listen: false,
      );

      for (Map<String, dynamic> item in generalInfoProvider
          .generalInfo.countryInfo.jobsFares.values
          .toList()) {
        if (employee.jobs.contains(item["value"])) {
          jobs.add(item);
        }
      }

      return jobs;
    } catch (e) {
      if (kDebugMode) {
        print("EmployeeServices getJobs error: $e");
      }
      return [];
    }
  }

  static Future<bool> changePhoneNumber(
      Map<String, dynamic> data, BuildContext context) async {
    try {
      Uri cloudUrl = Uri.parse("$urlFunctions/updateUser");
      http.Response response = await http.post(
        cloudUrl,
        body: data,
      );
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
              "EmployeeServices changePhoneNumber error, status code: ${response.statusCode}, reason phrase: ${response.reasonPhrase}");
        }
        return false;
      }

      WebUser admin = Provider.of<AuthProvider>(context, listen: false).webUser;

      ActivityParams params = ActivityParams(
        description:
            "El número de teléfono del colaborador ${data["employee_name"]} fue cambiado de ${data["current_phone"]} a ${data["phone"]}",
        category: {
          "key": "register_login",
          "name": "Login y registro",
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
          "id": data["uid"],
          "name": data["employee_name"],
          "type_key": "employee",
          "type_name": "Colaborador"
        },
        date: DateTime.now(),
      );

      await ActivityService.saveChange(params);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("EmployeeServices changePhoneNumber error: $e");
      }
      return false;
    }
  }

  static Future<bool> enableDisable(
      Map<String, dynamic> data, BuildContext context) async {
    try {
      Uri cloudUrl = Uri.parse("$urlFunctions/enableDisableEmployee");
      http.Response response = await http.post(
        cloudUrl,
        headers: {
          "content-type": "application/json",
        },
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
              "EmployeeServices enableDiable error, status code: ${response.statusCode}, reason phrase: ${response.reasonPhrase}");
        }
        return false;
      }

      WebUser admin = Provider.of<AuthProvider>(context, listen: false).webUser;

      String changeDescription = data["to_disable"]
          ? "Se deshabilitó al colaborador ${data["name"]}"
          : "Se habilitó al colaborador ${data["name"]}";

      ActivityParams params = ActivityParams(
        description: changeDescription,
        category: {
          "key": "disablements",
          "name": "Deshabilitaciones",
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
          "id": data["id"],
          "name": data["name"],
          "type_key": "employee",
          "type_name": "Colaborador"
        },
        date: DateTime.now(),
      );

      await ActivityService.saveChange(params);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("EmployeeServices enableDiable error: $e");
      }
      return false;
    }
  }

  static Future<bool> lock(
    String employeeID,
    DateTime unlockDate,
    String description,
    String employeeName,
  ) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();

      if (globalContext == null) return false;

      await FirebaseServices.db.collection("employees").doc(employeeID).update({
        "account_info.status": 3,
        "account_info.unlock_date": unlockDate,
      });

      WebUser admin =
          Provider.of<AuthProvider>(globalContext, listen: false).webUser;

      ActivityParams params = ActivityParams(
        description:
            "Se bloqueó el colaborador $employeeName por: $description",
        category: {
          "key": "locks",
          "name": "Bloqueos",
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
      if (kDebugMode) {
        print("EmployeeServices lock error: $e");
      }
      return false;
    }
  }

  static Future<bool> unlock(String employeeID, String employeeName) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();

      if (globalContext == null) return false;

      await FirebaseServices.db.collection("employees").doc(employeeID).update({
        "account_info.status": 1,
        "account_info.unlock_date": DateTime.now(),
      });

      WebUser admin =
          Provider.of<AuthProvider>(globalContext, listen: false).webUser;

      ActivityParams params = ActivityParams(
        description: "Se desbloqueó el colaborador $employeeName",
        category: {
          "key": "locks",
          "name": "Bloqueos",
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
      if (kDebugMode) {
        print("EmployeeServices unlock error: $e");
      }
      return false;
    }
  }

  static Future<bool> delete(
      String employeeID, String employeeName, BuildContext context) async {
    try {
      Uri cloudUrl = Uri.parse("$urlFunctions/deleteAccount");
      http.Response response = await http.post(
        cloudUrl,
        body: {"uid": employeeID},
      );
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
              "EmployeeServices delete error, status code: ${response.statusCode}, reason phrase: ${response.reasonPhrase}");
        }
        return false;
      }

      WebUser admin = Provider.of<AuthProvider>(context, listen: false).webUser;

      ActivityParams params = ActivityParams(
        description: "Se eliminó al colaborador $employeeName",
        category: {
          "key": "register_login",
          "name": "Login y registro",
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
      if (kDebugMode) {
        print("EmployeeServices delete error: $e");
      }
      return false;
    }
  }

  static Future<Employee?> getById(String id) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> employeeDoc =
          await FirebaseServices.db.collection("employees").doc(id).get();

      if (!employeeDoc.exists) return null;

      return EmployeeModel.fromMap(employeeDoc.data()!);
    } catch (e) {
      if (kDebugMode) {
        print("EmployeeServices getById error: $e");
      }
      return null;
    }
  }
}
