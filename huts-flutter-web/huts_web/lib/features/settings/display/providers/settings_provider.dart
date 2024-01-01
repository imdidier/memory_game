// ignore_for_file: use_build_context_synchronously

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/settings/data/datatsources/settings_remote_datasourse.dart';
import 'package:huts_web/features/settings/data/repositories/holidays_repository_impl.dart';
import 'package:huts_web/features/settings/data/repositories/system_roles_repository_impl.dart';
import 'package:huts_web/features/settings/domain/use_cases/holidays_crud.dart';
import 'package:huts_web/features/settings/domain/use_cases/system_roles_crud.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui/ui_methods.dart';
import '../../../../core/utils/ui/ui_variables.dart';

class SettingsProvider with ChangeNotifier {
  SystemRolesRepositoryImpl systemRolesRepositoryImpl =
      SystemRolesRepositoryImpl(SettingsRemoteDatasourseImpl());

  HolidaysRepositoryImpl holidayRepositoryImpl =
      HolidaysRepositoryImpl(SettingsRemoteDatasourseImpl());
  DateTime currentDate = DateTime.now();

  Future<void> updateClientRoles(
      List<Map<String, dynamic>> updatedRoles, String type) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    UiMethods().showLoadingDialog(context: globalContext);

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    bool itsOk = await SystemRolesCrud(systemRolesRepositoryImpl)
        .updateRoles(updatedRoles, type);

    if (!itsOk) {
      UiMethods().hideLoadingDialog(context: globalContext);
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al actualizar los roles",
        icon: Icons.check,
      );
      return;
    }

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    UiMethods().hideLoadingDialog(context: globalContext);

    LocalNotificationService.showSnackBar(
      type: "success",
      message: "Roles actualizados correctamente",
      icon: Icons.check,
    );
  }

  bool newRolAdded = false;

  Future<void> createRole(
      {required List<Map<String, dynamic>> routes,
      required String type,
      required String name,
      required String clientId}) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    UiMethods().showLoadingDialog(context: globalContext);

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    bool itsOk = await SystemRolesCrud(systemRolesRepositoryImpl).createRole(
      enabledRoutes: routes,
      rolType: type,
      rolName: name,
      clientId: clientId,
    );

    if (!itsOk) {
      UiMethods().hideLoadingDialog(context: globalContext);
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al crear el rol",
        icon: Icons.check,
      );
      return;
    }

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    UiMethods().hideLoadingDialog(context: globalContext);

    newRolAdded = true;

    Navigator.of(globalContext).pop();

    LocalNotificationService.showSnackBar(
      type: "success",
      message: "Rol creado correctamente",
      icon: Icons.check,
    );
  }

  Future<void> deleteRole(
      {required Map<String, dynamic> toDeleteRol,
      required String rolType}) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    bool itsConfirmed = await confirm(
      globalContext,
      title: Text(
        "Eliminar rol",
        style: TextStyle(
          color: UiVariables.primaryColor,
        ),
      ),
      content: RichText(
        text: TextSpan(
          text: '¿Quieres eliminar el rol ',
          children: <TextSpan>[
            TextSpan(
              text: '${toDeleteRol["name"]}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      textCancel: const Text(
        "Cancelar",
        style: TextStyle(color: Colors.grey),
      ),
      textOK: const Text(
        "Aceptar",
        style: TextStyle(color: Colors.blue),
      ),
    );

    if (!itsConfirmed) return;

    UiMethods().showLoadingDialog(context: globalContext);

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    String resp = await SystemRolesCrud(systemRolesRepositoryImpl)
        .deleteRole(toDeleteRol: toDeleteRol, rolType: rolType);

    if (resp == "fail") {
      UiMethods().hideLoadingDialog(context: globalContext);
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al eliminar el rol",
        icon: Icons.check,
      );
      return;
    }

    if (resp == "inUse") {
      UiMethods().hideLoadingDialog(context: globalContext);
      LocalNotificationService.showSnackBar(
        type: "fail",
        message:
            "El rol no puede eliminarse dado que uno o más usuarios lo tienen asignado",
        icon: Icons.check,
        duration: 7,
      );
      return;
    }

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    UiMethods().hideLoadingDialog(context: globalContext);

    newRolAdded = true;

    LocalNotificationService.showSnackBar(
      type: "success",
      message: "Rol eliminado correctamente",
      icon: Icons.check,
    );
  }

  Future<void> deleteHoliday({required Map<String, dynamic> holiday}) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    bool itsConfirmed = await confirm(
      globalContext,
      title: Text(
        "Eliminar festivo",
        style: TextStyle(
          color: UiVariables.primaryColor,
        ),
      ),
      content: RichText(
        text: TextSpan(
          text: '¿Quieres eliminar el día festivo ',
          children: <TextSpan>[
            TextSpan(
              text: '${holiday["name"]}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      textCancel: const Text(
        "Cancelar",
        style: TextStyle(color: Colors.grey),
      ),
      textOK: const Text(
        "Aceptar",
        style: TextStyle(color: Colors.blue),
      ),
    );

    if (!itsConfirmed) return;

    UiMethods().showLoadingDialog(context: globalContext);

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    String resp = await HolidaysCrud(holidayRepositoryImpl)
        .deleteHoliday(holiday: holiday);

    if (resp == "fail") {
      UiMethods().hideLoadingDialog(context: globalContext);
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al eliminar el día festivo",
        icon: Icons.check,
      );
      return;
    }

    if (resp == "inUse") {
      UiMethods().hideLoadingDialog(context: globalContext);
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "El día festivo no puede eliminarse.",
        icon: Icons.check,
        duration: 4,
      );
      return;
    }

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    UiMethods().hideLoadingDialog(context: globalContext);

    newRolAdded = true;

    LocalNotificationService.showSnackBar(
      type: "success",
      message: "Día festivo eliminado correctamente",
      icon: Icons.check,
    );
  }

  Future<void> createHoliday({
    required Map<String, dynamic> newHoliday,
  }) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    UiMethods().showLoadingDialog(context: globalContext);

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    bool itsOk = await HolidaysCrud(holidayRepositoryImpl)
        .createHoliday(newHoliday: newHoliday);

    if (!itsOk) {
      UiMethods().hideLoadingDialog(context: globalContext);
      LocalNotificationService.showSnackBar(
        type: "fail",
        message:
            "Ocurrió un error al crear el día festivo, verifique que ese feriado no exista.",
        icon: Icons.warning,
      );
      return;
    }

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    UiMethods().hideLoadingDialog(context: globalContext);

    LocalNotificationService.showSnackBar(
      type: "success",
      message: "Día festivo creado correctamente",
      icon: Icons.check,
    );
  }

  Future<void> updateHoliday({
    required Map<String, dynamic> newHoliday,
  }) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    UiMethods().showLoadingDialog(context: globalContext);

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    bool itsOk =
        await HolidaysCrud(holidayRepositoryImpl).updateHoliday(newHoliday);

    if (!itsOk) {
      UiMethods().hideLoadingDialog(context: globalContext);
      LocalNotificationService.showSnackBar(
        type: "fail",
        message:
            "La fecha seleccionada para el día festivo pertenece a un día festivo, primero elimine el existente.",
        icon: Icons.check,
      );
      return;
    }

    await Provider.of<GeneralInfoProvider>(globalContext, listen: false)
        .getGeneralInfoOrFail(globalContext);

    UiMethods().hideLoadingDialog(context: globalContext);

    Navigator.of(globalContext).pop();

    LocalNotificationService.showSnackBar(
      type: "success",
      message: "Día festivo actualizado correctamente",
      icon: Icons.check,
    );
  }
}
