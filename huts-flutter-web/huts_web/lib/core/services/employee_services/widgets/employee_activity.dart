import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_search_bar.dart';
import 'package:huts_web/features/activity/display/providers/activity_provider.dart';
import 'package:huts_web/features/activity/domain/entities/activity_report.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../features/auth/domain/entities/screen_size_entity.dart';
import '../../../utils/ui/widgets/general/custom_scroll_behavior.dart';

class EmployeeActivity extends StatefulWidget {
  final ScreenSize screenSize;
  final String employeeId;
  const EmployeeActivity(
      {required this.screenSize, required this.employeeId, Key? key})
      : super(key: key);

  @override
  State<EmployeeActivity> createState() => _EmployeeActivityState();
}

class _EmployeeActivityState extends State<EmployeeActivity> {
  bool isWidgetLoaded = false;
  String selectedCategory = "";
  List<Map<String, dynamic>> categories = [];
  late ActivityProvider activityProvider;

  @override
  void didChangeDependencies() async {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    activityProvider = Provider.of<ActivityProvider>(context);

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
    await activityProvider.getEmployeeActivity(
      id: widget.employeeId,
      category: selectedCategory,
      fromStart: true,
    );

    if (mounted) setState(() {});

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.screenSize.blockWidth,
      child: Column(
        children: [
          SizedBox(
            height: widget.screenSize.height * 0.05,
            child: ScrollConfiguration(
              behavior: CustomScrollBehavior(),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List<Widget>.from(
                  categories
                      .map(
                        (category) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: ChoiceChip(
                              label: Text(
                                category["name"],
                                style: const TextStyle(color: Colors.white),
                              ),
                              selected: selectedCategory == category["key"],
                              selectedColor: selectedCategory == category["key"]
                                  ? UiVariables.primaryColor
                                  : Colors.grey,
                              onSelected: (bool newValue) async {
                                setState(() {
                                  newValue
                                      ? selectedCategory = category["key"]
                                      : selectedCategory = "";
                                });

                                await activityProvider.getEmployeeActivity(
                                  id: widget.employeeId,
                                  category: selectedCategory,
                                );
                              }),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: widget.screenSize.blockWidth >= 920
                ? widget.screenSize.blockWidth / 3
                : widget.screenSize.blockWidth,
            child: CustomSearchBar(
              onChange: activityProvider.filterEmployeeActivity,
              hint: "Buscar reporte",
            ),
          ),
          const SizedBox(height: 25),
          _ActivityDataTable(
            screenSize: widget.screenSize,
            reports: activityProvider.employeeFilteredActivity,
          )
        ],
      ),
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
  @override
  Widget build(BuildContext context) {
    // List<ActivityReport> data = [];
    widget.reports.sort((a, b) => a.date.compareTo(b.date));
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
          columns: _getColums(),
          source: _DataSource(reports: widget.reports),
          horizontalMargin: 20,
          columnSpacing: 30,
        ),
      ),
    );
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
    reports.sort((a, b) => b.date.compareTo(a.date));
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
