import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/admins/display/providers/admin_provider.dart';
import 'package:huts_web/features/auth/data/models/web_user_model.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../core/utils/ui/ui_methods.dart';
import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../core/utils/ui/widgets/general/custom_tooltip.dart';
import '../../../../auth/domain/entities/screen_size_entity.dart';
import '../../../../general_info/display/providers/general_info_provider.dart';
import '../../provider/clients_provider.dart';
import '../../provider/user_provider.dart';

class ClientUsersDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  const ClientUsersDataTable({
    required this.screenSize,
    Key? key,
  }) : super(key: key);

  @override
  State<ClientUsersDataTable> createState() => _ClientUsersDataTableState();
}

class _ClientUsersDataTableState extends State<ClientUsersDataTable> {
  late WebUserModel webUser;

  List<String> headers = [
    "Foto",
    "Nombre",
    "Teléfono",
    "Tipo",
    "Subtipo",
    "Estado",
    "Correo",
    "Acciones",
  ];

  @override
  Widget build(BuildContext context) {
    UsersProvider providerWebUser = Provider.of<UsersProvider>(context);
    ClientsProvider providerClient = Provider.of<ClientsProvider>(context);
    AdminProvider adminProvider = Provider.of<AdminProvider>(context);
    AuthProvider authProvider = Provider.of<AuthProvider>(context);

    ScreenSize screenSize =
        Provider.of<GeneralInfoProvider>(context).screenSize;

    return SizedBox(
      height: widget.screenSize.height * 0.9,
      width: widget.screenSize.blockWidth,
      child: SelectionArea(
        child: PaginatedDataTable2(
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay información"),
            ),
          ),
          horizontalMargin: 20,
          columnSpacing: 30,
          columns: _getColums(),
          source: _UsersTableSource(
            screenSize,
            context,
            providerWebUser,
            providerClient: providerClient,
            adminProvider: adminProvider,
            authProvider: authProvider,
          ),
        ),
      ),
    );
  }

  List<DataColumn2> _getColums() {
    return headers.map(
      (String header) {
        return DataColumn2(
          label:
              Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    ).toList();
  }
}

class _UsersTableSource extends DataTableSource {
  final UsersProvider providerWebUser;
  final ClientsProvider providerClient;
  final AdminProvider adminProvider;
  final ScreenSize screenSize;
  final BuildContext context;
  final AuthProvider authProvider;

  _UsersTableSource(
    this.screenSize,
    this.context,
    this.providerWebUser, {
    required this.providerClient,
    required this.adminProvider,
    required this.authProvider,
  });
  bool isAdmin = false;

  @override
  DataRow? getRow(int index) => DataRow2.byIndex(
        cells: getCells(index),
        index: index,
      );

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount {
    isAdmin = authProvider.webUser.accountInfo.type == 'admin';
    if (!isAdmin) {
      authProvider.webUser.company.webUserEmployees
          .removeWhere((element) => element['uid'] == authProvider.webUser.uid);
    }
    return isAdmin
        ? providerClient.filteredWebUsers.length
        : authProvider.webUser.company.webUserEmployees.length;
  }

  @override
  int get selectedRowCount => 0;

  String getTypeName(String typeValue) {
    if (typeValue == "client") return "Cliente";
    if (typeValue == "admin") return "Administrador";
    if (typeValue == "superadmin") return "SuperAdministrador";
    return "Desconocido";
  }

  List<DataCell> getCells(int index) {
    Map<String, dynamic> user = {};
    if (!isAdmin) {
      user = authProvider.webUser.company.webUserEmployees[index];
      user['client_id'] = authProvider.webUser.company.id;
    } else {
      user = providerClient.filteredWebUsers[index];
      user["client_id"] = providerClient.selectedClient!.accountInfo.id;
    }
    bool isMe = user['uid'] == authProvider.webUser.uid;
    bool isEnabled = user["enable"];
    Widget statusWidget = Chip(
      label: Text(
        isEnabled ? "Habilitado" : "Deshabilitado",
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: isEnabled ? Colors.green : Colors.orange,
    );
    return <DataCell>[
      DataCell(
        CircleAvatar(
          backgroundImage: NetworkImage(user["image"]),
        ),
      ),
      DataCell(Text(user["full_name"])),
      DataCell(Text(user["phone"])),
      DataCell(Text((getTypeName(user["type"])))),
      DataCell(Text(
          CodeUtils.getWebUserSubtypeName(user["subtype"], type: "client"))),
      DataCell(statusWidget),
      DataCell(Text(user['email'])),
      DataCell(
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomTooltip(
              message: "Eliminar usuario",
              child: InkWell(
                onTap: () async {
                  bool itsConfirmed = await confirm(
                    context,
                    title: Text(
                      "Eliminar usuario",
                      style: TextStyle(
                        color: UiVariables.primaryColor,
                      ),
                    ),
                    content: RichText(
                      text: TextSpan(
                        text: '¿Seguro quieres eliminar a ',
                        children: <TextSpan>[
                          TextSpan(
                            text: '${user["full_name"]}?',
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

                  UiMethods().showLoadingDialog(context: context);
                  await adminProvider.deleteAdmin(user["uid"], true, isAdmin);
                  await providerClient.updateClientInfo(
                    {
                      "action": "delete",
                      "employee": {
                        "uid": user["uid"],
                        'fullname': user['fullname']
                      },
                    },
                    "web_users",
                    isAdmin,
                    authProvider.webUser,
                  );
                  UiMethods().hideLoadingDialog(context: context);
                },
                child: Icon(
                  Icons.delete,
                  color: isMe ? Colors.grey : Colors.red,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            CustomTooltip(
              message: "Editar usuario",
              child: InkWell(
                onTap: () {
                  providerWebUser.showCreateWebUserDialog(
                    context,
                    screenSize,
                    userToEdit: user,
                  );
                },
                child: Icon(
                  Icons.edit,
                  color: isMe ? Colors.grey : Colors.blue,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            CustomTooltip(
              message: !isEnabled ? "Habilitar" : "Deshabilitar",
              child: InkWell(
                onTap: () async {
                  bool itsConfirmed = await confirm(
                    context,
                    title: Text(
                      !isEnabled ? "Habilitar usuario" : "Deshabilitar usuario",
                      style: TextStyle(
                        color: UiVariables.primaryColor,
                      ),
                    ),
                    content: RichText(
                      text: TextSpan(
                        text: !isEnabled
                            ? '¿Quieres habilitar a '
                            : '¿Quieres deshabilitar a ',
                        children: <TextSpan>[
                          TextSpan(
                            text: '${user["full_name"]}?',
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
                  await providerClient.enableDisableClient(
                    index,
                    !isEnabled ? 1 : 0,
                    isAdmin,
                    true,
                    user['uid'],
                  );

                  await providerClient.updateClientInfo(
                    {
                      "action": "enabled",
                      "employee": {
                        "full_name": user["full_name"],
                        "phone": user["phone"],
                        "image": user["image"],
                        "email": user["email"],
                        "uid": user['uid'],
                        "type": user['type'],
                        "subtype": user["subtype"],
                        "enable": !isEnabled ? true : false,
                      },
                    },
                    "web_users",
                    isAdmin,
                    authProvider.webUser,
                  );
                },
                child: Icon(
                  !isEnabled
                      ? Icons.check_box_rounded
                      : Icons.disabled_by_default_rounded,
                  color: isMe ? Colors.grey : Colors.black54,
                  size: 20,
                ),
              ),
            )
          ],
        ),
      ),
    ];
  }
}
