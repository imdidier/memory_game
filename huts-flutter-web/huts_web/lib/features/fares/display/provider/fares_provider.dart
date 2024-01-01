// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/fares/data/datasources/fares_remote_datasource.dart';
import 'package:huts_web/features/fares/data/repositories/job_fares_crud_repository_impl.dart';
import 'package:huts_web/features/fares/domain/use_cases/job_fares_crud.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/firebase_config/firebase_services.dart';

class FaresProvider with ChangeNotifier {
  JobFaresCrudRepositoryImpl repository = JobFaresCrudRepositoryImpl(
    FaresRemoteDatasourceImpl(),
  );

  List<Map<String, dynamic>> dynamicFares = [];

  List<TextEditingController> normalControllers = [];

  List<TextEditingController> holidayControllers =
      List<TextEditingController>.generate(
    2,
    (index) => TextEditingController(),
  );

  List<TextEditingController> dynamicControllers = [];

  Future<void> updateJobFares(Map<String, dynamic> data) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) {
      return LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al actualizar la información (context)",
        icon: Icons.error_outline,
      );
    }

    UiMethods().showLoadingDialog(context: globalContext);

    Either<Failure, bool> resp = await JobFaresCrud(repository: repository)
        .updateJobFares(jobFares: data);

    resp.fold((l) {
      if (kDebugMode) print("FaresProvider updateJobFares: ${l.errorMessage}");
      UiMethods().hideLoadingDialog(context: globalContext);
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al actualizar la tarifa",
        icon: Icons.error_outline,
      );
    }, (r) async {
      await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
          .getGeneralInfoOrFail(globalContext);
      UiMethods().hideLoadingDialog(context: globalContext);
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Tarifa actualizada correctamente",
        icon: Icons.check,
      );
    });
  }

  Future<void> deleteJob(Map<String, dynamic> data) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) {
      return LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al eliminar el cargo (context)",
        icon: Icons.error_outline,
      );
    }

    UiMethods().showLoadingDialog(context: globalContext);

    String resp = await JobFaresCrud(repository: repository).deleteJob(data);

    UiMethods().hideLoadingDialog(context: globalContext);

    if (resp == "success") {
      Provider.of<GeneralInfoProvider>(globalContext, listen: false)
          .removeLocalJob(data["job_info"]["value"]);
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Cargo eliminado correctamente",
        icon: Icons.check,
      );
      return;
    }

    if (resp == "error") {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al eliminar el cargo",
        icon: Icons.error_outline,
      );
      return;
    }
    LocalNotificationService.showSnackBar(
      type: "fail",
      message: "No se puede eliminar el cargo, este tiene solicitudes activas",
      icon: Icons.error_outline,
    );
  }

  bool validateNewJobFare() {
    // if (normalControllers
    //     .any((TextEditingController controller) => controller.text == "0")) {
    //   LocalNotificationService.showSnackBar(
    //     type: "fail",
    //     message: "Tienes campos con ceros en la tarifa normal",
    //     icon: Icons.error_outline,
    //   );
    //   return false;
    // }

    // if (holidayControllers
    //     .any((TextEditingController controller) => controller.text == "0")) {
    //   LocalNotificationService.showSnackBar(
    //     type: "fail",
    //     message: "Tienes campos con ceros en la tarifa festiva",
    //     icon: Icons.error_outline,
    //   );
    //   return false;
    // }
    // if (dynamicControllers
    //     .any((TextEditingController controller) => controller.text == "0")) {
    //   LocalNotificationService.showSnackBar(
    //     type: "fail",
    //     message: "Tienes campos con ceros en la tarifa dinámica",
    //     icon: Icons.error_outline,
    //   );
    //   return false;
    // }

    return true;
  }

  Future<void> createJob(Map<String, dynamic> data) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    UiMethods().showLoadingDialog(context: globalContext);

    String resp = await JobFaresCrud(repository: repository).createJob(data);

    UiMethods().hideLoadingDialog(context: globalContext);

    if (resp == "success") {
      Provider.of<GeneralInfoProvider>(globalContext, listen: false)
          .addLocalJob(data["job_info"]);
      Navigator.of(globalContext).pop();
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Cargo creado correctamente",
        icon: Icons.check,
      );
      return;
    }

    if (resp == "error") {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al crear el cargo",
        icon: Icons.error_outline,
      );
      return;
    }
    LocalNotificationService.showSnackBar(
      type: "fail",
      message: "No se puede crear el cargo, ya existe uno con el mismo nombre",
      icon: Icons.error_outline,
    );
  }

  Future<void> updateJobDocs(Map<String, dynamic> data) async {
    try {
      //TODO: Move this db update to clean architecture

      BuildContext? globalContext = NavigationService.getGlobalContext();

      if (globalContext == null) return;

      UiMethods().showLoadingDialog(context: globalContext);

      DocumentSnapshot generalInfoDoc = await FirebaseServices.db
          .collection("countries_info")
          .doc(data["country_id"])
          .get();

      Map<String, dynamic> generalInfoData =
          generalInfoDoc.data() as Map<String, dynamic>;

      Map<String, dynamic> generalDocs = {...generalInfoData["required_docs"]};

      String fareJobKey = data["job_info"]["value"];

      generalDocs.forEach(
        (generalDocKey, generalDocData) {
          //If general doc already contains fare job///
          if (generalDocData["jobs"].contains(fareJobKey)) {
            if (!data["required_docs"]
                .any((element) => element["key"] == generalDocKey)) {
              //Remove job fom general  doc
              generalInfoData["required_docs"][generalDocKey]["jobs"]
                  .remove(fareJobKey);
            }
          } else {
            //If general doc doesn't contain fare job///
            if (data["required_docs"]
                .any((element) => element["key"] == generalDocKey)) {
              //Add job to doc
              generalInfoData["required_docs"][generalDocKey]["jobs"]
                  .add(fareJobKey);
            }
          }
        },
      );

      await FirebaseServices.db
          .collection("countries_info")
          .doc(data["country_id"])
          .update(
        {
          "required_docs": generalInfoData["required_docs"],
        },
      );

      GeneralInfoProvider generalInfoProvider =
          Provider.of<GeneralInfoProvider>(globalContext, listen: false);

      //Get employees with the edited job//
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseServices
          .db
          .collection("employees")
          .where("jobs", arrayContains: data["job_info"]["value"])
          .get();

      //Loop gotten employees
      await Future.forEach(
        querySnapshot.docs,
        (DocumentSnapshot<Map<String, dynamic>> employeeDoc) async {
          if (employeeDoc.exists) {
            Map<String, dynamic> employeeData = employeeDoc.data()!;

            //Get required docs by employee jobs//
            Map<String, dynamic> employeeRequiredDocs = {};

            for (String employeeJobValue in employeeData["jobs"]) {
              generalInfoData["required_docs"].forEach((key, value) {
                if (value["jobs"].contains(employeeJobValue)) {
                  employeeRequiredDocs[key] = value;
                }
              });
            }

            Map<String, dynamic> finalEmployeeDocs = {};

            for (String employeeRequiredDocKey
                in employeeRequiredDocs.keys.toList()) {
              if (employeeData["documents"]
                  .containsKey(employeeRequiredDocKey)) {
                finalEmployeeDocs[employeeRequiredDocKey] =
                    employeeData["documents"][employeeRequiredDocKey];
              } else {
                finalEmployeeDocs[employeeRequiredDocKey] = {
                  "approval_status": 0,
                  "can_expire": employeeRequiredDocs[employeeRequiredDocKey]
                      ["can_expire"],
                  "expired_date": null,
                  "file_url": "",
                  "name": employeeRequiredDocs[employeeRequiredDocKey]
                      ["doc_name"],
                  "required": employeeRequiredDocs[employeeRequiredDocKey]
                      ["required"],
                  "value": employeeRequiredDocKey,
                };
              }
            }

            await FirebaseServices.db
                .collection("employees")
                .doc(employeeDoc.id)
                .update(
              {
                "documents": finalEmployeeDocs,
              },
            );
          }
        },
      );

      UiMethods().hideLoadingDialog(context: globalContext);

      Navigator.of(globalContext).pop();

      generalInfoProvider.generalInfo.countryInfo.requiredDocs =
          generalInfoData["required_docs"];

      generalInfoProvider.generalInfo.countryInfo
          .jobsFares[data["job_info"]["value"]] = data["job_info"];

      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Cargo actualizado correctamente",
        icon: Icons.check,
      );
    } catch (e) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al actualizar el cargo",
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> createDoc(Map<String, dynamic> data) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    UiMethods().showLoadingDialog(context: globalContext);
    String resp = await JobFaresCrud(repository: repository).createDoc(data);
    UiMethods().hideLoadingDialog(context: globalContext);

    if (resp == "error") {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al crear el cargo",
        icon: Icons.error_outline,
      );
      return;
    }

    Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .generalInfo
        .countryInfo
        .requiredDocs[data["key"]] = data;

    Navigator.of(globalContext).pop();

    LocalNotificationService.showSnackBar(
      type: "success",
      message: "Listo, documento creado correctamente",
      icon: Icons.error_outline,
    );
  }
}
