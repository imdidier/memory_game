import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/code/code_utils.dart';

class ClientGeneralInfo extends StatefulWidget {
  final ClientsProvider clientsProvider;
  final ScreenSize screenSize;
  const ClientGeneralInfo({
    Key? key,
    required this.clientsProvider,
    required this.screenSize,
  }) : super(key: key);

  @override
  State<ClientGeneralInfo> createState() => _ClientGeneralInfoState();
}

class _ClientGeneralInfoState extends State<ClientGeneralInfo> {
  late ScreenSize screenSize;
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController minRequestController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isShowingPass = false;

  @override
  void initState() {
    nameController.text = widget.clientsProvider.selectedClient!.name;
    phoneController.text =
        widget.clientsProvider.selectedClient!.legalInfo.phone;
    emailController.text = widget.clientsProvider.selectedClient!.email;
    minRequestController.text = widget
        .clientsProvider.selectedClient!.accountInfo.minRequestHours
        .toString();
    super.initState();
  }

  bool clientToEdit = false;

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Información",
            style: TextStyle(
                color: Colors.black,
                fontSize: screenSize.width * 0.016,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            "Información general del cliente",
            style: TextStyle(
              color: Colors.black54,
              fontSize: screenSize.width * 0.01,
            ),
          ),
          const SizedBox(height: 20),
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowSpacing: 10,
            children: [
              buildTextField('Nombre de la compañía', nameController),
              buildTextField('Correo de la compañía', emailController),
              buildTextField('Teléfono', phoneController),
            ],
          ),
          const SizedBox(height: 35),
          OverflowBar(
            alignment: MainAxisAlignment.center,
            overflowSpacing: 10,
            spacing: 20,
            children: [
              buildTextField('Número de horas mínimo por solicitud',
                  minRequestController, true),
              // _buildPassTypeFields()
            ],
          ),
          buildUpdateBtn()
        ],
      ),
    );
  }

  Column _buildPassTypeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contraseña",
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
            color: Colors.black54,
          ),
        ),
        Container(
          height: screenSize.blockWidth >= 920
              ? screenSize.height * 0.055
              : screenSize.height * 0.035,
          width: screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.24
              : screenSize.width,
          margin: const EdgeInsets.only(top: 10, right: 10),
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
          child: TextField(
            obscureText: !isShowingPass,
            controller: passwordController,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              suffix: InkWell(
                onTap: () {
                  setState(
                    () {
                      isShowingPass = !isShowingPass;
                    },
                  );
                },
                child: Icon(
                  isShowingPass ? Icons.lock_open_rounded : Icons.lock_outline,
                  color: UiVariables.primaryColor,
                ),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Column buildTextField(String text, TextEditingController controller,
      [bool isMinRequest = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
            color: Colors.black54,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10, right: 10),
          width: screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.24
              : screenSize.width,
          height: screenSize.blockWidth >= 920
              ? screenSize.height * 0.055
              : screenSize.height * 0.035,
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
          child: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              isMinRequest
                  ? FilteringTextInputFormatter.digitsOnly
                  : FilteringTextInputFormatter.singleLineFormatter
            ],
            controller: controller,
            cursorColor: UiVariables.primaryColor,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            maxLength: isMinRequest ? 1 : 300,
            decoration: InputDecoration(
              hintText: text,
              hintStyle: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
              counterText: '',
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Align buildUpdateBtn() {
    return Align(
      alignment: screenSize.blockWidth > 920
          ? Alignment.centerRight
          : Alignment.center,
      child: InkWell(
        onTap: () async =>
            (widget.clientsProvider.isLoading) ? null : await validateFields(),
        child: Container(
          margin: const EdgeInsets.only(top: 30),
          width:
              screenSize.blockWidth > 1194 ? screenSize.blockWidth * 0.1 : 150,
          height: screenSize.blockWidth > 920
              ? screenSize.height * 0.055
              : screenSize.height * 0.035,
          decoration: BoxDecoration(
            color: UiVariables.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Guardar cambios",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> validateFields() async {
    // passwordController.text.isNotEmpty
    //     ? clientToEdit = true
    //     : clientToEdit = false;

    bool emptyFields = false;

    // if (emailController.text.isEmpty) emptyFields = true;
    if (nameController.text.isEmpty) emptyFields = true;
    // if (phoneController.text.isEmpty) emptyFields = true;
    if (minRequestController.text.isEmpty) emptyFields = true;

    if (emptyFields) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Debes llenar todos los campos",
        icon: Icons.error_outline,
      );
      return;
    }

    String email = emailController.text.toLowerCase().trim();
    if (!CodeUtils.checkValidEmail(email) && email.isNotEmpty) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Debes agregar un correo válido",
        icon: Icons.error_outline,
      );
      return;
    }
    // if (clientToEdit == true && email.isNotEmpty) {
    // if (passwordController.text.length < 6) {
    //   LocalNotificationService.showSnackBar(
    //     type: "fail",
    //     message: "La contraseña debe tener mínimo 6 caracteres",
    //     icon: Icons.error_outline,
    //   );
    //   return;
    // }

    // AdminProvider adminProvider =
    //     Provider.of<AdminProvider>(context, listen: false);

    // await adminProvider.editAdmin(
    //   {
    //     "user_info": {
    //       "subtype": "admin",
    //       "type": "client",
    //       "email": email,
    //       "names": nameController.text,
    //       "last_names": '',
    //       "phone": phoneController.text,
    //     },
    //     "password": passwordController.text,
    //     "update_auth": emailController.text !=
    //             widget.clientsProvider.selectedClient!.email ||
    //         passwordController.text.isNotEmpty,
    //     "update_email": emailController.text !=
    //         widget.clientsProvider.selectedClient!.email,
    //     "uid": widget.clientsProvider.selectedClient!.accountInfo.id,
    //   },
    // );

    // }
    await widget.clientsProvider.updateClientInfo(
      {
        "name": nameController.text,
        "phone": phoneController.text,
        "minRequestHours": int.parse(minRequestController.text),
        "email": email
      },
      "general",
      true,
    );
  }
}
