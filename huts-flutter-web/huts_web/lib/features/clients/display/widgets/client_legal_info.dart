import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/code/code_utils.dart';

class ClientLegalInfo extends StatefulWidget {
  final ClientsProvider clientsProvider;
  final ScreenSize screenSize;

  const ClientLegalInfo({
    Key? key,
    required this.clientsProvider,
    required this.screenSize,
  }) : super(key: key);

  @override
  State<ClientLegalInfo> createState() => _ClientLegalInfo();
}

class _ClientLegalInfo extends State<ClientLegalInfo> {
  late ScreenSize screenSize;
  TextEditingController nameLegalRepresentativeController =
      TextEditingController();
  TextEditingController emailLegalRepresentativeController =
      TextEditingController();
  TextEditingController documentLegalRepresentativeController =
      TextEditingController();

  @override
  void initState() {
    nameLegalRepresentativeController.text =
        widget.clientsProvider.selectedClient!.legalInfo.legalRepresentative;

    emailLegalRepresentativeController.text =
        widget.clientsProvider.selectedClient!.legalInfo.email;
    documentLegalRepresentativeController.text = widget
        .clientsProvider.selectedClient!.legalInfo.legalRepresentativeDocument;

    super.initState();
  }

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
              "Información legal del cliente",
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
                buildTextField('Nombre del representante legal',
                    nameLegalRepresentativeController),
                buildTextField('Documento del representante legal',
                    documentLegalRepresentativeController),
                buildTextField('Correo del representante legal',
                    emailLegalRepresentativeController),
              ],
            ),
            buildUpdateBtn()
          ],
        ));
  }

  Column buildTextField(
    String text,
    TextEditingController controller,
  ) {
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
            controller: controller,
            cursorColor: UiVariables.primaryColor,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: text,
              hintStyle: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
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
    if (nameLegalRepresentativeController.text.isEmpty ||
        emailLegalRepresentativeController.text.isEmpty ||
        documentLegalRepresentativeController.text.isEmpty) {
      LocalNotificationService.showSnackBar(
        type: "fails",
        message: "Debes llenar todos los campos",
        icon: Icons.error_outline,
      );
      return;
    }
    String email = emailLegalRepresentativeController.text.toLowerCase().trim();
    if (!CodeUtils.checkValidEmail(email)) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Debes agregar un correo válido",
        icon: Icons.error_outline,
      );
      return;
    }
    UiMethods().showLoadingDialog(context: context);
    await widget.clientsProvider.updateClientInfo(
      {
        "legal_representative": nameLegalRepresentativeController.text,
        "email": emailLegalRepresentativeController.text,
        "legal_representative_document":
            documentLegalRepresentativeController.text,
      },
      "legal_info",
    );
    UiMethods().hideLoadingDialog(context: context);
  }
}
