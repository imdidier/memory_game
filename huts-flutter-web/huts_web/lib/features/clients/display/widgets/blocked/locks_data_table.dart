import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:provider/provider.dart';

import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../core/utils/ui/widgets/general/custom_tooltip.dart';
import '../../../../auth/domain/entities/screen_size_entity.dart';
import '../../provider/clients_provider.dart';

class ClientLocksDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  const ClientLocksDataTable({required this.screenSize, Key? key})
      : super(key: key);

  @override
  State<ClientLocksDataTable> createState() => _ClientLocksDataTableState();
}

class _ClientLocksDataTableState extends State<ClientLocksDataTable> {
  List<String> headers = [
    "Foto",
    "Nombre",
    "Teléfono",
    "Cargos",
    "Id",
    "Acciones",
  ];

  @override
  Widget build(BuildContext context) {
    ClientsProvider provider = Provider.of<ClientsProvider>(context);
    return SizedBox(
      height: widget.screenSize.height * 0.6,
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
          // rowsPerPage: (provider.filteredLocks.length >= 8)
          //     ? 8
          //     : provider.filteredLocks.isEmpty
          //         ? 1
          //         : provider.filteredLocks.length,
          columns: _getColums(),
          source: _LocksTableSource(provider: provider),
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

class _LocksTableSource extends DataTableSource {
  final ClientsProvider provider;

  _LocksTableSource({required this.provider});

  @override
  DataRow? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => provider.filteredLocks.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    Map<String, dynamic> locked = provider.filteredLocks[index];
    return <DataCell>[
      DataCell(
        CircleAvatar(
          backgroundImage: NetworkImage(locked["photo"]),
        ),
      ),
      DataCell(Text(locked["fullname"])),
      DataCell(Text(locked["phone"])),
      DataCell(Text(
          locked["jobs"].isEmpty ? "Sin cargos" : locked["jobs"].join(", "))),
      DataCell(Text(locked["uid"])),
      DataCell(
        CustomTooltip(
          message: "Eliminar de bloqueados",
          child: InkWell(
            child: const Icon(
              Icons.delete,
              color: Colors.red,
              size: 20,
            ),
            onTap: () async {
              BuildContext? context = NavigationService.getGlobalContext();
              if (context == null) return;
              bool itsConfirmed = await confirm(
                context,
                title: Text(
                  "Eliminar de bloqueados",
                  style: TextStyle(
                    color: UiVariables.primaryColor,
                  ),
                ),
                content: RichText(
                  text: TextSpan(
                    text: '¿Quieres eliminar a ',
                    children: <TextSpan>[
                      TextSpan(
                        text: '${locked['fullname']}?',
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
              bool resp = await provider.updateClientInfo(
                {
                  "action": "delete",
                  "employee": {
                    "uid": locked["uid"],
                    'fullname': locked['fullname']
                  },
                },
                "locks",
                true,
              );
              UiMethods().hideLoadingDialog(context: context);
            },
          ),
        ),
      ),
    ];
  }
}
