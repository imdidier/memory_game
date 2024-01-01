// ignore_for_file: use_build_context_synchronously

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/statistics/domain/entities/employee_fav.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../core/services/navigation_service.dart';
import '../../../../../../../../core/utils/ui/ui_methods.dart';
import '../../../../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../../../../core/utils/ui/widgets/general/custom_tooltip.dart';
import '../../../../../../../auth/domain/entities/web_user_entity.dart';
import '../../../../../../../clients/display/provider/clients_provider.dart';

class BlockedTableWidget extends StatefulWidget {
  final List<ClientEmployee> userClient;
  final ScreenSize screenSize;
  final WebUser user;

  const BlockedTableWidget({
    Key? key,
    required this.userClient,
    required this.screenSize,
    required this.user,
  }) : super(key: key);

  @override
  State<BlockedTableWidget> createState() => _BlockedTableWidgetState();
}

class _BlockedTableWidgetState extends State<BlockedTableWidget> {
  List<String> headers = [
    "Foto",
    "Nombre",
    'Cargos',
    "Id",
    "Acciones",
  ];

  @override
  Widget build(BuildContext context) {
    ClientsProvider provider = Provider.of<ClientsProvider>(context);
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
          source: _LocksTableSource(
            user: widget.user,
            userClient: widget.userClient,
            provider: provider,
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

class _LocksTableSource extends DataTableSource {
  final List<ClientEmployee> userClient;
  final ClientsProvider provider;
  final WebUser user;

  _LocksTableSource({
    required this.user,
    required this.provider,
    required this.userClient,
  });
  @override
  DataRow? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => userClient.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    List<ClientEmployee> lock = userClient;

    return <DataCell>[
      DataCell(
        CircleAvatar(
          backgroundImage: NetworkImage(lock[index].photo),
        ),
      ),
      DataCell(Text(lock[index].fullname)),
      DataCell(Text(lock[index].jobs.join(', '))),
      DataCell(Text(lock[index].uid)),
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
                          text: '${lock[index].fullname}?',
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
                await provider.updateClientInfo(
                  {
                    "action": "delete",
                    "employee": {
                      "uid": lock[index].uid,
                      'fullname': lock[index].fullname,
                    },
                  },
                  "locks",
                  false,
                  user,
                );
                UiMethods().hideLoadingDialog(context: context);
              }),
        ),
      ),
    ];
  }
}
