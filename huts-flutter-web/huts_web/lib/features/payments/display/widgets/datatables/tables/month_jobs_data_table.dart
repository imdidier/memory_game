import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/domain/entities/month_jobs_entity.dart';
import 'package:provider/provider.dart';

class MonthJobsDataTable extends StatefulWidget {
  final List<DateJob> monthJobs;
  final ScreenSize screenSize;

  const MonthJobsDataTable(
      {required this.monthJobs, required this.screenSize, Key? key})
      : super(key: key);

  @override
  State<MonthJobsDataTable> createState() => _MonthJobsDataTableState();
}

class _MonthJobsDataTableState extends State<MonthJobsDataTable> {
  bool isLoaded = false;
  List<DateJob> filteredMonthJobs = [];
  TextEditingController searchController = TextEditingController();
  late PaymentsProvider paymentsProvider;
  List<String> headers = const [
    "Cargo",
    "Total horas",
  ];

  @override
  Widget build(BuildContext context) {
    bool isDesktop = widget.screenSize.blockWidth >= 1300;
    return Container(
      decoration: UiVariables.boxDecoration,
      width: widget.screenSize.blockWidth * 0.83,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          getTableHeader(isDesktop, "Listado de cargos"),
          SizedBox(
            height: filteredMonthJobs.length < 6
                ? widget.screenSize.height * 0.3
                : widget.screenSize.height * 0.7,
            child: filteredMonthJobs.isNotEmpty
                ? SelectionArea(
                  child: PaginatedDataTable2(
                      horizontalMargin: 20,
                      columnSpacing: 30,
                      empty: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text("No hay información"),
                        ),
                      ),
                      // rowsPerPage: filteredMonthJobs.length,
                      columns: getColumns(),
                      source: MonthJobsTableSource(
                          filteredMonthJobs, headers, paymentsProvider),
                      wrapInCard: false,
                      minWidth: 800,
                      fit: FlexFit.tight,
                    ),
                )
                : const Center(
                    child: Text("No hay elementos disponibles"),
                  ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> getColumns() {
    List<DataColumn> columns = [];
    for (var i = 0; i < headers.length; i++) {
      columns.add(
        DataColumn(
          label: Text(
            headers[i],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return columns;
  }

  void filterItems(String query) {
    String finalQuery = query.toLowerCase();
    if (query.isEmpty) {
      filteredMonthJobs = [...widget.monthJobs];
      setState(() {
        if (kDebugMode) print("modified");
      });
      return;
    }

    filteredMonthJobs.clear();
    for (DateJob job in widget.monthJobs) {
      String name = job.jobType;

      if (name.contains(finalQuery)) {
        filteredMonthJobs.add(job);
        continue;
      }
    }
    setState(() {
      if (kDebugMode) print(filteredMonthJobs.toString());
    });
  }

  getTableHeader(bool isDesktop, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text(
              title,
              style: TextStyle(
                  fontSize: (isDesktop || widget.screenSize.blockWidth >= 580)
                      ? widget.screenSize.width * 0.012
                      : widget.screenSize.width * 0.015,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: Container(
            width: widget.screenSize.width * 0.3,
            height: widget.screenSize.height * 0.055,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 2),
                  color: Colors.black26,
                  blurRadius: 2,
                )
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.search),
                hintText: "Buscar",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onChanged: filterItems,
            ),
          ),
        )
      ],
    );
  }

  @override
  void didUpdateWidget(covariant MonthJobsDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    filteredMonthJobs = [...widget.monthJobs];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isLoaded) {
      isLoaded = true;
      paymentsProvider = Provider.of<PaymentsProvider>(context);
      filteredMonthJobs = [...widget.monthJobs];
    }
  }
}

class MonthJobsTableSource extends DataTableSource {
  final List<DateJob> monthJobs;
  final List<dynamic> headers;
  final PaymentsProvider provider;

  MonthJobsTableSource(this.monthJobs, this.headers, this.provider);

  @override
  DataRow? getRow(int index) {
    return DataRow.byIndex(
      cells: getCells(index),
      index: index,
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => monthJobs.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    DateJob monthJob = monthJobs[index];
    return <DataCell>[
      DataCell(
        Text(monthJob.jobType),
      ),
      DataCell(
        Text(monthJob.employeesList.length.toString()),
      ),
    ];
  }
}
