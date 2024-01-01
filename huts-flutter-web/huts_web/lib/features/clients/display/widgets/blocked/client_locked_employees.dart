import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/employee_services/employee_services.dart';
import '../../../../../core/utils/code/code_utils.dart';
import '../../../../../core/utils/ui/ui_methods.dart';
import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../core/utils/ui/widgets/employees/employee_selection/dialog.dart';
import '../../../../../core/utils/ui/widgets/general/data_table_from_responsive.dart';
import '../../../../employees/display/provider/employees_provider.dart';
import '../../../../employees/domain/entities/employee_entity.dart';
import 'locks_data_table.dart';

class ClientLockedEmployees extends StatefulWidget {
  final ClientsProvider clientsProvider;
  const ClientLockedEmployees({Key? key, required this.clientsProvider})
      : super(key: key);

  @override
  State<ClientLockedEmployees> createState() => _ClientLockedEmployeesState();
}

class _ClientLockedEmployeesState extends State<ClientLockedEmployees> {
  late ScreenSize screenSize;
  List<List<String>> dataTableFromResponsive = [];

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    dataTableFromResponsive.clear();

    if (widget.clientsProvider.filteredLocks.isNotEmpty) {
      dataTableFromResponsive.clear();

      for (var locks in widget.clientsProvider.filteredLocks) {
        dataTableFromResponsive.add([
          'Foto-${locks['photo']}',
          'Nombre-${locks['fullname']}',
          'Teléfono-${locks['phone']}',
          'Cargos-${locks['jobs'].join(', ')}',
          'Id-${locks['uid']}',
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
                    "Bloqueados",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: screenSize.width * 0.016,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Información de colaboradores bloqueados del cliente",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: screenSize.width * 0.01,
                    ),
                  ),
                ],
              ),
              buildLockBtn(),
            ],
          ),
          const SizedBox(height: 30),
          screenSize.blockWidth >= 920
              ? _buildLocks()
              : DataTableFromResponsive(
                  listData: dataTableFromResponsive,
                  screenSize: screenSize,
                  type: 'locks'),
        ],
      ),
    );
  }

  Widget _buildLocks() => ClientLocksDataTable(screenSize: screenSize);

  InkWell buildLockBtn() {
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
        bool resp = await widget.clientsProvider.updateClientInfo(
          {
            "action": "add",
            "employees": employees,
          },
          "locks",
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
            "Agregar bloqueado",
            style: TextStyle(
              color: Colors.white,
              fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
            ),
          ),
        ),
      ),
    );
  }
}
