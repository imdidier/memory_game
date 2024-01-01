import 'package:flutter/material.dart';
import 'package:huts_web/core/services/employee_services/employee_services.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/employees/employee_selection/dialog.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/clients/display/widgets/favorites/favs_data_table.dart';
import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../employees/display/provider/employees_provider.dart';

class ClientFavsEmployees extends StatefulWidget {
  final ClientsProvider clientsProvider;
  const ClientFavsEmployees({Key? key, required this.clientsProvider})
      : super(key: key);

  @override
  State<ClientFavsEmployees> createState() => _ClientFavsEmployeesState();
}

class _ClientFavsEmployeesState extends State<ClientFavsEmployees> {
  late ScreenSize screenSize;
  List<List<String>> dataTableFromResponsive = [];

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    dataTableFromResponsive.clear();

    if (widget.clientsProvider.filteredFavs.isNotEmpty) {
      dataTableFromResponsive.clear();

      for (var favs in widget.clientsProvider.filteredFavs) {
        dataTableFromResponsive.add([
          'Foto-${favs['photo']}',
          'Nombre-${favs['fullname']}',
          'Teléfono-${favs['phone']}',
          'Cargos-${favs['jobs'].join(', ')}',
          'Id-${favs['uid']}',
          'Acciones-'
        ]);
      }
    }
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowSpacing: 10,
            overflowAlignment: OverflowBarAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Favoritos",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: screenSize.width * 0.016,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Información de colaboradores favoritos del cliente",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: screenSize.width * 0.01,
                    ),
                  ),
                ],
              ),
              buildAddBtn(),
            ],
          ),
          const SizedBox(height: 30),
          screenSize.blockWidth >= 920
              ? _buildFavs()
              : DataTableFromResponsive(
                  listData: dataTableFromResponsive,
                  screenSize: screenSize,
                  type: 'favs'),
        ],
      ),
    );
  }

  Widget _buildFavs() => ClientFavsDataTable(screenSize: screenSize);

  InkWell buildAddBtn() {
    return InkWell(
      onTap: () async {
        UiMethods().showLoadingDialog(context: context);
        List<Employee>? gottenEmployees =
            await EmployeeServices.getClientEmployees(
          widget.clientsProvider.selectedClient!.accountInfo.id,
        );
        UiMethods().hideLoadingDialog(context: context);
        if (gottenEmployees == null) return;

        widget.clientsProvider.selectedClient!.favoriteEmployees.forEach(
          (key, value) {
            gottenEmployees.removeWhere(
              (element) => element.id == value["uid"],
            );
          },
        );

        widget.clientsProvider.selectedClient!.blockedEmployees.forEach(
          (key, value) {
            gottenEmployees.removeWhere(
              (element) => element.id == value["uid"],
            );
          },
        );
        EmployeesProvider employeeProvider = context.read<EmployeesProvider>();
        List<Employee?> selectedEmployees = await EmployeeSelectionDialog.show(
          employees: gottenEmployees,
          indexesList: employeeProvider.locksOrFavsToEditIndexes,
          isAddFavOrLocks: true,
        );
        if (selectedEmployees.isEmpty) return;
        Map<String, dynamic> employees = {};
        for (Employee? employee in selectedEmployees) {
          employees[employee!.id] = {
            "fullname": CodeUtils.getFormatedName(
              employee.profileInfo.names,
              employee.profileInfo.lastNames,
            ),
            "phone": employee.profileInfo.phone,
            "jobs": employee.jobs,
            "photo": employee.profileInfo.image,
            "uid": employee.id,
          };
        }

        UiMethods().showLoadingDialog(context: context);
        await widget.clientsProvider.updateClientInfo(
          {
            "action": "add",
            "employees": employees,
          },
          "favs",
          true,
        );

        UiMethods().hideLoadingDialog(context: context);
      },
      child: Container(
        height: screenSize.height * 0.045,
        width: screenSize.blockWidth > 1194
            ? screenSize.blockWidth * 0.2
            : screenSize.blockWidth * 0.35,
        decoration: BoxDecoration(
          color: UiVariables.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            "Agregar favorito",
            style: TextStyle(
              color: Colors.white,
              fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
            ),
          ),
        ),
      ),
    );
  }
}
