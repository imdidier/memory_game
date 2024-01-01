import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/core/services/employee_services/employee_services.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_variables.dart';

class ChangePhoneDialog {
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
            title: _DialogContent(employee: employee),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatefulWidget {
  final Employee employee;
  const _DialogContent({required this.employee, Key? key}) : super(key: key);

  @override
  State<_DialogContent> createState() => __DialogContentState();
}

class __DialogContentState extends State<_DialogContent> {
  late ScreenSize screenSize;
  TextEditingController phoneController = TextEditingController();
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
              "Cambiar teléfono colaborador",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.blockWidth >= 920 ? 18 : 14),
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
                if (phoneController.text.isEmpty) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "Debes agregar el nuevo número",
                    icon: Icons.error_outline,
                  );
                  return;
                }
                if (phoneController.text.isEmpty) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "Debes agregar el nuevo número",
                    icon: Icons.error_outline,
                  );
                  return;
                }
                if (phoneController.text.length < 8) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "El número ingresado está incompleto",
                    icon: Icons.error_outline,
                  );
                  return;
                }

                if (phoneController.text == widget.employee.profileInfo.phone) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "El nuevo número debe ser diferente al anterior",
                    icon: Icons.error_outline,
                  );
                  return;
                }

                UiMethods().showLoadingDialog(context: context);
                bool resp = await EmployeeServices.changePhoneNumber(
                  {
                    "uid": widget.employee.id,
                    "employee_name": CodeUtils.getFormatedName(
                      widget.employee.profileInfo.names,
                      widget.employee.profileInfo.lastNames,
                    ),
                    "current_phone": widget.employee.profileInfo.phone,
                    "phone": phoneController.text.trim(),
                    "prefix": "+506"
                  },
                  context,
                );
                UiMethods().hideLoadingDialog(context: context);
                if (resp) {
                  widget.employee.profileInfo.phone = phoneController.text;
                  if (mounted) {
                    Provider.of<EmployeesProvider>(context, listen: false)
                        .updateLocalEmployeeData(widget.employee);
                  }
                  LocalNotificationService.showSnackBar(
                    type: "success",
                    message: "Número modificado correctamente",
                    icon: Icons.check_outlined,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } else {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "Ocurrió un error al cambiar el número",
                    icon: Icons.error_outline,
                  );
                }
              },
              child: Container(
                width: screenSize.blockWidth > 920 ? 150 : 150,
                height:
                    screenSize.blockWidth > 920 ? 35 : screenSize.height * 0.03,
                decoration: BoxDecoration(
                  color: UiVariables.primaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Guardar cambios",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: screenSize.blockWidth >= 920 ? 15 : 12),
                  ),
                ),
              )),
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
            const SizedBox(height: 15),
            _builEmployeeName(),
            const SizedBox(height: 15),
            _buildEmployeeCurrentPhone(),
            const SizedBox(height: 15),
            _buildNewPhoneFieldField(),
          ],
        ),
      ),
    );
  }

  Column _builEmployeeName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nombre colaborador",
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
            child: Text(
              "${widget.employee.profileInfo.names} ${widget.employee.profileInfo.lastNames}",
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Column _buildEmployeeCurrentPhone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Teléfono actual",
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
            child: Text(
              widget.employee.profileInfo.phone,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Column _buildNewPhoneFieldField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nuevo teléfono",
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
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                FilteringTextInputFormatter.digitsOnly
              ],
              controller: phoneController,
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
