import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/admins/display/providers/admin_provider.dart';
import 'package:huts_web/features/admins/display/widgets/create_admin_dialog.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';

class AdminsDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  const AdminsDataTable({required this.screenSize, Key? key}) : super(key: key);

  @override
  State<AdminsDataTable> createState() => _AdminsDataTableState();
}

class _AdminsDataTableState extends State<AdminsDataTable> {
  List<String> headers = [
    //"Imagen",
    "Nombres",
    "Apellidos",
    "Correo",
    "Teléfono",
    "Tipo",
    "Estado",
    "Id",
    "Acciones",
  ];

  @override
  Widget build(BuildContext context) {
    AdminProvider provider = Provider.of<AdminProvider>(context);
    return SizedBox(
      height: widget.screenSize.height * 0.6,
      width: widget.screenSize.blockWidth,
      child: SelectionArea(
        child: PaginatedDataTable2(
          lmRatio: 1.4,
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay información"),
            ),
          ),
          horizontalMargin: 20,
          columnSpacing: 30,
          columns: _getColumns(),
          source: _AdminsTableSource(provider: provider),
        ),
      ),
    );
  }

  List<DataColumn2> _getColumns() {
    return headers.map(
      (String header) {
        return DataColumn2(
          size: ColumnSize.L,
          label:
              Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    ).toList();
  }
}

class _AdminsTableSource extends DataTableSource {
  final AdminProvider provider;
  _AdminsTableSource({required this.provider});
  @override
  DataRow? getRow(int index) =>
      DataRow.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => provider.filteredAdmins.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    WebUser admin = provider.filteredAdmins[index];

    Widget statusWidget = Chip(
      label: Text(
        admin.accountInfo.enabled ? "Habilitado" : "Deshabilitado",
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: admin.accountInfo.enabled ? Colors.green : Colors.orange,
    );

    return <DataCell>[
      DataCell(
        Text(admin.profileInfo.names),
      ),
      DataCell(
        Text(admin.profileInfo.lastNames),
      ),
      DataCell(
        Text(admin.profileInfo.email),
      ),
      DataCell(
        Text(admin.profileInfo.phone),
      ),
      DataCell(
        Text(
            CodeUtils.getWebUserSubtypeName(admin.accountInfo.subtype)),
      ),
      DataCell(statusWidget),
      DataCell(
        Text(admin.uid),
      ),
      DataCell(
        Row(
          children: [
            _buildEnableDisableBtn(
              admin,
              globalContext,
              index,
            ),
            Row(
              children: [
                const SizedBox(width: 6),
                CustomTooltip(
                  message: "Editar",
                  child: InkWell(
                    onTap: () async =>
                        await CreateAdminDialog.show(adminToEdit: admin),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.black54,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            _buildDeleteBtn(globalContext, admin),
          ],
        ),
      )
    ];
  }

  Row _buildDeleteBtn(BuildContext? globalContext, WebUser admin) {
    return Row(
      children: [
        const SizedBox(width: 6),
        CustomTooltip(
          message: "Eliminar",
          child: InkWell(
            onTap: () async {
              if (globalContext == null) return;

              bool itsConfirmed = await confirm(
                globalContext,
                title: Text(
                  "Eliminar administrador",
                  style: TextStyle(
                    color: UiVariables.primaryColor,
                  ),
                ),
                content: RichText(
                  text: TextSpan(
                    text: '¿Quieres eliminar a ',
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            '${admin.profileInfo.names} ${admin.profileInfo.lastNames}?',
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

              await provider.deleteAdmin(admin.uid);
            },
            child: const Icon(
              Icons.delete_rounded,
              color: Colors.black54,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Row _buildEnableDisableBtn(
      WebUser admin, BuildContext? globalContext, int index) {
    return Row(
      children: [
        const SizedBox(width: 6),
        CustomTooltip(
          message: !admin.accountInfo.enabled ? "Habilitar" : "Deshabilitar",
          child: InkWell(
            onTap: () async {
              if (globalContext == null) return;

              bool itsConfirmed = await confirm(
                globalContext,
                title: Text(
                  (!admin.accountInfo.enabled)
                      ? "Habilitar Administrador"
                      : "Deshabilitar Administrador",
                  style: TextStyle(
                    color: UiVariables.primaryColor,
                  ),
                ),
                content: RichText(
                  text: TextSpan(
                    text: (!admin.accountInfo.enabled)
                        ? '¿Quieres habilitar a '
                        : '¿Quieres deshabilitar a ',
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            '${admin.profileInfo.names} ${admin.profileInfo.lastNames}?',
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

              await provider.enableDisableAdmin(
                index,
                !admin.accountInfo.enabled,
              );
            },
            child: Icon(
              (!admin.accountInfo.enabled)
                  ? Icons.check_box_rounded
                  : Icons.disabled_by_default_rounded,
              color: Colors.black54,
              size: 20,
            ),
          ),
        )
      ],
    );
  }
}
