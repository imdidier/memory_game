import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:provider/provider.dart';

import '../../../../../core/utils/code/code_utils.dart';
import '../../../../../core/utils/ui/widgets/general/custom_search_bar.dart';
import '../../../../../core/utils/ui/widgets/general/data_table_from_responsive.dart';
import '../../../../activity/display/providers/activity_provider.dart';
import '../../../../activity/domain/entities/activity_report.dart';
import '../../../../clients/display/provider/clients_provider.dart';
import '../../../../general_info/display/providers/general_info_provider.dart';

class ActivityScreen extends StatefulWidget {
  final ClientsProvider clientsProvider;

  const ActivityScreen({Key? key, required this.clientsProvider})
      : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late ScreenSize screenSize;

  bool isWidgetLoaded = false;

  String selectedCategory = "";

  List<Map<String, dynamic>> categories = [];

  late ActivityProvider activityProvider;

  List<List<String>> dataTableFromResponsive = [];

  @override
  void didChangeDependencies() async {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    categories = List<Map<String, dynamic>>.from(
      Provider.of<GeneralInfoProvider>(context, listen: false)
          .otherInfo
          .employeesActivityCategories
          .values
          .toList()
          .where((element) => element['key'] != 'all'),
    );
    categories = List<Map<String, dynamic>>.from(
      Provider.of<GeneralInfoProvider>(context, listen: false)
          .otherInfo
          .employeesActivityCategories
          .values
          .toList()
          .where((element) => element["key"] != "all"),
    );

    categories[0] = {
      "key": "all",
      "name": "Todo",
    };
    selectedCategory = categories[1]["key"];
    activityProvider = Provider.of<ActivityProvider>(context);

    if (mounted) setState(() {});
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    dataTableFromResponsive.clear();

    if (activityProvider.clientFilteredActivity.isNotEmpty) {
      dataTableFromResponsive.clear();
      for (var reports in activityProvider.clientActivity) {
        dataTableFromResponsive.add([
          "Descripción-${reports.description}",
          "Responsable-${reports.personInCharge['name']}",
          "Tipo responsable-${reports.personInCharge['type_name']}",
          "Categoría-${reports.category["name"]}",
          "Fecha-${CodeUtils.formatDate(reports.date)}",
        ]);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 5),
          child: Column(
            children: [
              Text(
                "Actividad",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: screenSize.width * 0.016,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                margin: const EdgeInsets.only(left: 22.0),
                child: Text(
                  "Actividad del cliente",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: screenSize.width * 0.01,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: screenSize.height * 0.6,
          child: Padding(
            padding: EdgeInsets.only(top: screenSize.height * 0.02),
            child: _buildDataTable(),
          ),
        ),
      ],
    );
  }

  Column _buildDataTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 9, left: 5),
          width: screenSize.blockWidth >= 920
              ? screenSize.blockWidth / 3
              : screenSize.blockWidth,
          child: CustomSearchBar(
            onChange: activityProvider.filterClientActivity,
            hint: "Buscar reporte",
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: screenSize.height * 0.45,
          width: screenSize.width * 0.90,
          child: screenSize.blockWidth >= 920
              ? _ActivityDataTable(
                  screenSize: screenSize,
                  reports: activityProvider.clientFilteredActivity,
                )
              : SingleChildScrollView(
                  child: DataTableFromResponsive(
                      listData: dataTableFromResponsive,
                      screenSize: screenSize,
                      type: 'activity-profile-client'),
                ),
        )
      ],
    );
  }
}

class _ActivityDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  final List<ActivityReport> reports;
  const _ActivityDataTable({
    required this.screenSize,
    required this.reports,
    Key? key,
  }) : super(key: key);

  @override
  State<_ActivityDataTable> createState() => __ActivityDataTableState();
}

class __ActivityDataTableState extends State<_ActivityDataTable> {
  bool _sortAscending = true;
  int? _sortColumnIndex;

  @override
  Widget build(BuildContext context) {
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
          columns: _getColums(),
          source: _DataSource(reports: widget.reports),
          horizontalMargin: 10,
          columnSpacing: 10,
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

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      if (columnIndex == 0) {
        widget.reports.sort((a, b) => (ascending)
            ? a.description.toLowerCase().compareTo(b.description.toLowerCase())
            : b.description
                .toLowerCase()
                .compareTo(a.description.toLowerCase()));

        return;
      }
      if (columnIndex == 1) {
        widget.reports.sort((a, b) => (ascending)
            ? a.personInCharge["name"]
                .toLowerCase()
                .compareTo(b.personInCharge["name"].toLowerCase())
            : b.personInCharge["name"]
                .toLowerCase()
                .compareTo(a.personInCharge["name"].toLowerCase()));

        return;
      }
      if (columnIndex == 2) {
        widget.reports.sort((a, b) => (ascending)
            ? a.personInCharge["type_name"]
                .toLowerCase()
                .compareTo(b.personInCharge["type_name"].toLowerCase())
            : b.personInCharge["type_name"]
                .toLowerCase()
                .compareTo(a.personInCharge["type_name"].toLowerCase()));

        return;
      }
      if (columnIndex == 3) {
        widget.reports.sort((a, b) => (ascending)
            ? a.category["name"]
                .toLowerCase()
                .compareTo(b.category["name"].toLowerCase())
            : b.category["name"]
                .toLowerCase()
                .compareTo(a.category["name"].toLowerCase()));

        return;
      }
      if (columnIndex == 4) {
        widget.reports.sort((a, b) =>
            (ascending) ? a.date.compareTo(b.date) : b.date.compareTo(a.date));

        return;
      }
    });
  }

  List<DataColumn2> _getColums() {
    return [
      "Descripción",
      "Responsable",
      "Tipo responsable",
      "Categoría",
      "Fecha",
    ].map(
      (String header) {
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
      },
    ).toList();
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
