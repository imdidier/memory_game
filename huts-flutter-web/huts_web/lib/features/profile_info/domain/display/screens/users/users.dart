// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/profile_info/domain/display/providers/profile_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../../core/utils/ui/widgets/general/data_table_from_responsive.dart';
import '../../../../../auth/display/providers/auth_provider.dart';
import '../../../../../auth/domain/entities/web_user_entity.dart';
import '../../../../../clients/display/provider/user_provider.dart';
import '../../../../../clients/display/widgets/users/users_data_table.dart';

class UsersScreen extends StatefulWidget {
  final ScreenSize screenSize;
  final WebUser user;
  const UsersScreen({
    Key? key,
    required this.screenSize,
    required this.user,
  }) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late UsersProvider webUserProvider;
  late AuthProvider authProvider;
  late ProfileProvider profileProvider;
  late GeneralInfoProvider generalInfoProvider;

  @override
  void didChangeDependencies() {
    webUserProvider = Provider.of<UsersProvider>(context);
    profileProvider = Provider.of<ProfileProvider>(context);
    authProvider = Provider.of<AuthProvider>(context);
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    List<List<String>> dataTableFromResponsive = [];

    dataTableFromResponsive.clear();
    // if (authProvider.webUser.company.webUserEmployees.isNotEmpty) {
    //   dataTableFromResponsive.clear();
    //   for (var clientWebUser in authProvider.webUser.company.webUserEmployees) {
    //     dataTableFromResponsive.add([
    //       "Foto-${clientWebUser.photo}",
    //       "Nombre-${clientWebUser.fullname}",
    //       "Id-${clientWebUser.uid}",
    //       "Acciones-",
    //     ]);
    //   }
    // }
    return Column(
      children: [
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: widget.screenSize.width * 0.03),
          child: generalInfoProvider.screenSize.blockWidth < 800
              ? buildColumnSubtitle(
                  profileProvider, context, generalInfoProvider)
              : buildRowSubtitle(profileProvider, context, generalInfoProvider,
                  webUserProvider),
        ),
        SizedBox(height: widget.screenSize.height * 0.03),
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: widget.screenSize.width * 0.02),
          child: Padding(
            padding: EdgeInsets.only(top: widget.screenSize.height * 0.02),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Usuarios totales: ${authProvider.webUser.company.webUserEmployees.length}',
                    ),
                  ],
                ),
                SizedBox(height: widget.screenSize.height * 0.018),
                SizedBox(
                  height: widget.screenSize.height * 0.45,
                  width: widget.screenSize.width * 0.90,
                  child: widget.screenSize.blockWidth >= 920
                      ? ClientUsersDataTable(
                          screenSize: widget.screenSize,
                          // userClient:
                          //     authProvider.webUser.company.webUserEmployees,
                          // screenSize: screenSize,
                          // profileProvider: profileProvider,
                          // generalInfoProvider: generalInfoProvider,
                          // user: user,
                        )
                      : SingleChildScrollView(
                          child: DataTableFromResponsive(
                            listData: dataTableFromResponsive,
                            screenSize: widget.screenSize,
                            type: 'web-user-client',
                          ),
                        ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  InkWell buildAddBtn() {
    return InkWell(
      onTap: () {
        webUserProvider.showCreateWebUserDialog(context, widget.screenSize);
      },
      child: Container(
        height: widget.screenSize.height * 0.045,
        width: widget.screenSize.blockWidth > 1194
            ? widget.screenSize.blockWidth * 0.2
            : widget.screenSize.blockWidth * 0.35,
        decoration: BoxDecoration(
          color: UiVariables.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            "Crear usuario",
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.screenSize.blockWidth >= 920 ? 15 : 12,
            ),
          ),
        ),
      ),
    );
  }

  buildColumnSubtitle(ProfileProvider profileProvider, BuildContext context,
      GeneralInfoProvider generalInfoProvider) {
    return OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      overflowSpacing: 10,
      overflowAlignment: OverflowBarAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usuarios',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Usuarios asociados a ${widget.user.company.name}')
          ],
        ),
        buildAddBtn()
      ],
    );
  }

  buildRowSubtitle(ProfileProvider profileProvider, BuildContext context,
      GeneralInfoProvider generalInfoProvider, UsersProvider webUserProvider) {
    return OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      overflowSpacing: 10,
      overflowAlignment: OverflowBarAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usuarios',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Usuarios asociados a ${widget.user.company.name}')
          ],
        ),
        buildAddBtn()
      ],
    );
  }

  buildAddNewUserDialog(BuildContext context, ProfileProvider profileProvider,
      GeneralInfoProvider generalInfoProvider) {
    return showDialog(
        context: context,
        builder: (BuildContext ctxt) {
          return AlertDialog(
            actions: [
              buildCancelButtom(profileProvider, ctxt),
              buildSaveButtom(ctxt, profileProvider)
            ],
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Agregar nuevo Usuario'),
                Text(
                  'Agrega un nuevo usuario del cliente',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            content: StatefulBuilder(
              builder: ((ctxt, setState) {
                return SizedBox(
                  height: widget.screenSize.height * 0.38,
                  child: Column(children: [
                    buildAddUserForm(ctxt, profileProvider, widget.screenSize,
                        generalInfoProvider),
                  ]),
                );
              }),
            ),
          );
        });
  }

  Widget buildAddUserForm(BuildContext context, ProfileProvider profileProvider,
      ScreenSize screenSize, GeneralInfoProvider generalInfoProvider) {
    return Column(
      children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    height: screenSize.height * 0.05,
                    width: screenSize.width * 0.28,
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
                        controller: profileProvider.namesEditController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'Nombres',
                          suffixIcon: Padding(
                              padding: EdgeInsets.only(
                                  top: screenSize.height * 0.01),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.blueAccent,
                              )),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.03),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.003),
                    height: screenSize.height * 0.05,
                    width: screenSize.width * 0.28,
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
                        controller: profileProvider.adminEmailEditController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'Correo',
                          suffixIcon: Padding(
                              padding: EdgeInsets.only(
                                  top: screenSize.height * 0.01),
                              child: const Icon(Icons.edit)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.03),
                  Container(
                    height: screenSize.height * 0.05,
                    width: screenSize.width * 0.28,
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
                      child: profileProvider.dropdownButton(
                        context: context,
                        updateValue: profileProvider.userSubType,
                        items: generalInfoProvider
                            .otherInfo.webUserSubtypes.values
                            .map((e) => e.toString())
                            .toList(),
                        hintText: 'Subtipo de Usuario',
                        onChange: (value) {
                          profileProvider.userSubType = value;
                          profileProvider.newUserSubtype = profileProvider
                                      .userSubType! ==
                                  'Administrador'
                              ? 'admin'
                              : profileProvider.userSubType! == 'Operaciones'
                                  ? 'operations'
                                  : 'finances';
                        },
                        size: screenSize,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: screenSize.width * 0.007),
              Column(
                children: [
                  Container(
                    height: screenSize.height * 0.05,
                    width: screenSize.width * 0.28,
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
                        controller: profileProvider.lastNamesEditController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Apellidos',
                          suffixIcon: Padding(
                              padding: EdgeInsets.only(
                                  top: screenSize.height * 0.01),
                              child: const Icon(Icons.edit)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.03),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: screenSize.height * 0.05,
                        width: screenSize.width * 0.28,
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                  blurRadius: 3,
                                  color: Colors.black12,
                                  offset: Offset(2, 2))
                            ]),
                        child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: 10, left: 10),
                            child: profileProvider.dropdownButton(
                                context: context,
                                updateValue: profileProvider.usercountryPrefix,
                                items: profileProvider.countryPrefix,
                                hintText: 'País',
                                onChange: (value) {
                                  profileProvider.usercountryPrefix = value;
                                },
                                size: screenSize)),
                      ),
                      SizedBox(height: screenSize.height * 0.03),
                      Container(
                        height: screenSize.height * 0.05,
                        width: screenSize.width * 0.28,
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
                            maxLength: 13,
                            controller: profileProvider.phoneEdtiController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Telefono',
                              counterText: '',
                              suffixIcon: Padding(
                                  padding: EdgeInsets.only(
                                      top: screenSize.height * 0.01),
                                  child: const Icon(Icons.edit)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      Text(
                          'Escriba el numero de telefono con\nel indicativo del pais',
                          style: TextStyle(
                              fontSize: screenSize.width * 0.01,
                              color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ]),
        SizedBox(height: screenSize.height * 0.03),
      ],
    );
  }

  buildSaveButtom(BuildContext ctxt, ProfileProvider profileProvider) {
    return InkWell(
      onTap: () async {
        await profileProvider.eitherFailOrAddNewUser(
            ctxt, widget.user.company.id);
        Navigator.of(ctxt).pop();
      },
      child: Container(
        height: widget.screenSize.height * 0.045,
        width: profileProvider.isMobilView
            ? widget.screenSize.blockWidth * 0.60
            : widget.screenSize.width * 0.10,
        decoration: BoxDecoration(
            color: Colors.pink, borderRadius: BorderRadius.circular(25)),
        child: const Center(
            child: Text(
          'Agregar Nuevo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w200),
        )),
      ),
    );
  }

  buildCancelButtom(ProfileProvider profileProvider, BuildContext ctxt) {
    return InkWell(
      onTap: () async {
        Navigator.of(ctxt).pop();
      },
      child: Container(
        height: widget.screenSize.height * 0.045,
        width: profileProvider.isMobilView
            ? widget.screenSize.blockWidth * 0.60
            : widget.screenSize.width * 0.10,
        decoration: BoxDecoration(
            color: Colors.grey, borderRadius: BorderRadius.circular(25)),
        child: const Center(
            child: Text(
          'Cancelar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w200),
        )),
      ),
    );
  }
}
