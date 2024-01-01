import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/display/screens/widgets/admin/request_action.dart';
import 'package:huts_web/features/requests/display/screens/widgets/request_action_dialog.dart';
import 'package:huts_web/features/requests/domain/entities/event_entity.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/services/event_message_service/service.dart';
import '../../../../../../core/utils/code/code_utils.dart';
import '../../../../../auth/domain/entities/screen_size_entity.dart';

class AdminRequestsDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  const AdminRequestsDataTable({required this.screenSize, Key? key})
      : super(key: key);

  @override
  State<AdminRequestsDataTable> createState() => _AdminRequestsDataTableState();
}

class _AdminRequestsDataTableState extends State<AdminRequestsDataTable> {
  List<String> headers = [
    "Acciones",
    // "Img:Imagen",
    "Cliente",
    "Colab:Colaborador",
    "Cargo",
    "Inicio:Fecha de inicio",
    "Fin:Fecha de fin",
    "Hrs:Horas totales",
    "Estado",
    "Evento",
    "Tarifa:Tipo de tarifa",
    "Ta.Co:Tarifa colaborador",
    "R.Co: Recargo nocturno colaborador",
    "Ta.Cli:Tarifa cliente",
    "R.Cli: Recargo nocturno cliente",
    "To.Co:Total colaborador",
    "To.Cli:Total cliente",
  ];

  late GetRequestsProvider provider;

  bool _sortAscending = true;
  int? _sortColumnIndex;

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<GetRequestsProvider>(context);
    if (context.read<AuthProvider>().webUser.clientAssociationInfo.isNotEmpty) {
      headers = [
        "Acciones",
        // "Img:Imagen",
        "Cliente",
        "Colaborador",
        "Cargo",
        "Inicio:Fecha de inicio",
        "Fin:Fecha de fin",
        "Hrs:Horas totales",
        "Estado",
        "Evento",
      ];
    }

    return SizedBox(
      height: provider.adminFilteredRequests.length > 10
          ? widget.screenSize.height
          : widget.screenSize.height * 0.5,
      width: widget.screenSize.width,
      child: SelectionArea(
        child: PaginatedDataTable2(
          lmRatio: 1.4,
          minWidth: widget.screenSize.blockWidth,
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay solicitudes"),
            ),
          ),
          horizontalMargin: 8,
          columnSpacing: 12,
          columns: getColums(),
          source: _RequestsTableSource(
            provider: provider,
            screenSize: widget.screenSize,
          ),
          dataRowHeight: kMinInteractiveDimension + 15,
          fixedLeftColumns: 3,
          rowsPerPage: 10,
          fit: FlexFit.tight,
          onRowsPerPageChanged: (value) {},
          availableRowsPerPage: const [10, 20, 50],
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          sortArrowIcon: Icons.keyboard_arrow_up,
          sortArrowAnimationDuration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }

  void _sort(int columnIndex, bool ascending) {
    setState(
      () {
        _sortColumnIndex = columnIndex;
        _sortAscending = ascending;

        if (columnIndex == 2) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? a.clientInfo.name.compareTo(b.clientInfo.name)
              : b.clientInfo.name.compareTo(a.clientInfo.name));
          return;
        }
        if (columnIndex == 3) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? a.employeeInfo.names.compareTo(b.employeeInfo.names)
              : b.employeeInfo.names.compareTo(a.employeeInfo.names));
          return;
        }
        if (columnIndex == 4) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? a.details.job["name"].compareTo(b.details.job["name"])
              : b.details.job["name"].compareTo(a.details.job["name"]));
          return;
        }
        if (columnIndex == 5) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? a.details.startDate.compareTo(b.details.startDate)
              : b.details.startDate.compareTo(a.details.startDate));
          return;
        }
        if (columnIndex == 6) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? a.details.endDate.compareTo(b.details.endDate)
              : b.details.endDate.compareTo(a.details.endDate));
          return;
        }
        if (columnIndex == 7) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? a.details.totalHours.compareTo(b.details.totalHours)
              : b.details.totalHours.compareTo(a.details.totalHours));
          return;
        }
        if (columnIndex == 8) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? a.details.status.compareTo(b.details.status)
              : b.details.status.compareTo(a.details.status));
          return;
        }
        if (columnIndex == 9) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? a.eventName.compareTo(b.eventName)
              : b.eventName.compareTo(a.eventName));
          return;
        }
        if (columnIndex == 10) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? a.details.fare.type.compareTo(b.details.fare.type)
              : b.details.fare.type.compareTo(a.details.fare.type));
          return;
        }
        if (columnIndex == 11) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? (a.details.fare.totalToPayEmployee / a.details.totalHours)
                  .compareTo(
                      b.details.fare.totalToPayEmployee / b.details.totalHours)
              : (b.details.fare.totalToPayEmployee / b.details.totalHours)
                  .compareTo(a.details.fare.totalToPayEmployee /
                      a.details.totalHours));
          return;
        }
        if (columnIndex == 12) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? (a.details.fare.totalClientPays / a.details.totalHours)
                  .compareTo(
                      b.details.fare.totalClientPays / b.details.totalHours)
              : (b.details.fare.totalClientPays / b.details.totalHours)
                  .compareTo(
                      a.details.fare.totalClientPays / a.details.totalHours));
          return;
        }

        if (columnIndex == 13) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? a.details.fare.totalToPayEmployee
                  .compareTo(b.details.fare.totalToPayEmployee)
              : b.details.fare.totalToPayEmployee
                  .compareTo(a.details.fare.totalToPayEmployee));
        }

        if (columnIndex == 14) {
          provider.adminFilteredRequests.sort((a, b) => (ascending)
              ? a.details.fare.totalClientPays
                  .compareTo(b.details.fare.totalClientPays)
              : b.details.fare.totalClientPays
                  .compareTo(a.details.fare.totalClientPays));
        }
      },
    );
  }

  List<DataColumn2> getColums() {
    List<DataColumn2> columns = [];
    for (String item in headers) {
      String tootltip = item;
      if (item.split(":").length == 2) {
        tootltip = item.split(":")[1];
        item = item.split(":")[0];
      }

      columns.add(
        DataColumn2(
          onSort: _sort,
          label: CustomTooltip(
            message: tootltip,
            child: Text(
              item,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          size: (item == "Cli" ||
                  item == "Co" ||
                  item == "Cargo" ||
                  item == "Inicio" ||
                  item == "Fin" ||
                  item == "Estado" ||
                  item == "Evento" ||
                  item == "Tarifa" ||
                  item == "Acciones")
              ? ColumnSize.L
              :
              // (item == "Img")
              //     ? ColumnSize.S
              //     :
              ColumnSize.M,
        ),
      );
    }

    return columns;
  }
}

class _RequestsTableSource extends DataTableSource {
  final GetRequestsProvider provider;
  final ScreenSize screenSize;
  _RequestsTableSource({required this.provider, required this.screenSize});

  @override
  DataRow? getRow(int index) =>
      DataRow.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => provider.adminFilteredRequests.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    BuildContext? context = NavigationService.getGlobalContext();

    Request request = provider.adminFilteredRequests[index];
    RequestEmployeeInfo employeeInfo = request.employeeInfo;

    return <DataCell>[
      DataCell(
        (provider.adminRequestsType == "deleted")
            ? const SizedBox()
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomTooltip(
                    message: "Historial solicitud",
                    child: InkWell(
                      onTap: () => AdminRequestAction.showActionDialog(
                        type: "history",
                        requestIndex: index,
                        provider: provider,
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.black54,
                        size: 19,
                      ),
                    ),
                  ),
                  CustomTooltip(
                    message: "Editar solicitud",
                    child: InkWell(
                      onTap: () {
                        // if (request.details.status == 0) return;
                        AdminRequestAction.showActionDialog(
                          type: "edit",
                          requestIndex: index,
                          provider: provider,
                        );
                      },
                      child: const Icon(
                        Icons.edit,
                        color:
                            //  (request.details.status == 0)
                            //     ? Colors.grey[300]
                            //     :
                            Colors.black54,
                        size: 19,
                      ),
                    ),
                  ),
                  CustomTooltip(
                    message: "Clonar solicitud",
                    child: InkWell(
                      onTap: () async {
                        Event? event = await provider.getRequestEvent(request);
                        if (event == null) return;

                        List<Request> requests = [];
                        requests.add(request);
                        await RequestActionDialog.show(
                          "clone",
                          "Clonar solicitud",
                          request,
                          event,
                          [0],
                          requests,
                          false,
                        );
                      },
                      child: const Icon(
                        Icons.content_copy,
                        color: Colors.black54,
                        size: 19,
                      ),
                    ),
                  ),
                  CustomTooltip(
                    message: "Mensaje al colaborador",
                    child: InkWell(
                      onTap: () async {
                        if (request.employeeInfo.names.isEmpty) return;
                        await EventMessageService.send(
                          eventItem: null,
                          employeesIds: [request.employeeInfo.id],
                          company: null,
                          screenSize: screenSize,
                          employeeName: CodeUtils.getFormatedName(
                            request.employeeInfo.names,
                            request.employeeInfo.lastNames,
                          ),
                        );
                      },
                      child: Icon(
                        Icons.circle_notifications_outlined,
                        color: (request.employeeInfo.names.isEmpty)
                            ? Colors.grey[300]
                            : Colors.black54,
                        size: 19,
                      ),
                    ),
                  ),
                  CustomTooltip(
                    message: "Eliminar solicitud",
                    child: InkWell(
                      onTap: () async {
                        // if (request.details.status > 2) return;
                        await provider.deleteRequest(request);
                      },
                      child: const Icon(
                        Icons.delete,
                        color:
                            // request.details.status > 2
                            //     ? Colors.grey[300]
                            //:
                            Colors.black54,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      DataCell(
        Text(
          request.clientInfo.name,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.getFormatedName(
            employeeInfo.names,
            employeeInfo.lastNames,
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          request.details.job["name"],
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.formatDate(request.details.startDate),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.formatDate(request.details.endDate),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(
        Center(
          child: Text(
            "${request.details.totalHours}",
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CodeUtils.getStatusColor(request.details.status, true),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            CodeUtils.getStatusName(request.details.status),
            style: TextStyle(
              color:
                  (request.details.status == 1 || request.details.status == 0)
                      ? Colors.black
                      : Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ),
      DataCell(
        CustomTooltip(
          message: request.eventName,
          child: Text(
            request.eventName,
            maxLines: 2,
            style:
                const TextStyle(overflow: TextOverflow.ellipsis, fontSize: 13),
          ),
        ),
      ),
      if (context == null ||
          context.read<AuthProvider>().webUser.clientAssociationInfo.isEmpty)
        DataCell(
          Text(
            request.details.fare.type,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      if (context == null ||
          context.read<AuthProvider>().webUser.clientAssociationInfo.isEmpty)
        DataCell(
          Text(
            CodeUtils.formatMoney((request.details.fare.totalToPayEmployee -
                    request.details.fare.totalEmployeeNightSurcharge) /
                request.details.totalHours),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      if (context == null ||
          context.read<AuthProvider>().webUser.clientAssociationInfo.isEmpty)
        DataCell(
          Text(
            CodeUtils.formatMoney(
                request.details.fare.totalEmployeeNightSurcharge),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      if (context == null ||
          context.read<AuthProvider>().webUser.clientAssociationInfo.isEmpty)
        DataCell(
          Text(
            CodeUtils.formatMoney((request.details.fare.totalClientPays -
                    request.details.fare.totalClientNightSurcharge) /
                request.details.totalHours),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      if (context == null ||
          context.read<AuthProvider>().webUser.clientAssociationInfo.isEmpty)
        DataCell(
          Text(
            CodeUtils.formatMoney(
                request.details.fare.totalClientNightSurcharge),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      if (context == null ||
          context.read<AuthProvider>().webUser.clientAssociationInfo.isEmpty)
        DataCell(
          Text(
            CodeUtils.formatMoney(request.details.fare.totalToPayEmployee),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      if (context == null ||
          context.read<AuthProvider>().webUser.clientAssociationInfo.isEmpty)
        DataCell(
          Text(
            CodeUtils.formatMoney(request.details.fare.totalClientPays),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
    ];
  }
}
