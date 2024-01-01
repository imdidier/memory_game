import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/code/code_utils.dart';
import '../../../../core/utils/ui/widgets/general/custom_search_bar.dart';
import '../../../activity/display/providers/activity_provider.dart';
import '../../../activity/domain/entities/activity_report.dart';

class ClientActivity extends StatefulWidget {
  final ClientsProvider clientsProvider;
  const ClientActivity({Key? key, required this.clientsProvider})
      : super(key: key);

  @override
  State<ClientActivity> createState() => _ClientActivityState();
}

class _ClientActivityState extends State<ClientActivity> {
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
          .where((element) => element["key"] != "all"),
    );

    categories[0] = {
      "key": "all",
      "name": "Todo",
    };
    selectedCategory = categories[1]["key"];
    activityProvider = Provider.of<ActivityProvider>(context);
    // await activityProvider.getClientActivity(
    //   id: widget.clientsProvider.selectedClient!.accountInfo.id,
    //   startDate: DateTime.now(),
    //   endDate: DateTime.now().subtract(const Duration(days: 30)),
    //   fromStart: true,
    // );

    if (mounted) setState(() {});
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    dataTableFromResponsive.clear();

    if (activityProvider.clientFilteredActivity.isNotEmpty) {
      dataTableFromResponsive.clear();
      for (var reports in activityProvider.clientFilteredActivity) {
        dataTableFromResponsive.add([
          "Descripción-${reports.description}",
          "Responsable-${reports.personInCharge['name']}",
          "Tipo responsable-${reports.personInCharge['type_name']}",
          "Categoría-${reports.category["name"]}",
          "Fecha-${CodeUtils.formatDate(reports.date)}",
        ]);
      }
    }
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Actividad",
            style: TextStyle(
                color: Colors.black,
                fontSize: screenSize.width * 0.016,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Actividad del cliente",
            style: TextStyle(
              color: Colors.black54,
              fontSize: screenSize.width * 0.01,
            ),
          ),
          _buildDataTable(),
        ],
      ),
    );
  }

  Column _buildDataTable() {
    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          // width: screenSize.blockWidth >= 920
          //     ? screenSize.blockWidth / 3
          //     : screenSize.blockWidth,
          child: Align(
            alignment: Alignment.centerRight,
            child: CustomSearchBar(
              onChange: activityProvider.filterClientActivity,
              hint: "Buscar reporte",
            ),
          ),
        ),
        const SizedBox(height: 25),
        screenSize.blockWidth >= 920
            ? _ActivityDataTable(
                screenSize: screenSize,
                reports: activityProvider.clientFilteredActivity,
              )
            : DataTableFromResponsive(
                listData: dataTableFromResponsive,
                screenSize: screenSize,
                type: 'activity')
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
    reports
        .sort((dateA, dateB) => dateA.date.compareTo(dateB.date) >= 1 ? 0 : 1);
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
