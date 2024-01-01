// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/employee_services/employee_services.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/employees/data/models/employee_model.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/activity_service.dart';
import '../../../../core/use_cases_params/activity_params.dart';
import '../../../../core/utils/code/code_utils.dart';
import '../../../auth/display/providers/auth_provider.dart';
import '../../../auth/domain/entities/web_user_entity.dart';
import '../../../clients/domain/entities/client_entity.dart';

abstract class FaresRemoteDatasource {
  Future<bool> updateJobFares(Map<String, dynamic> newData);
  Future<String> deleteJobFare(Map<String, dynamic> data);
  Future<String> createJob(Map<String, dynamic> data);
  Future<String> createDoc(Map<String, dynamic> data);
}

class FaresRemoteDatasourceImpl implements FaresRemoteDatasource {
  @override
  Future<bool> updateJobFares(Map<String, dynamic> newData) async {
    try {
      ClientEntity? client;
      BuildContext? context = NavigationService.getGlobalContext();
      if (context == null) return true;
      if (newData["type"] == "admin") {
        await FirebaseServices.db
            .collection("countries_info")
            .doc(newData["country"])
            .update(
          {
            "jobs_fares.${newData["job"]}.fares": {
              "normal": newData["normal"],
              "holiday": newData["holiday"],
              "dynamic": newData["dynamic"],
            }
          },
        );
      } else {
        await FirebaseServices.db
            .collection("clients")
            .doc(newData["client_id"])
            .update(
          {
            "jobs.${newData["job"]}.fares": {
              "normal": newData["normal"],
              "holiday": newData["holiday"],
              "dynamic": newData["dynamic"],
            },
          },
        );
        List<ClientEntity> clients = context.read<ClientsProvider>().allClients;
        client = clients.firstWhere(
            (element) => element.accountInfo.id == newData["client_id"]);
      }

      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;
      String description = newData["type"] == "admin"
          ? 'Se actualizo la tarifa del cargo: ${newData["job_name"]}'
          : 'Se actualizo la tarifa del cargo: ${newData["job_name"]}, para el cliente ${client!.name}';
      ActivityParams activityParams = ActivityParams(
        description: description,
        category: {
          "key": "fares",
          "name": "Tarifas",
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
  Future<String> deleteJobFare(Map<String, dynamic> data) async {
    try {
      //Get active requests with the job to delete
      QuerySnapshot activeRequestsQuery = await FirebaseServices.db
          .collection("requests")
          .where("details.status", isLessThan: 4)
          .where("details.job.value", isEqualTo: data["job_info"]["value"])
          .get();

      if (activeRequestsQuery.docs.isNotEmpty) return "active-requests";

      //Get clients with the job to delete
      QuerySnapshot clientsQuery = await FirebaseServices.db
          .collection("clients")
          //This where does not works :'v//
          // .where(
          //     "jobs.${data["job_info"]["value"]}.${data["job_info"]["name"]}",
          //     isEqualTo: data["job_info"]["name"])
          .get();

      BuildContext? globalContext = NavigationService.getGlobalContext();

      ClientsProvider? clientsProvider;
      EmployeesProvider? employeesProvider;

      //Delete job from gotten clients
      await Future.forEach(
        clientsQuery.docs,
        (DocumentSnapshot clientDoc) async {
          Map<String, dynamic> clientData =
              clientDoc.data() as Map<String, dynamic>;
          if (clientData["jobs"].containsKey(data["job_info"]["value"])) {
            await FirebaseServices.db
                .collection("clients")
                .doc(clientDoc.id)
                .update(
              {
                "jobs.${data["job_info"]["value"]}": FieldValue.delete(),
              },
            );
            if (globalContext != null) {
              clientsProvider ??=
                  Provider.of<ClientsProvider>(globalContext, listen: false);
              clientsProvider!.allClients.removeWhere(
                (element) => element.accountInfo.id == clientDoc.id,
              );
              clientsProvider!.filteredClients.removeWhere(
                (element) => element.accountInfo.id == clientDoc.id,
              );
            }
          }
        },
      );

      //Get employees with the job to delete
      QuerySnapshot employeesQuery = await FirebaseServices.db
          .collection("employees")
          .where("jobs", arrayContains: data["job_info"]["value"])
          .get();

      //Delete job from gotten employees
      await Future.forEach(
        employeesQuery.docs,
        (DocumentSnapshot employeeDoc) async {
          Employee employee =
              EmployeeModel.fromMap(employeeDoc.data() as Map<String, dynamic>);

          await EmployeeServices.updateJobs(
            employee: employee,
            jobKey: data["job_info"]["value"],
            toEnable: false,
          );
          if (globalContext != null) {
            employeesProvider ??=
                Provider.of<EmployeesProvider>(globalContext, listen: false);

            int generalIndex = employeesProvider!.employees
                .indexWhere((element) => element.id == employeeDoc.id);

            int filteredIndex = employeesProvider!.filteredEmployees
                .indexWhere((element) => element.id == employeeDoc.id);

            if (generalIndex != -1) {
              employeesProvider!.employees[generalIndex].jobs
                  .remove(data["job_info"]["value"]);
            }

            if (filteredIndex != -1) {
              employeesProvider!.filteredEmployees[filteredIndex].jobs
                  .remove(data["job_info"]["value"]);
            }
          }
        },
      );

      //Get general country info
      DocumentSnapshot countryDoc = await FirebaseServices.db
          .collection("countries_info")
          .doc(data["country_id"])
          .get();

      Map<String, dynamic> countryData =
          countryDoc.data() as Map<String, dynamic>;

      countryData["jobs_fares"].remove(data["job_info"]["value"]);

      Map<String, dynamic> requiredDocsCopy = {...countryData["required_docs"]};

      requiredDocsCopy.forEach((key, value) {
        if (countryData["required_docs"][key]["jobs"].length == 1 &&
            countryData["required_docs"][key]["jobs"][0] ==
                data["job_info"]["value"]) {
          countryData["required_docs"].remove(key);
        } else {
          countryData["required_docs"][key]["jobs"]
              .removeWhere((element) => element == data["job_info"]["value"]);
        }
      });

      //Delete job from general country info
      await FirebaseServices.db
          .collection("countries_info")
          .doc(data["country_id"])
          .update(
        {
          "jobs_fares": countryData["jobs_fares"],
          "required_docs": countryData["required_docs"],
        },
      );

      return "success";
    } catch (e) {
      if (kDebugMode) {
        print("FaresRemoteDatasourceImpl, deleteJobFare error: $e");
      }
      return "error";
    }
  }

  @override
  Future<String> createJob(Map<String, dynamic> data) async {
    try {
      DocumentSnapshot generalInfoDoc = await FirebaseServices.db
          .collection("countries_info")
          .doc(data["country_id"])
          .get();

      Map<String, dynamic> generalInfoData =
          generalInfoDoc.data() as Map<String, dynamic>;

      if (generalInfoData["jobs_fares"]
          .containsKey(data["job_info"]["value"])) {
        return "already_exists";
      }

      generalInfoData["jobs_fares"][data["job_info"]["value"]] =
          data["job_info"];

      for (Map<String, dynamic> newJobDoc in data["required_docs"]) {
        generalInfoData["required_docs"][newJobDoc["key"]]["jobs"]
            .add(data["job_info"]["value"]);
      }

      await FirebaseServices.db
          .collection("countries_info")
          .doc(data["country_id"])
          .update(
        {
          "required_docs": generalInfoData["required_docs"],
          "jobs_fares": generalInfoData["jobs_fares"],
        },
      );

      return "success";
    } catch (e) {
      if (kDebugMode) {
        print("FaresRemoteDatasourceImpl, createJob error: $e");
      }
      return "error";
    }
  }

  @override
  Future<String> createDoc(Map<String, dynamic> data) async {
    try {
      String key = data["key"];
      data.remove(key);
      await FirebaseServices.db
          .collection("countries_info")
          .doc("costa_rica")
          .update(
        {"required_docs.$key": data},
      );
      return "success";
    } catch (e) {
      if (kDebugMode) {
        print("FaresRemoteDatasourceImpl, createDoc error: $e");
      }
      return "error";
    }
  }
}
