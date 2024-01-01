import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/profile_info/domain/display/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import '../../../../auth/domain/entities/web_user_entity.dart';

class InformationScreen extends StatelessWidget {
  final WebUser user;
  InformationScreen({Key? key, required this.user}) : super(key: key);
  late AuthProvider authProvider;
  @override
  Widget build(BuildContext context) {
    ProfileProvider profileProvider = Provider.of<ProfileProvider>(context);
    authProvider = Provider.of<AuthProvider>(context);
    GeneralInfoProvider generalInfoProvider =
        Provider.of<GeneralInfoProvider>(context);
    profileProvider.phoneEdtiController.text = user.profileInfo.phone;
    profileProvider.emailEditController.text =
        user.profileInfo.email.toLowerCase();

    return SizedBox(
      width: generalInfoProvider.screenSize.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Datos personales y de contacto',
                style: TextStyle(
                  fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                      ? 18
                      : 14,
                ),
              ),
              buildSaveButtom(profileProvider, generalInfoProvider, context),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          SizedBox(height: generalInfoProvider.screenSize.height * 0.03),
          generalInfoProvider.screenSize.blockWidth <= 1000
              ? buildColumnInformation(profileProvider, generalInfoProvider)
              : buildRowInformation(profileProvider, generalInfoProvider),
          SizedBox(height: generalInfoProvider.screenSize.height * 0.02),
        ],
      ),
    );
  }

  Widget buildColumnInformation(ProfileProvider profileProvider,
      GeneralInfoProvider generalInfoProvider) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modificar correo',
            style: TextStyle(
              color: Colors.grey,
              fontSize:
                  generalInfoProvider.screenSize.blockWidth >= 920 ? 16 : 13,
            ),
          ),
          Container(
            height: generalInfoProvider.screenSize.height * 0.05,
            width: generalInfoProvider.screenSize.width * 0.28,
            decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                      blurRadius: 3,
                      color: Colors.black12,
                      offset: Offset(2, 2))
                ]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 10),
              child: TextFormField(
                style: TextStyle(
                  fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                      ? 15
                      : 12,
                ),
                controller: profileProvider.emailEditController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    suffixIcon: Padding(
                        padding: EdgeInsets.only(
                            top: generalInfoProvider.screenSize.height * 0.01),
                        child: Icon(Icons.edit,
                            size:
                                generalInfoProvider.screenSize.blockWidth >= 920
                                    ? 20
                                    : 15)),
                    border: InputBorder.none),
              ),
            ),
          ),
          SizedBox(height: generalInfoProvider.screenSize.height * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modificar Teléfono',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                      ? 16
                      : 13,
                ),
              ),
              Container(
                height: generalInfoProvider.screenSize.height * 0.05,
                width: generalInfoProvider.screenSize.width * 0.28,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                          blurRadius: 3,
                          color: Colors.black12,
                          offset: Offset(2, 2))
                    ]),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 10),
                  child: TextFormField(
                    style: TextStyle(
                      fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                          ? 15
                          : 12,
                    ),
                    controller: profileProvider.phoneEdtiController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixIcon: Padding(
                          padding: EdgeInsets.only(
                              top:
                                  generalInfoProvider.screenSize.height * 0.01),
                          child: Icon(Icons.edit,
                              size: generalInfoProvider.screenSize.blockWidth >=
                                      920
                                  ? 20
                                  : 15)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: generalInfoProvider.screenSize.height * 0.03),
          Text(
            'Modificar Contraseña',
            style: TextStyle(
              color: Colors.grey,
              fontSize:
                  generalInfoProvider.screenSize.blockWidth >= 920 ? 15 : 13,
            ),
          ),
          Container(
            height: generalInfoProvider.screenSize.height * 0.05,
            width: generalInfoProvider.screenSize.width * 0.28,
            decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                      blurRadius: 3,
                      color: Colors.black12,
                      offset: Offset(2, 2))
                ]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 10),
              child: TextFormField(
                style: TextStyle(
                  fontSize: generalInfoProvider.screenSize.blockWidth >= 920
                      ? 15
                      : 12,
                ),
                controller: profileProvider.passEditController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                    suffixIcon: Padding(
                        padding: EdgeInsets.only(
                            top: generalInfoProvider.screenSize.height * 0.01),
                        child: Icon(
                          Icons.edit,
                          size: generalInfoProvider.screenSize.blockWidth >= 920
                              ? 20
                              : 15,
                        )),
                    border: InputBorder.none,
                    hintText: 'Nueva Contraseña'),
                obscureText: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Row buildRowInformation(ProfileProvider profileProvider,
      GeneralInfoProvider generalInfoProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modificar correo',
              style: TextStyle(color: Colors.grey),
            ),
            Container(
              height: generalInfoProvider.screenSize.height * 0.05,
              width: generalInfoProvider.screenSize.width * 0.28,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        blurRadius: 3,
                        color: Colors.black12,
                        offset: Offset(2, 2))
                  ]),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 10),
                child: TextFormField(
                  controller: profileProvider.emailEditController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                      suffixIcon: Padding(
                          padding: EdgeInsets.only(
                              top:
                                  generalInfoProvider.screenSize.height * 0.01),
                          child: const Icon(Icons.edit)),
                      border: InputBorder.none),
                ),
              ),
            ),
            SizedBox(height: generalInfoProvider.screenSize.height * 0.05),
            const Text(
              'Modificar Contraseña',
              style: TextStyle(color: Colors.grey),
            ),
            Container(
              height: generalInfoProvider.screenSize.height * 0.05,
              width: generalInfoProvider.screenSize.width * 0.28,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        blurRadius: 3,
                        color: Colors.black12,
                        offset: Offset(2, 2))
                  ]),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 10),
                child: TextFormField(
                  controller: profileProvider.passEditController,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                      suffixIcon: Padding(
                          padding: EdgeInsets.only(
                              top:
                                  generalInfoProvider.screenSize.height * 0.01),
                          child: const Icon(Icons.edit)),
                      border: InputBorder.none,
                      hintText: 'Nueva Contraseña'),
                  obscureText: true,
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: generalInfoProvider.screenSize.width * 0.09),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modificar Telefono',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: generalInfoProvider.screenSize.width * 0.012),
            ),
            Container(
              height: generalInfoProvider.screenSize.height * 0.05,
              width: generalInfoProvider.screenSize.width * 0.28,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        blurRadius: 3,
                        color: Colors.black12,
                        offset: Offset(2, 2))
                  ]),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 10),
                child: TextFormField(
                  controller: profileProvider.phoneEdtiController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    suffixIcon: Padding(
                      padding: EdgeInsets.only(
                          top: generalInfoProvider.screenSize.height * 0.01),
                      child: const Icon(
                        Icons.edit,
                      ),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  buildSaveButtom(ProfileProvider profileProvider,
      GeneralInfoProvider generalInfoProvider, BuildContext context) {
    return InkWell(
      onTap: () async {
        authProvider.webUser.clientAssociationInfo;

        Map<String, dynamic> updateData = {
          "uid": user.uid,
          "names": user.profileInfo.names,
          "last_names": user.profileInfo.lastNames,
          authProvider.webUser.accountInfo.type != 'admin'
              ? "image_url"
              : user.profileInfo.image: '',
          if (authProvider.webUser.accountInfo.type == 'admin') "type": 'admin',
          "subtype": user.accountInfo.subtype,
          "phone": profileProvider.phoneEdtiController.text,
          if (authProvider.webUser.accountInfo.type != 'admin')
            "client_id": authProvider.webUser.clientAssociationInfo.isEmpty
                ? user.accountInfo.companyId
                : authProvider.webUser.clientAssociationInfo['client_id'],
        };

        if (profileProvider.passEditController.text.isNotEmpty) {
          updateData["password"] = profileProvider.passEditController.text;
          profileProvider.passEditController.clear();
        }
        if (profileProvider.emailEditController.text.isNotEmpty) {
          updateData["email"] = profileProvider.emailEditController.text;
        }
        // bool resp =
        await profileProvider.validateInformationFields(user, updateData);

        // if (resp) {
        //   ClientsProvider providerClient =
        //       Provider.of<ClientsProvider>(context, listen: false);
        //   await providerClient.updateClientInfo(
        //     {
        //       'name': '${user.profileInfo.names} ${user.profileInfo.lastNames}',
        //       'phone': profileProvider.phoneEdtiController.text,
        //       'minRequestHours': user.company.accountInfo['min_request_hours'],
        //       'email': profileProvider.emailEditController.text
        //     },
        //     "general",
        //     false,
        //     user,
        //   );
        // }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: generalInfoProvider.screenSize.height * 0.045,
        decoration: BoxDecoration(
            color: UiVariables.primaryColor,
            borderRadius: BorderRadius.circular(10)),
        child: const Center(
            child: Text(
          'Guardar Cambios',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w200, fontSize: 15),
        )),
      ),
    );
  }
}
