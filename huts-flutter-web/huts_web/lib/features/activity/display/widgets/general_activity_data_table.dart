import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/activity/display/providers/activity_provider.dart';
import 'package:huts_web/features/activity/domain/entities/activity_report.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/code/code_utils.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';

class GeneralActivityDataTable extends StatefulWidget {
  const GeneralActivityDataTable({super.key});

  @override
  State<GeneralActivityDataTable> createState() =>
      _GeneralActivityDataTableState();
}

class _GeneralActivityDataTableState extends State<GeneralActivityDataTable> {
  bool _sortAscending = true;
  int? _sortColumnIndex;
  late ScreenSize screenSize;
  late ActivityProvider activityProvider;

  bool isWidgetLoaded = false;

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    activityProvider = context.watch<ActivityProvider>();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = context.read<GeneralInfoProvider>().screenSize;
    return SizedBox(
      height: screenSize.height * 0.9,
      width: screenSize.blockWidth,
      child: SelectionArea(
        child: PaginatedDataTable2(
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay información"),
            ),
          ),
          columns: _getColumns(),
          source: _DataSource(reports: activityProvider.filteredAllActivity),
          horizontalMargin: 15,
          columnSpacing: 15,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          sortArrowIcon: Icons.keyboard_arrow_up,
          sortArrowAnimationDuration: const Duration(milliseconds: 300),
          rowsPerPage: 10,
          onRowsPerPageChanged: (value) {},
          availableRowsPerPage: const [10, 20, 50],
          dataRowHeight: kMinInteractiveDimension + 15,
        ),
      ),
    );
  }

  List<DataColumn2> _getColumns() {
    return [
      "Descripción",
      "Responsable",
      "Tipo responsable",
      "Categoría",
      "Fecha",
    ].map((String header) {
      return DataColumn2(
        onSort: _sort,
        size: (header == "Descripción")
            ? ColumnSize.L
            : header == "Categoría" || header == "Tipo responsable"
                ? ColumnSize.S
                : ColumnSize.M,
        label:
            Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }).toList();
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      if (columnIndex == 0) {
        activityProvider.filteredAllActivity.sort((a, b) => (ascending)
            ? a.description.toLowerCase().compareTo(b.description.toLowerCase())
            : b.description
                .toLowerCase()
                .compareTo(a.description.toLowerCase()));

        return;
      }
      if (columnIndex == 1) {
        activityProvider.filteredAllActivity.sort((a, b) => (ascending)
            ? a.personInCharge["name"]
                .toLowerCase()
                .compareTo(b.personInCharge["name"].toLowerCase())
            : b.personInCharge["name"]
                .toLowerCase()
                .compareTo(a.personInCharge["name"].toLowerCase()));

        return;
      }
      if (columnIndex == 2) {
        activityProvider.filteredAllActivity.sort((a, b) => (ascending)
            ? a.personInCharge["type_name"]
                .toLowerCase()
                .compareTo(b.personInCharge["type_name"].toLowerCase())
            : b.personInCharge["type_name"]
                .toLowerCase()
                .compareTo(a.personInCharge["type_name"].toLowerCase()));

        return;
      }
      if (columnIndex == 3) {
        activityProvider.filteredAllActivity.sort((a, b) => (ascending)
            ? a.category["name"]
                .toLowerCase()
                .compareTo(b.category["name"].toLowerCase())
            : b.category["name"]
                .toLowerCase()
                .compareTo(a.category["name"].toLowerCase()));

        return;
      }
      if (columnIndex == 4) {
        activityProvider.filteredAllActivity.sort((a, b) =>
            (ascending) ? a.date.compareTo(b.date) : b.date.compareTo(a.date));

        return;
      }
    });
  }
}

class _DataSource extends DataTableSource {
  final List<ActivityReport> reports;
  _DataSource({required this.reports});

  @override
  DataRow? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => reports.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    ActivityReport report = reports[index];

    return <DataCell>[
      DataCell(
        Text(report.description),
      ),
      DataCell(
        Text(report.personInCharge["name"]),
      ),
      DataCell(
        Text(report.personInCharge["type_name"]),
      ),
      DataCell(
        Text(report.category["name"]),
      ),
      DataCell(
        Text(CodeUtils.formatDate(report.date)),
      ),
    ];
  }
}
