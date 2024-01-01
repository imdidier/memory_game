import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/employees/display/widgets/payment_requests_dialog.dart';
import 'package:provider/provider.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';

class EmployeesPaymentsDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  final String type;
  const EmployeesPaymentsDataTable(
      {required this.screenSize, required this.type, Key? key})
      : super(key: key);

  @override
  State<EmployeesPaymentsDataTable> createState() =>
      _EmployeesPaymentsDataTableState();
}

class _EmployeesPaymentsDataTableState
    extends State<EmployeesPaymentsDataTable> {
  late EmployeesProvider employeesProvider;
  bool isWidgetLoaded = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    employeesProvider = Provider.of<EmployeesProvider>(context);
    employeesProvider.setDynamicHeaders(widget.type);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 10,
      radius: const Radius.circular(10),
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
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
              rowsPerPage: 10,
              horizontalMargin: 20,
              columnSpacing: 30,
              columns: _getColums(),
              source: _EmployeesPaymentsDataSource(
                provider: employeesProvider,
                type: widget.type,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DataColumn2> _getColums() {
    return employeesProvider.employeesPaymentsHeaders.map(
      (String header) {
        return DataColumn2(
          label:
              Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    ).toList();
  }
}

class _EmployeesPaymentsDataSource extends DataTableSource {
  final EmployeesProvider provider;
  final String type;
  _EmployeesPaymentsDataSource({required this.provider, required this.type});

  @override
  DataRow? getRow(int index) =>
      DataRow.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => provider.filteredEmployeesPayments.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    Map<String, dynamic> payment = provider.filteredEmployeesPayments[index];
    List<DataCell> cells = [
      DataCell(
        payment["employee_info"]["image"] != ""
            ? CircleAvatar(
                backgroundImage:
                    NetworkImage(payment["employee_info"]["image"]))
            : const CircleAvatar(
                child: Icon(Icons.person),
              ),
      ),
      DataCell(Text(payment["employee_info"]["id"])),
      DataCell(Text(payment["employee_info"]["fullname"])),
      DataCell(Text(payment["employee_info"]["phone"])),
    ];

    if (type != "days") {
      cells.addAll(
        List<DataCell>.from(
          payment["range_requests"]
              .values
              .map(
                (e) => DataCell(
                  Text(CodeUtils.formatMoney(e["total_to_pay"])),
                ),
              )
              .toList(),
        ),
      );
    }

    cells.addAll(
      List<DataCell>.from(
        [
          DataCell(Text("${payment["total_hours"]}")),
          DataCell(
            Text(
              CodeUtils.formatMoney(payment["total_to_pay"]),
            ),
          ),
          DataCell(CustomTooltip(
            message: "Ver detalles",
            child: InkWell(
              onTap: () => PaymentRequestsDialog.show(payment),
              child: const Icon(
                Icons.info_outline,
                color: Colors.black54,
                size: 20,
              ),
            ),
          ))
        ],
      ),
    );

    return cells;
  }
}
