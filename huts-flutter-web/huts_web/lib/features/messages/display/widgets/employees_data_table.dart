import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/messages/data/models/message_employee.dart';
import 'package:huts_web/features/messages/display/provider/messages_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/code/code_utils.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';

class EmployeesDataTable extends StatelessWidget {
  final ScreenSize screenSize;
  const EmployeesDataTable({required this.screenSize, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    MessagesProvider provider = Provider.of<MessagesProvider>(context);
    return SizedBox(
      height: screenSize.height * 0.5,
      width: screenSize.blockWidth,
      child: SelectionArea(
        child: PaginatedDataTable2(
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay información"),
            ),
          ),
          showCheckboxColumn: true,
          horizontalMargin: 20,
          columnSpacing: 20,
          // rowsPerPage: (provider.filteredEmployees.length >= 8)
          //     ? 8
          //     : provider.filteredEmployees.length,
          columns: getColums(),
          source: _EmployeesTableSource(provider: provider),
        ),
      ),
    );
  }

  List<DataColumn2> getColums() {
    return <DataColumn2>[
      const DataColumn2(
        label: Text("Acción", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn2(
        label: Text("Foto", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn2(
        label: Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn2(
        label: Text("Estado", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn2(
        label: Text("Id", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ];
  }
}

class _EmployeesTableSource extends DataTableSource {
  final MessagesProvider provider;
  _EmployeesTableSource({required this.provider});

  @override
  DataRow? getRow(int index) =>
      DataRow.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => provider.filteredEmployees.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    MessageEmployee employeeItem = provider.filteredEmployees[index];

    Widget statusWidget = Chip(
      label: Text(
        CodeUtils.getEmployeeStatusName(employeeItem.status),
        style: TextStyle(
          color: employeeItem.status == 0 ||
                  employeeItem.status == 4 ||
                  employeeItem.status == 6 ||
                  employeeItem.status == 7
              ? Colors.black
              : Colors.white,
        ),
      ),
      backgroundColor: CodeUtils.getEmployeeStatusColor(
        employeeItem.status,
      ),
    );

    return <DataCell>[
      DataCell(
        Checkbox(
          value: employeeItem.isSelected,
          onChanged: (bool? newValue) =>
              provider.onEmployeeSelection(index, newValue!),
        ),
      ),
      DataCell(
        (employeeItem.imageUrl.isNotEmpty)
            ? CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(employeeItem.imageUrl),
              )
            : const CircleAvatar(
                radius: 20,
                child: Icon(
                  Icons.hide_image_outlined,
                ),
              ),
      ),
      DataCell(
        Text(
          CodeUtils.getFormatedName(employeeItem.names, employeeItem.lastNames),
        ),
      ),
      DataCell(statusWidget),
      DataCell(Text(employeeItem.id)),
    ];
  }
}
