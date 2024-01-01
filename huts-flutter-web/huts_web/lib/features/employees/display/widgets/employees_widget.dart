import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/employees/display/widgets/admin_employees_data_table.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/code/code_utils.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';

class EmployeesWidget extends StatefulWidget {
  final int typeFilter;
  const EmployeesWidget({Key? key, required this.typeFilter}) : super(key: key);

  @override
  State<EmployeesWidget> createState() => _EmployeesWidgetState();
}

class _EmployeesWidgetState extends State<EmployeesWidget> {
  late EmployeesProvider employeesProvider;
  late ScreenSize screenSize;
  // TextEditingController searchController = TextEditingController();
  List<List<String>> dataTableFromResponsive = [];

  bool isWidgetLoaded = false;

  @override
  Widget build(BuildContext context) {
    employeesProvider = Provider.of<EmployeesProvider>(context);
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    return Column(
      children: [
        OverflowBar(
          spacing: 10,
          alignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 35),
                  child: Text(
                    "Total colaboradores: ${employeesProvider.filteredEmployees.length}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                builcSearchBar(),
              ],
            ),
          ],
        ),
        buildEmployees(),
      ],
    );
  }

  Widget builcSearchBar() {
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
          controller: employeesProvider.searchController,
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
          onChanged: employeesProvider.filterEmployees,
        ),
      ),
    );
  }

  Container buildEmployees() {
    dataTableFromResponsive.clear();

    if (employeesProvider.filteredEmployees.isNotEmpty &&
        screenSize.blockWidth < 920) {
      dataTableFromResponsive.clear();
      for (var employee in employeesProvider.filteredEmployees) {
        dataTableFromResponsive.add([
          "Imagen-${employee.profileInfo.image}",
          "Nombre-${CodeUtils.getFormatedName(employee.profileInfo.names, employee.profileInfo.lastNames)}",
          "Disponibilidad-",
          "Nacimiento-${CodeUtils.formatDateWithoutHour(employee.profileInfo.birthday)}",
          "Documento-${employee.profileInfo.docNumber}",
          "Teléfono-${employee.profileInfo.phone}",
          "País-Costa Rica",
          "Cargos-${UiMethods.getJobsNamesBykeys(employee.jobs)}",
          "Estado-${employee.accountInfo.status}",
          "Id-${employee.id}",
          "Acciones-",
        ]);
      }
    }

    return Container(
      // color: Colors.red,
      margin: const EdgeInsets.only(top: 30),
      child: screenSize.blockWidth >= 920
          ? AdminEmployeesDataTable(
              screenSize: screenSize,
              filterEmployees: employeesProvider.filteredEmployees,
            )
          : DataTableFromResponsive(
              listData: dataTableFromResponsive,
              screenSize: screenSize,
              type: 'employees',
            ),
    );
  }
}
