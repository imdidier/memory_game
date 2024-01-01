import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/widgets/general/date_time_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/employee_services/employee_services.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';
import '../../domain/entities/employee_entity.dart';
import '../provider/employees_provider.dart';

class LockDialog {
  static Future<void> show(Employee employee) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: EdgeInsets.zero,
            title: _DialogContent(
              employee: employee,
              newStatus: employee.accountInfo.status == 3 ? 1 : 3,
            ),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatefulWidget {
  final Employee employee;
  final int newStatus;
  const _DialogContent({
    required this.employee,
    required this.newStatus,
    Key? key,
  }) : super(key: key);

  @override
  State<_DialogContent> createState() => __DialogContentState();
}

class __DialogContentState extends State<_DialogContent> {
  late ScreenSize screenSize;
  DateTime? unlockDate;
  TextEditingController descriptionController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    return Container(
      width: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          _buildBody(),
          _buildHeader(),
          _buildFooter(),
        ],
      ),
    );
  }

  Container _buildHeader() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: screenSize.blockWidth >= 920 ? 26 : 15,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Bloquear colaborador",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.blockWidth >= 920 ? 18 : 14),
            ),
          ],
        ),
      ),
    );
  }

  SingleChildScrollView _buildBody() {
    return SingleChildScrollView(
      controller: ScrollController(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        margin: EdgeInsets.symmetric(
          vertical: screenSize.height * 0.09,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  "Se bloqueará al colaborador ${CodeUtils.getFormatedName(widget.employee.profileInfo.names, widget.employee.profileInfo.lastNames)}. Este no podrá recibir solicitudes durante el período de bloqueo.",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                _builDescriptionField(),
                const SizedBox(height: 15),
                _buildDateField(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Positioned _buildFooter() {
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
          left: 8.0,
          right: 14.0,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: InkWell(
              onTap: () async {
                if (descriptionController.text.isEmpty) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "Debes agregar la descripción",
                    icon: Icons.error_outline,
                  );
                  return;
                }

                if (unlockDate == null) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "Debes seleccionar la fecha de desbloqueo",
                    icon: Icons.error_outline,
                  );
                  return;
                }

                UiMethods().showLoadingDialog(context: context);
                bool resp = await EmployeeServices.lock(
                    widget.employee.id,
                    unlockDate!,
                    descriptionController.text,
                    CodeUtils.getFormatedName(
                      widget.employee.profileInfo.names,
                      widget.employee.profileInfo.lastNames,
                    ));
                UiMethods().hideLoadingDialog(context: context);
                if (resp) {
                  widget.employee.accountInfo.status = 3;
                  widget.employee.accountInfo.unlockDate = unlockDate!;
                  if (mounted) {
                    Provider.of<EmployeesProvider>(context, listen: false)
                        .updateLocalEmployeeData(widget.employee);
                  }
                  LocalNotificationService.showSnackBar(
                    type: "success",
                    message: "Colaborador bloqueado correctamente",
                    icon: Icons.check_outlined,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } else {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "Ocurrió un error al bloquear el colaborador",
                    icon: Icons.error_outline,
                  );
                }
              },
              child: Container(
                width: 150,
                height: 35,
                decoration: BoxDecoration(
                  color: UiVariables.primaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "Aceptar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              )),
        ),
      ),
    );
  }

  Column _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Fecha de desbloqueo",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        InkWell(
          onTap: () async {
            unlockDate = await DateTimePickerDialog.show(
              screenSize,
              true,
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                00,
                00,
              ),
              null,
              maxDaysFromStart: 365,
            );

            if (unlockDate == null) return;

            if (unlockDate!.isBefore(DateTime.now())) {
              LocalNotificationService.showSnackBar(
                type: "Fail",
                message:
                    "La fecha de desbloqueo debe ser mayor a la fecha actual",
                icon: Icons.error_outline,
              );
              return;
            }

            setState(() {});
          },
          child: Container(
            height: 50,
            width: double.infinity,
            margin: EdgeInsets.only(
              top: screenSize.height * 0.01,
              bottom: screenSize.height * 0.02,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: UiVariables.lightBlueColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                unlockDate != null
                    ? CodeUtils.formatDate(unlockDate!)
                    : "Elegir fecha",
                style: TextStyle(
                  fontSize: 15,
                  color: unlockDate != null
                      ? Colors.black
                      : UiVariables.primaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Column _builDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Descripción del bloqueo",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Container(
          height: 50,
          width: double.infinity,
          margin: EdgeInsets.only(
            top: screenSize.height * 0.01,
            bottom: screenSize.height * 0.02,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                offset: Offset(0, 2),
                color: Colors.black26,
                blurRadius: 2,
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              keyboardType: TextInputType.text,
              controller: descriptionController,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
