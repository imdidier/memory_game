import 'package:flutter/material.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/code/code_utils.dart';
import '../../../../core/utils/ui/widgets/general/data_table_from_responsive.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';
import 'employees_payments_data_table.dart';

class EmployeesPaymentsWidgets extends StatefulWidget {
  const EmployeesPaymentsWidgets({Key? key}) : super(key: key);

  @override
  State<EmployeesPaymentsWidgets> createState() =>
      _EmployeesPaymentsWidgetsState();
}

class _EmployeesPaymentsWidgetsState extends State<EmployeesPaymentsWidgets> {
  bool isWidgetLoaded = false;
  late ScreenSize screenSize;
  late EmployeesProvider employeesProvider;
  TextEditingController searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    employeesProvider = Provider.of<EmployeesProvider>(context);

    super.didChangeDependencies();
  }

  List<List<String>> dataTableFromResponsive = [];

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    dataTableFromResponsive.clear();

    if (employeesProvider.filteredEmployees.isNotEmpty) {
      dataTableFromResponsive.clear();

      for (var payment in employeesProvider.filteredEmployeesPayments) {
        dataTableFromResponsive.add([
          "Imagen-${payment['employee_info']['image']}",
          "Id-${payment['employee_info']['id']}",
          "Nombre-${payment['employee_info']['fullname']}",
          "Teléfono-${payment['employee_info']['phone']}",
          "Total horas-${payment['total_hours']}",
          "Total pagar-${CodeUtils.formatMoney(payment['total_to_pay'])}",
          "Acciones-",
        ]);
      }
    }
    return Column(
      children: [
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowSpacing: 10,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 35),
              child: Text(
                "Total resultados: ${employeesProvider.filteredEmployeesPayments.length}",
                style: const TextStyle(fontSize: 16),
              ),
            ),
            _buildSearchBar(),
          ],
        ),
        const SizedBox(height: 15),
        screenSize.blockWidth >= 920
            ? EmployeesPaymentsDataTable(
                screenSize: screenSize,
                type: (employeesProvider.filteredEmployeesPayments.isEmpty)
                    ? "days"
                    : employeesProvider.filteredEmployeesPayments[0]["type"],
              )
            : DataTableFromResponsive(
                listData: dataTableFromResponsive,
                screenSize: screenSize,
                type: 'historical-payment-employees'),
      ],
    );
  }

  Align _buildSearchBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 30),
        width: screenSize.blockWidth >= 920
            ? screenSize.blockWidth * 0.3
            : screenSize.blockWidth,
        height: screenSize.height * 0.055,
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
            hintText: "Buscar colaborador",
            hintStyle: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onChanged: employeesProvider.filterEmployeesPayments,
        ),
      ),
    );
  }
}
