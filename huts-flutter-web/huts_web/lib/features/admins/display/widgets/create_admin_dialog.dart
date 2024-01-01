import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/admins/display/providers/admin_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../auth/domain/entities/web_user_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';

class CreateAdminDialog {
  static Future<void> show({WebUser? adminToEdit}) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;

    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (_) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: EdgeInsets.zero,
            title: _DialogContent(adminToEdit: adminToEdit),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatefulWidget {
  final WebUser? adminToEdit;
  const _DialogContent({required this.adminToEdit, Key? key}) : super(key: key);

  @override
  State<_DialogContent> createState() => __DialogContentState();
}

class __DialogContentState extends State<_DialogContent> {
  bool isWidgetLoaded = false;
  late ScreenSize screenSize;
  TextEditingController namesController = TextEditingController();
  TextEditingController lastNamesController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isShowingPass = false;
  Map<String, dynamic> selectedType = {"name": "Administrador", "key": "admin"};

  List<Map<String, dynamic>> adminTypes = [];

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;

    context
        .read<GeneralInfoProvider>()
        .otherInfo
        .systemRoles["admin"]
        .forEach((key, value) {
      adminTypes.add({
        "name": value["name"],
        "key": value["value"],
      });
    });

    if (widget.adminToEdit != null) {
      namesController.text = widget.adminToEdit!.profileInfo.names;
      lastNamesController.text = widget.adminToEdit!.profileInfo.lastNames;
      emailController.text = widget.adminToEdit!.profileInfo.email;
      phoneController.text = widget.adminToEdit!.profileInfo.phone;
      selectedType = adminTypes.firstWhere(
        (element) => element["key"] == widget.adminToEdit!.accountInfo.subtype,
      );
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    return Container(
      width: screenSize.blockWidth * 0.6,
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
                size: screenSize.width * 0.018,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              (widget.adminToEdit != null)
                  ? "Editar administrador"
                  : "Agregar nuevo admin a Huts",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenSize.blockWidth >= 920
                    ? screenSize.width * 0.011
                    : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildBody() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      margin: EdgeInsets.symmetric(
        vertical: screenSize.height * 0.09,
      ),
      height: 320,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            _buildNamesFields(),
            _buildContactFields(),
            _buildPassTypeFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildNamesFields() {
    return OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      overflowSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nombres",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Container(
              height: 50,
              width: screenSize.blockWidth >= 920
                  ? screenSize.blockWidth * 0.26
                  : screenSize.blockWidth,
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
                  controller: namesController,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Apellidos",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Container(
              height: 50,
              width: screenSize.blockWidth >= 920
                  ? screenSize.blockWidth * 0.26
                  : screenSize.blockWidth,
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
                  controller: lastNamesController,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildContactFields() {
    return OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      overflowSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Correo",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Container(
              height: 50,
              width: screenSize.blockWidth >= 920
                  ? screenSize.blockWidth * 0.26
                  : screenSize.blockWidth,
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
                  controller: emailController,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Teléfono",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Container(
              height: 50,
              width: screenSize.blockWidth >= 920
                  ? screenSize.blockWidth * 0.26
                  : screenSize.blockWidth,
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
            )
          ],
        )
      ],
    );
  }

  Widget _buildPassTypeFields() {
    return OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      overflowSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contraseña",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Container(
              height: 50,
              width: screenSize.blockWidth >= 920
                  ? screenSize.blockWidth * 0.26
                  : screenSize.blockWidth,
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
                  obscureText: !isShowingPass,
                  controller: passwordController,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    suffix: InkWell(
                      onTap: () {
                        setState(() {
                          isShowingPass = !isShowingPass;
                        });
                      },
                      child: Icon(
                        isShowingPass
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline,
                        color: UiVariables.primaryColor,
                      ),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tipo",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Container(
              height: 50,
              width: screenSize.blockWidth >= 920
                  ? screenSize.blockWidth * 0.26
                  : screenSize.blockWidth,
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
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text(
                    "Selecciona un tipo",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  menuMaxHeight: 300,
                  underline: const SizedBox(),
                  value: selectedType["name"],
                  items: adminTypes
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e["name"],
                          child: Text(
                            e["name"],
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedType = adminTypes.firstWhere(
                        (element) => element["name"] == value,
                      );
                    });
                  },
                ),
              ),
            )
          ],
        )
      ],
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
              if (namesController.text.isEmpty ||
                  lastNamesController.text.isEmpty) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes agregar los nombres y apellidos",
                  icon: Icons.error_outline,
                );
                return;
              }
              if (emailController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes agregar el correo y el teléfono",
                  icon: Icons.error_outline,
                );
                return;
              }

              String email = emailController.text.toLowerCase().trim();

              if (!CodeUtils.checkValidEmail(email)) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes agregar un correo válido",
                  icon: Icons.error_outline,
                );
                return;
              }

              if (widget.adminToEdit == null &&
                  passwordController.text.length < 6) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "La contraseña debe tener mínimo 6 caracteres",
                  icon: Icons.error_outline,
                );
                return;
              }

              if (widget.adminToEdit != null &&
                  passwordController.text.isNotEmpty &&
                  passwordController.text.length < 6) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "La contraseña debe tener mínimo 6 caracteres",
                  icon: Icons.error_outline,
                );
                return;
              }

              AdminProvider provider =
                  Provider.of<AdminProvider>(context, listen: false);

              if (widget.adminToEdit != null) {
                await provider.editAdmin(
                  {
                    "user_info": {
                      "subtype": selectedType["key"],
                      "email": email,
                      "names": namesController.text,
                      "last_names": lastNamesController.text,
                      "phone": phoneController.text,
                    },
                    "password": passwordController.text,
                    "update_auth": emailController.text !=
                            widget.adminToEdit!.profileInfo.email ||
                        passwordController.text.isNotEmpty,
                    "update_email": emailController.text !=
                        widget.adminToEdit!.profileInfo.email,
                    "id": widget.adminToEdit!.uid,
                  },
                  true,
                );
                return;
              }

              await provider.createAdmin(
                {
                  "account_info": {
                    "company_id": "",
                    "creation_date": "",
                    "enabled": true,
                    "type": "admin",
                    "subtype": selectedType["key"]
                  },
                  "profile_info": {
                    "country_prefix": "CR",
                    "email": email,
                    "image": "",
                    "names": namesController.text,
                    "last_names": lastNamesController.text,
                    "phone": phoneController.text,
                  },
                  "password": passwordController.text,
                },
              );
            },
            child: Container(
              width: 150,
              height: 35,
              decoration: BoxDecoration(
                color: UiVariables.primaryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  (widget.adminToEdit != null)
                      ? "Guardar cambios"
                      : "Crear admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
