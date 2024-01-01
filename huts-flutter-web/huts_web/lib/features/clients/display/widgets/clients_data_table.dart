import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/router.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../admins/display/providers/admin_provider.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../domain/entities/client_entity.dart';
import 'dart:html' as html;

class ClientsDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  const ClientsDataTable({required this.screenSize, Key? key})
      : super(key: key);

  @override
  State<ClientsDataTable> createState() => _ClientsDataTableState();
}

class _ClientsDataTableState extends State<ClientsDataTable> {
  List<String> headers = [
    "Acciones",
    "Img",
    "Nombre",
    "Correo",
    "País",
    "Ciudad",
    "Estado",
  ];

  @override
  Widget build(BuildContext context) {
    ClientsProvider provider = Provider.of<ClientsProvider>(context);
    AdminProvider adminProvider = Provider.of<AdminProvider>(context);

    return SizedBox(
      height: provider.filteredClients.length > 10
          ? widget.screenSize.height
          : widget.screenSize.height * 0.6,
      width: widget.screenSize.blockWidth,
      child: SelectionArea(
        child: PaginatedDataTable2(
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay información"),
            ),
          ),
          horizontalMargin: 15,
          columnSpacing: 10,
          columns: getColums(),
          source: _ClientsTableSource(
              provider: provider, adminProvider: adminProvider),
          dataRowHeight: kMinInteractiveDimension + 15,
          rowsPerPage: 10,
          onRowsPerPageChanged: (value) {},
          availableRowsPerPage: const [10, 20, 50],
        ),
      ),
    );
  }

  List<DataColumn2> getColums() {
    List<DataColumn2> columns = headers.map((String header) {
      return DataColumn2(
        size: header == "Img" || header == "Acciones"
            ? ColumnSize.S
            : (header == "Nombre")
                ? ColumnSize.L
                : ColumnSize.M,
        label: Text(
          header,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }).toList();

    return columns;
  }
}

class _ClientsTableSource extends DataTableSource {
  final ClientsProvider provider;
  final AdminProvider adminProvider;
  _ClientsTableSource({required this.provider, required this.adminProvider});
  @override
  DataRow? getRow(int index) =>
      DataRow.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => provider.filteredClients.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    ClientEntity client = provider.filteredClients[index];
    AuthProvider authProvider =
        Provider.of<AuthProvider>(globalContext!, listen: false);
    bool isAdmin = authProvider.webUser.accountInfo.type == 'admin';
    int status = client.accountInfo.status;

    Widget statusWidget = Chip(
      label: Text(
        status == 1 ? "Habilitado" : "Deshabilitado",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
      backgroundColor: status == 1 ? Colors.green : Colors.orange,
    );
    return <DataCell>[
      DataCell(
        Column(
          children: [
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomTooltip(
                  message: "Ver detalles",
                  child: InkWell(
                    onTap: () => html.window.open(
                      "/admin-v2/#${CustomRouter.clientDetails.replaceAll(":id", client.accountInfo.id)}",
                      "_blank",
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      color: Colors.black54,
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                CustomTooltip(
                  message: "Eliminar cliente",
                  child: InkWell(
                    onTap: () async {
                      if (globalContext == null) return;
                      bool itsConfirmed = await confirm(
                        globalContext,
                        title: Text(
                          "Eliminar cliente",
                          style: TextStyle(
                            color: UiVariables.primaryColor,
                          ),
                        ),
                        content: RichText(
                          text: TextSpan(
                            text: '¿Quieres eliminar a ',
                            children: <TextSpan>[
                              TextSpan(
                                text: '${client.name}?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
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
                      UiMethods().showLoadingDialog(context: globalContext);
                      await provider.deleteClient(id: client.accountInfo.id);
                      UiMethods().hideLoadingDialog(context: globalContext);
                    },
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                CustomTooltip(
                  message: status == 0 ? "Habilitar" : "Deshabilitar",
                  child: InkWell(
                    onTap: () async {
                      bool itsConfirmed = await confirm(
                        globalContext,
                        title: Text(
                          status == 0
                              ? "Habilitar Cliente"
                              : "Deshabilitar Cliente",
                          style: TextStyle(
                            color: UiVariables.primaryColor,
                          ),
                        ),
                        content: RichText(
                          text: TextSpan(
                            text: status == 0
                                ? '¿Quieres habilitar a '
                                : '¿Quieres deshabilitar a ',
                            children: <TextSpan>[
                              TextSpan(
                                text: '${client.name}?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
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
                      await provider.enableDisableClient(
                        index,
                        status == 1 ? 0 : 1,
                        isAdmin,
                      );
                    },
                    child: Icon(
                      status == 0
                          ? Icons.check_box_rounded
                          : Icons.disabled_by_default_rounded,
                      color: Colors.black54,
                      size: 20,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
      DataCell(
        CustomTooltip(
          message: "Copiar Id",
          child: GestureDetector(
            onTap: () async {
              await Clipboard.setData(
                  ClipboardData(text: client.accountInfo.id));
            },
            child: CircleAvatar(
              backgroundImage: client.imageUrl == ''
                  ? const NetworkImage(
                      'https://firebasestorage.googleapis.com/v0/b/huts-services.appspot.com/o/no_user_image.png?alt=media&token=697082b3-7ae8-4fc0-8943-a2efbbd0f788')
                  : NetworkImage(client.imageUrl),
            ),
          ),
        ),
      ),
      DataCell(
        Text(
          client.name == '' ? '' : client.name,
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(Text(
        client.email == '' ? '' : client.email,
        style: const TextStyle(fontSize: 13),
      )),
      DataCell(Text(
        client.location.country == '' ? '' : client.location.country,
        style: const TextStyle(fontSize: 13),
      )),
      DataCell(Text(
        client.location.city == '' ? '' : client.location.city,
        style: const TextStyle(fontSize: 13),
      )),
      DataCell(statusWidget),
    ];
  }
}
