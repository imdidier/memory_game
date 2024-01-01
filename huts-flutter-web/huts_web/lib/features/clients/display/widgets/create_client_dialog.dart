import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/features/admins/display/providers/admin_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import 'dropdwon_button.dart';

class CreateClientDialog extends StatefulWidget {
  final ScreenSize screenSize;

  const CreateClientDialog({
    required this.screenSize,
    Key? key,
  }) : super(key: key);

  @override
  State<CreateClientDialog> createState() => _CreateClientDialogState();
}

class _CreateClientDialogState extends State<CreateClientDialog> {
  bool isScreenLoaded = false;

  late ClientsProvider clientsProvider;
  late AdminProvider adminProvider;
  late GeneralInfoProvider generalInfoProvider;

  late ClientEntity client;
  TextEditingController clientNameController = TextEditingController();
  TextEditingController clientEmailController = TextEditingController();
  TextEditingController clientDescriptionController = TextEditingController();
  TextEditingController clientPasswordController = TextEditingController();

  List<Map<String, dynamic>> countries = [
    {"name": "Costa Rica", "key": "CR"},
    {"name": "Colombia", "key": "CO"},
  ];

  Map<String, dynamic> selectedCountry = {"name": "Costa Rica", "key": "CR"};

  bool isShowingPassword = false;

  late ScreenSize screenSize;
  bool isAdmin = false;

  bool imageAvailable = false;
  Uint8List? imageFile;

  bool isDesktop = false;

  int selectedTab = 0;
  @override
  void didChangeDependencies() {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    clientsProvider = Provider.of<ClientsProvider>(context);
    adminProvider = Provider.of<AdminProvider>(context);
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;

    isDesktop = screenSize.width >= 1120;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      width: widget.screenSize.blockWidth * 0.3,
      height: widget.screenSize.height * 0.8,
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.only(
              top: widget.screenSize.height * 0.08,
              left: widget.screenSize.blockWidth * 0.04,
              right: widget.screenSize.blockWidth * 0.04,
            ),
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: widget.screenSize.blockWidth * 0.7,
              height: widget.screenSize.height * 0.7,
              child: buildInfoRegistredClient(),
            ),
          ),
          buildHeader(),
        ],
      ),
    );
  }

  Align buildAddPhotoBtn() {
    return Align(
      alignment: Alignment.center,
      child: InkWell(
        onTap: () async {
          final image =
              (await FilePicker.platform.pickFiles(type: FileType.image));
          if (image == null) return;
          setState(() {
            imageFile = image.files.first.bytes;
            imageAvailable = true;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(top: 15),
          width: screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.12
              : screenSize.blockWidth * 0.35,
          height: screenSize.height * 0.035,
          decoration: BoxDecoration(
            color: UiVariables.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Seleccionar foto",
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.screenSize.blockWidth >= 920
                    ? widget.screenSize.width * 0.011
                    : 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> validateFields() async {
    try {
      if (imageFile == null) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Seleccione una foto",
          icon: Icons.error_outline,
        );
        return;
      }
      if (clientNameController.text.isEmpty) {
        LocalNotificationService.showSnackBar(
          type: "fails",
          message: "Debes agregar el nombre del cliente",
          icon: Icons.error_outline,
        );
        return;
      }
      UiMethods().showLoadingDialog(context: context);

      String temporalyId = FirebaseServices.db.collection('clients').doc().id;

      TaskSnapshot uploadTask =
          await FirebaseStorage.instance.ref('web_users/$temporalyId/').putData(
                imageFile!,
                SettableMetadata(contentType: 'image/jpeg'),
              );
      String imageUrl = await uploadTask.ref.getDownloadURL();

      bool resp = false;
      Map<String, dynamic> clientCreate = {
        "country": selectedCountry['name'],
        "description": clientDescriptionController.text,
        "name": clientNameController.text,
        "email": "",
        "image": imageUrl,
        "account_info": Map<String, dynamic>.from(
          {
            "has_dynamic_fare": false,
            "id": temporalyId,
            "min_request_hours": 4,
            "status": 1,
            "total_requests": 0,
            "total_requests_ended": 0
          },
        ),
        "blocked_employees": Map<String, dynamic>.from({}),
        "web_users": Map<String, dynamic>.from({}),
        "favorites": Map<String, dynamic>.from({}),
        "jobs": Map<String, dynamic>.from({}),
        "legal_info": Map<String, dynamic>.from(
          {
            "company_legal_id": '',
            "email": '',
            "legal_representative": '',
            "legal_representative_document": '',
            "phone": ''
          },
        ),
        "location": Map<String, dynamic>.from(
          {
            "address": '',
            "city": '',
            "state": '',
            "country": '',
            "district": '',
            "position": const GeoPoint(9.9355151, -84.2568767)
          },
        ),
      };
      resp = await clientsProvider.addClient(client: clientCreate);

      UiMethods().hideLoadingDialog(context: context);

      if (!resp) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al crear la información del cliente",
          icon: Icons.error_outline,
        );
        return;
      }

      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Listo, cliente creado correctamente",
        icon: Icons.check,
      );
      clearFields();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (kDebugMode) {
        print("CreateClientDialog, validateFields error: $e");
      }
      UiMethods().hideLoadingDialog(context: context);
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al crear la información del cliente",
        icon: Icons.error_outline,
      );
      return;
    }
  }

  void clearFields() {
    clientNameController.clear();
    clientEmailController.clear();
    clientDescriptionController.clear();
    imageFile = null;
    imageAvailable = false;
    setState(() {});
    LocalNotificationService.showSnackBar(
      type: "success",
      message: "Campos limpios",
      icon: Icons.check,
    );
  }

  SizedBox buildInfoRegistredClient() {
    return SizedBox(
      width: widget.screenSize.blockWidth * 0.6,
      height: widget.screenSize.height * 0.7,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Información",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: widget.screenSize.width * 0.016,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              "Información general del cliente",
              style: TextStyle(
                color: Colors.black54,
                fontSize: widget.screenSize.width * 0.01,
              ),
            ),
            const SizedBox(height: 15),
            Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: isDesktop
                      ? widget.screenSize.width * 0.13
                      : widget.screenSize.width * 0.1,
                  height: isDesktop
                      ? widget.screenSize.height * 0.13
                      : widget.screenSize.height * 0.1,
                  child: imageAvailable
                      ? ClipOval(
                          child: SizedBox(
                            width: widget.screenSize.blockWidth >= 920
                                ? widget.screenSize.width * 0.13
                                : widget.screenSize.blockWidth * 0.25,
                            height: widget.screenSize.blockWidth >= 920
                                ? widget.screenSize.height * 0.13
                                : widget.screenSize.blockWidth * 0.25,
                            child: Image.memory(
                              imageFile!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.panorama_outlined,
                            color: Colors.grey[300],
                            size:
                                widget.screenSize.blockWidth >= 920 ? 150 : 100,
                          ),
                        ),
                ),
                const SizedBox(
                  height: 5,
                ),
                buildAddPhotoBtn(),
              ],
            ),
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowSpacing: 5,
              children: [
                const SizedBox(height: 20),
                buildTextField(
                  "Nombre del cliente",
                  clientNameController,
                  TextInputType.name,
                  false,
                ),
                const SizedBox(height: 10),
                buildTextField(
                  "Descripción",
                  clientDescriptionController,
                  TextInputType.text,
                  false,
                ),
                const SizedBox(height: 20),

                DropDwonButton(
                  text: 'Seleccione el país',
                  itemsSelected: countries,
                  isCountry: true,
                  screenSize: screenSize,
                ),
                // buildTextField(
                //   "Correo electrónico",
                //   clientEmailController,
                //   TextInputType.emailAddress,
                //   false,
                // ),
              ],
            ),
            // const SizedBox(
            //   height: 10,
            // ),
            // OverflowBar(
            //   alignment: MainAxisAlignment.spaceBetween,
            //   overflowSpacing: 5,
            //   children: [
            //     // buildTextField("Descripción", clientDescriptionController,
            //     //     TextInputType.text, false),
            //     Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         DropDwonButton(
            //             text: 'Seleccione el país',
            //             itemsSelected: countries,
            //             isCountry: true,
            //             screenSize: screenSize),
            //       ],
            //     ),
            //   ],
            // ),
            // const SizedBox(
            //   height: 10,
            // ),
            // OverflowBar(
            //   alignment: MainAxisAlignment.center,
            //   children: [
            //     buildTextField('Contraseña', clientPasswordController,
            //         TextInputType.none, true),
            //   ],
            // ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: UiVariables.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: widget.screenSize.width * 0.018,
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: () {
                  clearFields();
                },
                child: Text(
                  "Limpiar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.screenSize.blockWidth >= 920
                        ? widget.screenSize.width * 0.011
                        : 14,
                  ),
                ),
              ),
              const SizedBox(width: 30),
              InkWell(
                onTap: () async =>
                    (clientsProvider.isLoading) ? null : await validateFields(),
                child: Text(
                  "Crear Cliente",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.screenSize.blockWidth >= 920
                        ? widget.screenSize.width * 0.011
                        : 14,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Container buildTextField(String text, TextEditingController controller,
      TextInputType inputType, bool isPassword) {
    return Container(
      margin: const EdgeInsets.only(top: 10, right: 10),
      width: screenSize.blockWidth >= 920
          ? screenSize.blockWidth * 0.28
          : screenSize.blockWidth,
      height: screenSize.blockWidth >= 920
          ? screenSize.height * 0.055
          : screenSize.height * 0.05,
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
        obscureText: isPassword ? !isShowingPassword : false,
        keyboardType: inputType,
        controller: controller,
        cursorColor: UiVariables.primaryColor,
        style: TextStyle(
          color: Colors.black87,
          fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
        ),
        decoration: InputDecoration(
          hintText: text,
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
          ),
          suffix: isPassword
              ? InkWell(
                  onTap: () {
                    setState(() {
                      isShowingPassword = !isShowingPassword;
                    });
                  },
                  child: Icon(
                    isShowingPassword
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline,
                    color: UiVariables.primaryColor,
                  ),
                )
              : const SizedBox(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}
