import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../auth/domain/entities/screen_size_entity.dart';
import '../../../../../general_info/display/providers/general_info_provider.dart';

class RequestHistorical extends StatefulWidget {
  final String requestId;
  const RequestHistorical({required this.requestId, Key? key})
      : super(key: key);

  @override
  State<RequestHistorical> createState() => _RequestHistoricalState();
}

class _RequestHistoricalState extends State<RequestHistorical> {
  bool isWidgetLoaded = false;
  late ScreenSize screenSize;
  late GetRequestsProvider requestsProvider;
  List<List<String>> dataTableFromResponsive = [];

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Historial",
              style: TextStyle(
                color: Colors.black,
                fontSize: screenSize.blockWidth >= 920
                    ? screenSize.width * 0.016
                    : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              "Información de los cambios realizados a la solicitud.",
              style: TextStyle(
                color: Colors.black54,
                fontSize:
                    screenSize.blockWidth >= 920 ? screenSize.width * 0.01 : 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        _buildHistorical(),
      ],
    );
  }

  @override
  void didChangeDependencies() async {
    if (!isWidgetLoaded) {
      isWidgetLoaded = true;
      requestsProvider = Provider.of<GetRequestsProvider>(context);
      await requestsProvider.getRequestHistorical(widget.requestId);
    }
    super.didChangeDependencies();
  }

  Widget _buildHistorical() {
    dataTableFromResponsive.clear();

    if (requestsProvider.selectedRequestChanges.isNotEmpty) {
      dataTableFromResponsive.clear();
      for (var change in requestsProvider.selectedRequestChanges) {
        String responsable = change["details"].containsKey("person_in_charge")
            ? change["details"]["person_in_charge"]
            : CodeUtils.getFormatedName(
                change["employee_info"]["names"],
                change["employee_info"]["last_names"],
              );
        String typeUser = change["details"].containsKey("user_type")
            ? change["details"]["user_type"]
            : "Colaborador";
        dataTableFromResponsive.add([
          "Fecha-${CodeUtils.formatDate(
            change["update_date"].toDate(),
          )}",
          "Descripción-${change["details"]["description"]}",
          "Responsable-$responsable",
          "Tipo usuario-$typeUser",
          "Id solicitud-${widget.requestId}",
          // "Acciones",
        ]);
      }
    }
    return screenSize.blockWidth >= 920
        ? _HistoricalDataTable(
            screenSize: screenSize,
            provider: requestsProvider,
            requestId: widget.requestId,
          )
        : DataTableFromResponsive(
            listData: dataTableFromResponsive,
            screenSize: screenSize,
            type: 'history-request');
  }
}

class _HistoricalDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  final GetRequestsProvider provider;
  final String requestId;
  const _HistoricalDataTable(
      {required this.screenSize,
      required this.provider,
      required this.requestId,
      Key? key})
      : super(key: key);

  @override
  State<_HistoricalDataTable> createState() => __HistoricalDataTableState();
}

class __HistoricalDataTableState extends State<_HistoricalDataTable> {
  List<String> headers = [
    "Fecha",
    "Descripción",
    "Responsable",
    "Tipo usuario",
    "Id solicitud",
    // "Acciones",
  ];
  @override
  Widget build(BuildContext context) {
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
          rowsPerPage: defaultRowsPerPage,
          columns: _getColums(),
          source: _HistoricalTableSource(
            provider: widget.provider,
            requestId: widget.requestId,
          ),
        ),
      ),
    );
  }

  List<DataColumn2> _getColums() {
    return headers.map(
      (String header) {
        return DataColumn2(
          size: (header == "Fecha" || header == "Tipo usuario" || header == "Responsable" )
              ? ColumnSize.S
              : ColumnSize.L,
          label:
              Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    ).toList();
  }
}

class _HistoricalTableSource extends DataTableSource {
  final GetRequestsProvider provider;
  final String requestId;
  _HistoricalTableSource({required this.provider, required this.requestId});

  @override
  DataRow? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => provider.selectedRequestChanges.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    Map<String, dynamic> change = provider.selectedRequestChanges[index];
    return <DataCell>[
      DataCell(
        Text(
          CodeUtils.formatDate(
            change["update_date"].toDate(),
          ),
        ),
      ),
      DataCell(
        Text(
          change["details"]["description"],
        ),
      ),
      DataCell(
        Text(
          change["details"].containsKey("person_in_charge")
              ? change["details"]["person_in_charge"]
              : CodeUtils.getFormatedName(
                  change["employee_info"]["names"],
                  change["employee_info"]["last_names"],
                ),
        ),
      ),
      DataCell(
        Text(
          change["details"].containsKey("user_type")
              ? change["details"]["user_type"]
              : "Colaborador",
        ),
      ),
      DataCell(
        Text(requestId),
      ),
    ];
  }
}
