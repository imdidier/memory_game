import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/client_services/client_services.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../core/utils/code/code_utils.dart';
import '../../../../admins/display/providers/admin_provider.dart';
import '../../../../auth/data/models/web_user_model.dart';
import '../../../../auth/display/providers/auth_provider.dart';
import '../../../../auth/domain/entities/web_user_entity.dart';
import '../../provider/clients_provider.dart';
import '../../provider/user_provider.dart';
import '../../../../../core/services/local_notification_service.dart';
import '../../../../../core/utils/ui/ui_methods.dart';
import '../../../../../core/utils/ui/ui_variables.dart';
//import '../dropdwon_button.dart';

class DialogContentWebUser extends StatefulWidget {
  final ScreenSize screenSize;
  final Map<String, dynamic>? userToEdit;
  const DialogContentWebUser({
    super.key,
    required this.screenSize,
    this.userToEdit,
  });

  @override
  State<DialogContentWebUser> createState() => _DialogContentWebUserState();
}

class _DialogContentWebUserState extends State<DialogContentWebUser> {
  bool isScreenLoaded = false;
  late ClientsProvider clientsProvider;
  late UsersProvider webUserProvider;
  late AdminProvider adminProvider;
  late AuthProvider authProvider;
  late GeneralInfoProvider generalInfoProvider;

  late WebUserModel webUser;
  late WebUser user;

  TextEditingController webUserNameController = TextEditingController();
  TextEditingController webUserLastNameController = TextEditingController();
  TextEditingController webUserTypeController = TextEditingController();

  TextEditingController webUserEmailController = TextEditingController();
  TextEditingController webUserPhoneController = TextEditingController();
  TextEditingController webUserPasswordController = TextEditingController();

  bool isShowingPassword = false;

  Map<String, dynamic> selectedCountry = {"name": "Costa Rica", "key": "CR"};

  List<Map<String, dynamic>> countries = [
    {"name": "Costa Rica", "key": "CR"},
    {"name": "Colombia", "key": "CO"},
  ];

  Map<String, dynamic> selectedSubtype = {
    "name": "Operaciones",
    "key": "operations",
  };

  Map<String, dynamic> clientType = {"name": "Cliente", "key": "client"};

  List<Map<String, dynamic>> clientSubtypes = [];

  late ScreenSize screenSize;
  bool isAdmin = false;

  bool imageAvailable = false;
  Uint8List? imageFile;
  bool isDesktop = false;

  @override
  void didChangeDependencies() async {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    clientsProvider = Provider.of<ClientsProvider>(context);
    webUserProvider = Provider.of<UsersProvider>(context);
    adminProvider = Provider.of<AdminProvider>(context);
    authProvider = Provider.of<AuthProvider>(context);
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    user = authProvider.webUser;
    isAdmin = user.accountInfo.type == "admin";

    if (webUserProvider.selectedUser == null) {
      webUserNameController.text = '';
      webUserLastNameController.text = '';
      webUserEmailController.text = '';
      webUserPhoneController.text = '';
      webUserTypeController.text = clientType['name'];
    } else {
      webUserNameController.text = webUser.profileInfo.names;
      webUserLastNameController.text = webUser.profileInfo.lastNames;
      webUserEmailController.text = webUser.profileInfo.email;
      webUserPhoneController.text = webUser.profileInfo.phone;
      webUserTypeController.text = CodeUtils.getWebUserSubtypeName(
        webUser.accountInfo.type,
        type: "client",
      );
    }

    generalInfoProvider.otherInfo.systemRoles["client"].forEach(
      (key, value) {
        clientSubtypes.add({"name": value["name"], "key": key});
      },
    );

    if (widget.userToEdit != null) {
      webUserNameController.text =
          widget.userToEdit!["full_name"].split(" ")[0];
      webUserLastNameController.text =
          widget.userToEdit!["full_name"].split(" ")[1];
      webUserEmailController.text = widget.userToEdit!["email"];
      webUserPhoneController.text = widget.userToEdit!["phone"];
      webUserTypeController.text = "Cliente";

      selectedSubtype = {
        "name": generalInfoProvider.otherInfo.systemRoles["client"]
            [widget.userToEdit!["subtype"]]["name"],
        "key": generalInfoProvider.otherInfo.systemRoles["client"]
            [widget.userToEdit!["subtype"]]["value"],
      };

      //  CodeUtils.getWebUserSubtypeName(widget.userToEdit!["subtype"]);
    }

    imageFile = null;
    imageAvailable = false;

    await doSetState();

    super.didChangeDependencies();
  }

  Future<void> doSetState() async {
    await Future.delayed(const Duration(seconds: 1), () {});
    if (!mounted) doSetState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    adminProvider = Provider.of<AdminProvider>(context);
    isDesktop = screenSize.width >= 1120;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      width: screenSize.blockWidth >= 920
          ? screenSize.blockWidth * 0.7
          : screenSize.blockWidth * 0.8,
      height: screenSize.height * 0.8,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.only(
                top: screenSize.height * 0.05,
                left: screenSize.blockWidth * 0.05,
                right: screenSize.blockWidth * 0.05,
              ),
              width: screenSize.blockWidth >= 920
                  ? screenSize.blockWidth * 0.7
                  : screenSize.blockWidth * 0.8,
              height: screenSize.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildInfoRegistredWebUser(),
                ],
              ),
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
          margin: const EdgeInsets.only(top: 15, bottom: 50),
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
              "Seleccionar archivo",
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
              if (widget.userToEdit == null)
                InkWell(
                  onTap: () => clearFields(),
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
              if (widget.userToEdit == null) const SizedBox(width: 30),
              if (widget.userToEdit == null)
                InkWell(
                  onTap: () async {
                    await validateFields();
                  },
                  child: Text(
                    "Crear Usuario",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.screenSize.blockWidth >= 920
                          ? widget.screenSize.width * 0.011
                          : 14,
                    ),
                  ),
                ),
              if (widget.userToEdit != null)
                InkWell(
                  onTap: () async {
                    UiMethods().showLoadingDialog(context: context);
                    Map<String, dynamic>? updateData =
                        await validateEditFields();

                    if (updateData == null) {
                      UiMethods().hideLoadingDialog(context: context);
                      // LocalNotificationService.showSnackBar(
                      //   type: "fail",
                      //   message: "Ocurrió un error al validar los campos",
                      //   icon: Icons.error_outline,
                      // );
                      return;
                    }

                    bool itsOk = await ClientServices.updateClientUser(
                      updateData: updateData,
                    );

                    if (!itsOk) {
                      UiMethods().hideLoadingDialog(context: context);
                      LocalNotificationService.showSnackBar(
                        type: "fail",
                        message:
                            "Ocurrió un error al actualizar la información",
                        icon: Icons.error_outline,
                      );
                      return;
                    }
                    UiMethods().hideLoadingDialog(context: context);
                    String fullName = CodeUtils.getFormatedName(
                        webUserNameController.text,
                        webUserLastNameController.text);
                    await clientsProvider.updateClientInfo(
                      {
                        "action": "edit",
                        "employee": {
                          "full_name": fullName,
                          "phone": webUserPhoneController.text,
                          "image": widget.userToEdit!["image"],
                          "email": webUserEmailController.text,
                          "uid": widget.userToEdit!['uid'],
                          "type": widget.userToEdit!['type'],
                          "subtype": selectedSubtype['key'],
                          "enable": widget.userToEdit!['enable'],
                        },
                      },
                      "web_users",
                      isAdmin,
                      authProvider.webUser,
                    );
                    LocalNotificationService.showSnackBar(
                      type: "success",
                      message: "Usuario actualizado correctamente",
                      icon: Icons.check,
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    "Guardar cambios",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.screenSize.blockWidth >= 920
                          ? widget.screenSize.width * 0.011
                          : 14,
                    ),
                  ),
                )
            ],
          )
        ],
      ),
    );
  }

  SizedBox buildInfoRegistredWebUser() {
    return SizedBox(
      width: screenSize.blockWidth * 0.7,
      height: screenSize.height * 0.85,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 30,
            ),
            Text(
              (widget.userToEdit == null)
                  ? "Completa la información para crear un usuario"
                  : "Edita la información del usuario del cliente",
              style: TextStyle(
                color: Colors.black,
                fontSize: screenSize.blockWidth >= 920
                    ? screenSize.width * 0.016
                    : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            buildPhotoWidget(),
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowSpacing: 6,
              children: [
                buildTextField(webUserNameController, 'Nombre', false, false),
                buildTextField(
                    webUserLastNameController, 'Apellidos', false, false),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowSpacing: 6,
              children: [
                buildTextField(
                    webUserEmailController, 'Correo electrónico', false, false),
                buildTextField(
                    webUserPhoneController, 'Telefono', false, false),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowSpacing: 6,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'País',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      width: screenSize.blockWidth >= 920
                          ? screenSize.blockWidth * 0.28
                          : screenSize.blockWidth,
                      height: screenSize.blockWidth >= 920
                          ? screenSize.height * 0.055
                          : screenSize.height * 0.04,
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
                          hint: Text(
                            selectedSubtype["name"],
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: screenSize.blockWidth >= 920 ? 12 : 10,
                            ),
                          ),
                          menuMaxHeight: 200,
                          underline: const SizedBox(),
                          value: selectedCountry["name"],
                          items: countries
                              .map(
                                (e) => DropdownMenuItem<String>(
                                  value: e["name"],
                                  child: Text(
                                    e["name"],
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: screenSize.blockWidth >= 920
                                          ? 14
                                          : 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedCountry = countries.firstWhere(
                                  (element) => element["name"] == value);
                            });
                          },
                        ),
                      ),
                    )
                  ],
                ),

                // DropDwonButton(
                //     text: 'País',
                //     itemsSelected: countries,
                //     isCountry: true,
                //     screenSize: screenSize),
                buildTextField(
                  webUserTypeController,
                  'Tipo de usuario',
                  true,
                  false,
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowSpacing: 6,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rol usuario',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      width: screenSize.blockWidth >= 920
                          ? screenSize.blockWidth * 0.28
                          : screenSize.blockWidth,
                      height: screenSize.blockWidth >= 920
                          ? screenSize.height * 0.055
                          : screenSize.height * 0.04,
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
                          hint: Text(
                            selectedSubtype["name"],
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: screenSize.blockWidth >= 920 ? 12 : 10,
                            ),
                          ),
                          menuMaxHeight: 200,
                          underline: const SizedBox(),
                          value: selectedSubtype["name"],
                          items: clientSubtypes
                              .map(
                                (e) => DropdownMenuItem<String>(
                                  value: e["name"],
                                  child: Text(
                                    e["name"],
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: screenSize.blockWidth >= 920
                                          ? 14
                                          : 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedSubtype = clientSubtypes.firstWhere(
                                  (element) => element["name"] == value);
                            });
                          },
                        ),
                      ),
                    )
                  ],
                ),

                // DropDwonButton(
                //     text: 'Sub-tipo de usuario',
                //     itemsSelected: clientSubtypes,
                //     isCountry: false,
                //     screenSize: screenSize),
                buildTextField(
                  webUserPasswordController,
                  'Contraseña',
                  false,
                  true,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Column buildPhotoWidget() {
    return Column(
      children: [
        ClipRect(
          child: Container(
              width: screenSize.blockWidth >= 920
                  ? widget.screenSize.width * 0.13
                  : screenSize.blockWidth * 0.25,
              height: screenSize.blockWidth >= 920
                  ? widget.screenSize.height * 0.13
                  : screenSize.blockWidth * 0.25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
              ),
              child: imageAvailable
                  ? ClipOval(
                      child: SizedBox(
                        width: widget.screenSize.blockWidth >= 920
                            ? widget.screenSize.width * 0.13
                            : widget.screenSize.blockWidth * 0.25,
                        height: widget.screenSize.blockWidth >= 920
                            ? widget.screenSize.height * 0.13
                            : widget.screenSize.blockWidth * 0.25,
                        child: Image.memory(imageFile!),
                      ),
                    )
                  : (widget.userToEdit == null)
                      ? Icon(
                          Icons.person,
                          color: UiVariables.lightRedColor,
                          size: widget.screenSize.blockWidth >= 920 ? 150 : 100,
                        )
                      : ClipOval(
                          child: SizedBox(
                            width: widget.screenSize.blockWidth >= 920
                                ? widget.screenSize.width * 0.13
                                : widget.screenSize.blockWidth * 0.25,
                            height: widget.screenSize.blockWidth >= 920
                                ? widget.screenSize.height * 0.13
                                : widget.screenSize.blockWidth * 0.25,
                            child: Image.network(widget.userToEdit!["image"]),
                          ),
                        )),
        ),
        buildAddPhotoBtn(),
      ],
    );
  }

  Column buildTextField(TextEditingController controller, String text,
      bool readOnly, bool isPassword) {
    if (widget.userToEdit != null && isPassword) text = "Nueva contraseña";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
            color: Colors.grey,
          ),
        ),
        Container(
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
            readOnly: readOnly,
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isPassword ? 18 : 0,
              ), // top: screenSize.blockWidth >= 920 ? 14 : 0),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> validateFields() async {
    if (webUserNameController.text.isEmpty ||
        webUserLastNameController.text.isEmpty) {
      LocalNotificationService.showSnackBar(
        type: "fails",
        message: "Debes agregar los nombres y apellidos",
        icon: Icons.error_outline,
      );
      return;
    }
    if (webUserEmailController.text.isEmpty ||
        webUserPhoneController.text.isEmpty) {
      LocalNotificationService.showSnackBar(
        type: "fails",
        message: "Debes agregar el correo y el teléfono",
        icon: Icons.error_outline,
      );
      return;
    }
    String email = webUserEmailController.text.toLowerCase().trim();
    if (!CodeUtils.checkValidEmail(email)) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Debes agregar un correo válido",
        icon: Icons.error_outline,
      );
      return;
    }

    if (webUserPasswordController.text.length < 6) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "La contraseña debe tener mínimo 6 caracteres",
        icon: Icons.error_outline,
      );
      return;
    }
    if (imageFile == null) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Seleccione una foto",
        icon: Icons.error_outline,
      );
      return;
    }

    String storageId = FirebaseServices.db.collection("web_users").doc().id;
    String urlRef = isAdmin
        ? 'web_users/${clientsProvider.selectedClient!.accountInfo.id}/$storageId'
        : "web_users/${authProvider.webUser.uid}/$storageId";
    TaskSnapshot uploadTask =
        await FirebaseStorage.instance.ref(urlRef).putData(
              imageFile!,
              SettableMetadata(contentType: 'image/jpeg'),
            );
    String imageUrl = await uploadTask.ref.getDownloadURL();

    Map<String, dynamic> webUser = {
      "account_info": {
        "company_id": isAdmin
            ? clientsProvider.selectedClient!.accountInfo.id
            : authProvider.webUser.accountInfo.companyId,
        "creation_date": '',
        "enabled": true,
        "type": clientType['key'],
        "subtype": selectedSubtype["key"],
      },
      "profile_info": {
        "country_prefix": selectedCountry["key"],
        "email": email,
        "image": imageUrl,
        "names": webUserNameController.text,
        "last_names": webUserLastNameController.text,
        "phone": webUserPhoneController.text,
      },
      "uid": '',
      "password": webUserPasswordController.text,
    };
    String uidWebUser = await adminProvider.createAdmin(webUser, false);
    if (uidWebUser != "repeated_email" && uidWebUser != "error") {
      await clientsProvider.updateClientInfo(
        {
          "action": "add",
          "employee": {
            "full_name": CodeUtils.getFormatedName(
              webUserNameController.text,
              webUserLastNameController.text,
            ),
            "image": imageUrl,
            "enable": true,
            "phone": webUserPhoneController.text,
            "email": webUserEmailController.text,
            "type": clientType['key'],
            "subtype": selectedSubtype["key"],
            "uid": uidWebUser,
          }
        },
        "web_users",
        isAdmin,
        user,
      );
      imageFile = null;
      imageAvailable = false;
    }
  }

  void clearFields() {
    if (webUserNameController.text.isNotEmpty ||
        webUserLastNameController.text.isNotEmpty ||
        webUserEmailController.text.isNotEmpty ||
        webUserPhoneController.text.isNotEmpty ||
        webUserPasswordController.text.isNotEmpty) {
      webUserNameController.clear();
      webUserLastNameController.clear();
      webUserEmailController.clear();
      webUserPhoneController.clear();
      webUserPasswordController.clear();
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Campos limpios",
        icon: Icons.check,
      );
      UiMethods().showLoadingDialog(context: context);
    } else {
      LocalNotificationService.showSnackBar(
        type: "fails",
        message: "No hay campos que limpiar",
        icon: Icons.error_outline,
      );
      UiMethods().showLoadingDialog(context: context);
    }
    UiMethods().hideLoadingDialog(context: context);
  }

  Future<Map<String, dynamic>?> validateEditFields() async {
    try {
      if (webUserNameController.text.isEmpty ||
          webUserLastNameController.text.isEmpty) {
        LocalNotificationService.showSnackBar(
          type: "fails",
          message: "Debes agregar los nombres y apellidos",
          icon: Icons.error_outline,
        );
        return null;
      }
      if (webUserEmailController.text.isEmpty ||
          webUserPhoneController.text.isEmpty) {
        LocalNotificationService.showSnackBar(
          type: "fails",
          message: "Debes agregar el correo y el teléfono",
          icon: Icons.error_outline,
        );
        return null;
      }
      String email = webUserEmailController.text.toLowerCase().trim();
      if (!CodeUtils.checkValidEmail(email)) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Debes agregar un correo válido",
          icon: Icons.error_outline,
        );
        return null;
      }

      if (webUserPasswordController.text.isNotEmpty &&
          webUserPasswordController.text.length < 6) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "La contraseña debe tener mínimo 6 caracteres",
          icon: Icons.error_outline,
        );
        return null;
      }

      String imageUrl = widget.userToEdit!["image"];

      if (imageFile != null) {
        TaskSnapshot uploadTask = await FirebaseStorage.instance
            .ref(
                'web_users/${clientsProvider.selectedClient!.accountInfo.id}/${widget.userToEdit!["uid"]}')
            .putData(
              imageFile!,
              SettableMetadata(contentType: 'image/jpeg'),
            );

        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      Map<String, dynamic> updateData = {
        "uid": widget.userToEdit!["uid"],
        "names": webUserNameController.text.trim(),
        "last_names": webUserLastNameController.text.trim(),
        "image_url": imageUrl,
        "subtype": selectedSubtype["key"] != widget.userToEdit!["subtype"] &&
                selectedSubtype["key"] != null
            ? selectedSubtype["key"]
            : widget.userToEdit!["subtype"],
        "phone": webUserPhoneController.text,
        "client_id": widget.userToEdit!["client_id"],
      };

      if (webUserEmailController.text != widget.userToEdit!["email"] ||
          webUserPasswordController.text.isNotEmpty) {
        updateData["email"] = webUserEmailController.text;
      }

      if (webUserPasswordController.text.isNotEmpty) {
        updateData["password"] = webUserPasswordController.text;
      }

      return updateData;
    } catch (e) {
      if (kDebugMode) {
        print("DialogContentWebUser, validateEditFields error: $e");
      }

      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al validar los campos",
        icon: Icons.error_outline,
      );
      return null;
    }
  }
}
