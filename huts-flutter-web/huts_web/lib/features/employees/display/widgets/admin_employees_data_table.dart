// ignore_for_file: use_build_context_synchronously
import 'dart:html' as html;

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/employee_services/employee_services.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/employees/display/widgets/lock_dialog.dart';
import 'package:huts_web/features/employees/display/widgets/requests_history_dialog.dart';
import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/router.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import 'change_phone_dialog.dart';

class AdminEmployeesDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  final List<Employee> filterEmployees;
  const AdminEmployeesDataTable(
      {required this.screenSize, Key? key, required this.filterEmployees})
      : super(key: key);

  @override
  State<AdminEmployeesDataTable> createState() =>
      _AdminEmployeesDataTableState();
}

class _AdminEmployeesDataTableState extends State<AdminEmployeesDataTable> {
  List<String> headers = [
    "Acciones",
    "Img",
    "Nombre",
    "Disponibilidad",
    "Último ingreso",
    "Nacimiento",
    "Documento",
    "Teléfono",
    "País",
    "Cargos",
    "Estado",
  ];

  bool _sortAscending = true;
  int? _sortColumnIndex;

  @override
  Widget build(BuildContext context) {
    EmployeesProvider provider = Provider.of<EmployeesProvider>(context);
    return SizedBox(
      height: widget.filterEmployees.length > 10
          ? widget.screenSize.height
          : widget.screenSize.height * 0.6,
      width: widget.screenSize.width,
      child: SelectionArea(
        child: PaginatedDataTable2(
          lmRatio: 0.9,
          smRatio: 0.6,
          minWidth: widget.screenSize.width,
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay información"),
            ),
          ),
          horizontalMargin: 10,
          columnSpacing: 15,
          columns: _getColums(),
          source: _EmployeesTableSource(
              provider: provider, filterEmployees: widget.filterEmployees),
          fixedLeftColumns: 3,
          rowsPerPage: 10,
          onRowsPerPageChanged: (value) {},
          availableRowsPerPage: const [10, 20, 50],
          sortAscending: _sortAscending,
          sortColumnIndex: _sortColumnIndex,
          sortArrowIcon: Icons.keyboard_arrow_up,
          sortArrowAnimationDuration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      if (columnIndex == 2) {
        widget.filterEmployees.sort((a, b) {
          String aName = CodeUtils.getFormatedName(
                  a.profileInfo.names, a.profileInfo.lastNames)
              .toLowerCase()
              .trim();
          String bName = CodeUtils.getFormatedName(
                  b.profileInfo.names, a.profileInfo.lastNames)
              .toLowerCase()
              .trim();

          if (ascending) return aName.compareTo(bName);

          return bName.compareTo(aName);
        });
        return;
      }

      if (columnIndex == 4) {
        widget.filterEmployees.sort((a, b) {
          DateTime aLastEntry = a.accountInfo.lastEntry != null
              ? a.accountInfo.lastEntry!
              : DateTime.now().subtract(const Duration(days: 3650));
          DateTime bLastEntry = b.accountInfo.lastEntry != null
              ? b.accountInfo.lastEntry!
              : DateTime.now().subtract(const Duration(days: 3650));

          if (ascending) return aLastEntry.compareTo(bLastEntry);

          return bLastEntry.compareTo(aLastEntry);
        });
        return;
      }

      if (columnIndex == 5) {
        widget.filterEmployees.sort((a, b) {
          DateTime aBirthday = a.profileInfo.birthday;
          DateTime bBirthday = b.profileInfo.birthday;

          if (ascending) return aBirthday.compareTo(bBirthday);

          return bBirthday.compareTo(aBirthday);
        });
        return;
      }

      if (columnIndex == 6) {
        widget.filterEmployees.sort((a, b) {
          String aDoc = a.profileInfo.docNumber;
          String bDoc = b.profileInfo.docNumber;

          if (ascending) return aDoc.compareTo(bDoc);

          return bDoc.compareTo(aDoc);
        });
        return;
      }

      if (columnIndex == 9) {
        widget.filterEmployees.sort((a, b) {
          String aJobs = UiMethods.getJobsNamesBykeys(a.jobs);
          String bJobs = UiMethods.getJobsNamesBykeys(b.jobs);

          if (ascending) return aJobs.compareTo(bJobs);

          return bJobs.compareTo(aJobs);
        });
        return;
      }

      if (columnIndex == 10) {
        widget.filterEmployees.sort((a, b) {
          String aStatus = CodeUtils.getEmployeeStatusName(a.accountInfo.status)
              .toLowerCase()
              .trim();
          String bStatus = CodeUtils.getEmployeeStatusName(b.accountInfo.status)
              .toLowerCase()
              .trim();

          if (ascending) return aStatus.compareTo(bStatus);

          return bStatus.compareTo(aStatus);
        });
        return;
      }
    });
  }

  List<DataColumn2> _getColums() {
    List<DataColumn2> columns = headers.map(
      (String header) {
        return DataColumn2(
          onSort: _sort,
          size: (header == "Disponibilidad" ||
                  header == "Nombre" ||
                  header == "Estado" ||
                  header == "Cargos" ||
                  header == "Id" ||
                  header == "Último ingreso")
              ? ColumnSize.L
              : (header == "Img" || header == "País" || header == "Teléfono")
                  ? ColumnSize.S
                  : ColumnSize.M,
          label: CustomTooltip(
            message:
                header == 'Último ingreso' ? 'Último ingreso a la app' : header,
            child: Text(
              header,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    ).toList();
    return columns;
  }
}

class _EmployeesTableSource extends DataTableSource {
  final EmployeesProvider provider;
  final List<Employee> filterEmployees;
  _EmployeesTableSource(
      {required this.provider, required this.filterEmployees});

  @override
  DataRow? getRow(int index) =>
      DataRow.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => filterEmployees.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    Employee employee = filterEmployees[index];
    int employeeStatus = employee.accountInfo.status;
    RichText? availability;
    //TextSpan? children;
    List<TextSpan> availabilityL = [],
        availabilityM = [],
        availabilityW = [],
        availabilityJ = [],
        availabilityV = [],
        availabilityS = [],
        availabilityD = [];
    for (var element in employee.availability.values) {
      switch (element['name']) {
        case 'Lun':
          availabilityL.add(
            TextSpan(
              text: 'L',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: element['morning_shift_enabled'] == true
                    ? Colors.green
                    : Colors.grey,
              ),
            ),
          );
          availabilityL.add(TextSpan(
              text: 'L',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['afternoon_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityL.add(
            TextSpan(
                text: 'L',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: element['night_shift_enabled'] == true
                        ? Colors.green
                        : Colors.grey)),
          );
          break;
        case 'Mar':
          availabilityM.add(TextSpan(
              text: 'M',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['morning_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityM.add(TextSpan(
              text: 'M',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['afternoon_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityM.add(
            TextSpan(
                text: 'M',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: element['night_shift_enabled'] == true
                        ? Colors.green
                        : Colors.grey)),
          );
          break;
        case 'Mier':
          availabilityW.add(TextSpan(
              text: 'W',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['morning_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityW.add(TextSpan(
              text: 'W',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['afternoon_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityW.add(
            TextSpan(
                text: 'W',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: element['night_shift_enabled'] == true
                        ? Colors.green
                        : Colors.grey)),
          );
          break;
        case 'Jue':
          availabilityJ.add(TextSpan(
              text: 'J',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['morning_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityJ.add(TextSpan(
              text: 'J',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['afternoon_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityJ.add(
            TextSpan(
                text: 'J',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: element['night_shift_enabled'] == true
                        ? Colors.green
                        : Colors.grey)),
          );
          break;
        case 'Vie':
          availabilityV.add(TextSpan(
              text: 'V',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['morning_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityV.add(TextSpan(
              text: 'V',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['afternoon_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityV.add(
            TextSpan(
                text: 'V',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: element['night_shift_enabled'] == true
                        ? Colors.green
                        : Colors.grey)),
          );
          break;
        case 'Sab':
          availabilityS.add(TextSpan(
              text: 'S',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['morning_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityS.add(TextSpan(
              text: 'S',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['afternoon_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityS.add(
            TextSpan(
                text: 'S',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: element['night_shift_enabled'] == true
                        ? Colors.green
                        : Colors.grey)),
          );
          break;
        case 'Dom':
          availabilityD.add(TextSpan(
              text: 'D',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['morning_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityD.add(TextSpan(
              text: 'D',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: element['afternoon_shift_enabled'] == true
                      ? Colors.green
                      : Colors.grey)));
          availabilityD.add(
            TextSpan(
                text: 'D',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: element['night_shift_enabled'] == true
                        ? Colors.green
                        : Colors.grey)),
          );
          break;
        default:
      }
      availability = RichText(
        text: TextSpan(
          text: '',
          children: <TextSpan>[
            for (var l = 0; l < availabilityL.length; l++) availabilityL[l],
            const TextSpan(text: ' - '),
            for (var m = 0; m < availabilityM.length; m++) availabilityM[m],
            const TextSpan(text: ' - '),
            for (var w = 0; w < availabilityW.length; w++) availabilityW[w],
            const TextSpan(text: ' - '),
            for (var j = 0; j < availabilityJ.length; j++) availabilityJ[j],
            const TextSpan(text: ' - '),
            for (var v = 0; v < availabilityV.length; v++) availabilityV[v],
            const TextSpan(text: ' - '),
            for (var s = 0; s < availabilityS.length; s++) availabilityS[s],
            const TextSpan(text: ' - '),
            for (var d = 0; d < availabilityD.length; d++) availabilityD[d],
          ],
        ),
      );
    }
    String employeeFullname = CodeUtils.getFormatedName(
        employee.profileInfo.names, employee.profileInfo.lastNames);

    String statusName =
        CodeUtils.getEmployeeStatusName(employee.accountInfo.status);

    Widget statusWidget = CustomTooltip(
      message: statusName,
      child: Chip(
        label: Text(statusName,
            style: TextStyle(
              fontSize: 12,
              color: employee.accountInfo.status == 0 ||
                      employee.accountInfo.status == 4 ||
                      employee.accountInfo.status == 6 ||
                      employee.accountInfo.status == 7
                  ? Colors.black
                  : Colors.white,
            )),
        backgroundColor: CodeUtils.getEmployeeStatusColor(
          employee.accountInfo.status,
        ),
      ),
    );

    return <DataCell>[
      DataCell(
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildDetailsBtn(employee, globalContext!),
            _buildHistoricalBtn(employee),
            buildChangePhoneBtn(employee),
            if (employeeStatus == 1 ||
                employeeStatus == 7 ||
                employeeStatus == 5)
              buildenableDisableBtn(
                  employeeStatus, employeeFullname, employee, globalContext),
            if (employeeStatus != 2)
              buildLockUnlockBtn(employee, employeeFullname, globalContext),
            if (employeeStatus != 2)
              CustomTooltip(
                message: "Eliminar",
                child: InkWell(
                  onTap: () async {
                    bool itsConfirmed = await confirm(
                      globalContext,
                      title: Text(
                        "Eliminar colaborador",
                        style: TextStyle(
                          color: UiVariables.primaryColor,
                        ),
                      ),
                      content: RichText(
                        text: TextSpan(
                          text: '¿Quieres eliminar a ',
                          children: <TextSpan>[
                            TextSpan(
                              text: employeeFullname,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      textCancel: const Text(
                        "Cancelar",
                        style: TextStyle(color: Colors.grey),
                      ),
                      textOK: const Text(
                        "Aceptar",
                        style: TextStyle(color: Colors.blue),
                      ),
                    );

                    if (!itsConfirmed) return;

                    UiMethods().showLoadingDialog(context: globalContext);
                    bool resp = await EmployeeServices.delete(
                      employee.id,
                      CodeUtils.getFormatedName(
                        employee.profileInfo.names,
                        employee.profileInfo.lastNames,
                      ),
                      globalContext,
                    );
                    UiMethods().hideLoadingDialog(context: globalContext);

                    if (resp) {
                      EmployeesProvider employeesProvider =
                          Provider.of<EmployeesProvider>(
                        globalContext,
                        listen: false,
                      );
                      employeesProvider.updateLocalEmployeesList(
                        isDelete: true,
                        index: employeesProvider.filteredEmployees.indexWhere(
                          (element) => element.id == employee.id,
                        ),
                      );
                      LocalNotificationService.showSnackBar(
                        type: "success",
                        message: "Colaborador eliminado correctamente",
                        icon: Icons.check,
                      );
                    } else {
                      LocalNotificationService.showSnackBar(
                        type: "fail",
                        message: "Ocurrió un error, intenta nuevamente",
                        icon: Icons.error_outline,
                      );
                    }
                  },
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
              )
          ],
        ),
      ),
      DataCell(
        employee.profileInfo.image.isNotEmpty
            ? CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(employee.profileInfo.image),
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
          CodeUtils.getFormatedName(
              employee.profileInfo.names, employee.profileInfo.lastNames),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(availability!),
      DataCell(
        Center(
          child: Text(
            employee.accountInfo.lastEntry != null
                ? CodeUtils.formatDate(employee.accountInfo.lastEntry!)
                : '-----------',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.formatDateWithoutHour(employee.profileInfo.birthday),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(Text(
        employee.profileInfo.docNumber,
        style: const TextStyle(fontSize: 13),
      )),
      DataCell(Text(
        employee.profileInfo.phone,
        style: const TextStyle(fontSize: 13),
      )),
      const DataCell(Text(
        "Costa Rica",
        style: TextStyle(fontSize: 13),
      )),
      DataCell(Text(
        UiMethods.getJobsNamesBykeys(employee.jobs),
        style: const TextStyle(fontSize: 13),
      )),
      DataCell(statusWidget),
    ];
  }

  Row buildLockUnlockBtn(
      Employee employee, String employeeFullname, BuildContext? globalContext) {
    return Row(
      children: [
        CustomTooltip(
          message:
              (employee.accountInfo.status == 3) ? "Desbloquear" : "Bloquear",
          child: InkWell(
            onTap: () async {
              if (globalContext == null) return;

              if (employee.accountInfo.status == 3) {
                bool itsConfirmed = await confirm(
                  globalContext,
                  title: Text(
                    "Desbloquear colaborador",
                    style: TextStyle(
                      color: UiVariables.primaryColor,
                    ),
                  ),
                  content: RichText(
                    text: TextSpan(
                      text: '¿Quieres desbloquear a ',
                      children: <TextSpan>[
                        TextSpan(
                          text: '$employeeFullname?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  textCancel: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                  textOK: const Text(
                    "Aceptar",
                    style: TextStyle(color: Colors.blue),
                  ),
                );

                if (!itsConfirmed) return;

                UiMethods().showLoadingDialog(context: globalContext);
                bool resp = await EmployeeServices.unlock(
                  employee.id,
                  CodeUtils.getFormatedName(
                    employee.profileInfo.names,
                    employee.profileInfo.lastNames,
                  ),
                );
                UiMethods().hideLoadingDialog(context: globalContext);

                if (resp) {
                  employee.accountInfo.status = 1;
                  employee.accountInfo.unlockDate = DateTime.now();
                  Provider.of<EmployeesProvider>(
                    globalContext,
                    listen: false,
                  ).updateLocalEmployeeData(employee);
                  LocalNotificationService.showSnackBar(
                    type: "success",
                    message: "Colaborador desbloqueado correctamente",
                    icon: Icons.check,
                  );
                } else {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "Ocurrió un error, intenta nuevamente",
                    icon: Icons.error_outline,
                  );
                }
                return;
              }
              await LockDialog.show(employee);
            },
            child: Icon(
              (employee.accountInfo.status == 3)
                  ? Icons.lock_open_rounded
                  : Icons.lock_clock_rounded,
              color: Colors.black54,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  CustomTooltip buildChangePhoneBtn(Employee employee) {
    return CustomTooltip(
      message: "Cambiar número teléfono",
      child: InkWell(
        onTap: () async => await ChangePhoneDialog.show(employee),
        child: const Icon(
          Icons.phone_android_rounded,
          color: Colors.black54,
          size: 20,
        ),
      ),
    );
  }

  CustomTooltip buildDetailsBtn(Employee employee, BuildContext context) {
    return CustomTooltip(
      message: "Ver detalles",
      child: InkWell(
        onTap: () {
          html.window.open(
              "/admin-v2/#${CustomRouter.employeeDetails.replaceAll(":id", employee.id)}",
              "_blank");
        },
        child: const Icon(
          Icons.account_circle,
          color: Colors.black54,
          size: 20,
        ),
      ),
    );
  }

  CustomTooltip _buildHistoricalBtn(
    Employee employee,
  ) {
    return CustomTooltip(
      message: "Ver historial solicitudes",
      child: InkWell(
        onTap: () => EmployeesRequestsHistoryDialog.show(employee),
        child: const Icon(
          Icons.history,
          color: Colors.black54,
          size: 22,
        ),
      ),
    );
  }

  Row buildenableDisableBtn(int employeeStatus, String employeeFullname,
      Employee employee, BuildContext? globalContext) {
    return Row(
      children: [
        CustomTooltip(
          message: (employeeStatus == 5) ? "Habilitar" : "Deshabilitar",
          child: InkWell(
            onTap: () async {
              if (globalContext == null) return;

              bool itsConfirmed = await confirm(
                globalContext,
                title: Text(
                  (employeeStatus == 5)
                      ? "Habilitar colaborador"
                      : "Deshabilitar colaborador",
                  style: TextStyle(
                    color: UiVariables.primaryColor,
                  ),
                ),
                content: RichText(
                  text: TextSpan(
                    text: (employeeStatus == 5)
                        ? '¿Quieres habilitar a '
                        : '¿Quieres deshabilitar a ',
                    children: <TextSpan>[
                      TextSpan(
                        text: '$employeeFullname?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                textCancel: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.grey),
                ),
                textOK: const Text(
                  "Aceptar",
                  style: TextStyle(color: Colors.blue),
                ),
              );

              if (!itsConfirmed) return;

              UiMethods().showLoadingDialog(context: globalContext);
              int newStatus = employeeStatus == 5 ? 1 : 5;
              bool resp = await EmployeeServices.enableDisable(
                {
                  "name": CodeUtils.getFormatedName(
                    employee.profileInfo.names,
                    employee.profileInfo.lastNames,
                  ),
                  "id": employee.id,
                  "to_disable": employeeStatus != 5,
                  "new_status": newStatus
                },
                globalContext,
              );
              UiMethods().hideLoadingDialog(context: globalContext);

              String doneAction =
                  employeeStatus == 5 ? "Habilitado" : "Deshabilitado";
              if (resp) {
                employee.accountInfo.status = newStatus;
                Provider.of<EmployeesProvider>(
                  globalContext,
                  listen: false,
                ).updateLocalEmployeeData(employee);
                LocalNotificationService.showSnackBar(
                  type: "success",
                  message: "Colaborador $doneAction correctamente",
                  icon: Icons.check,
                );
              } else {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Ocurrió un error, intenta nuevamente",
                  icon: Icons.error_outline,
                );
              }
            },
            child: Icon(
              (employeeStatus == 5)
                  ? Icons.check_box_rounded
                  : Icons.disabled_by_default_rounded,
              color: Colors.black54,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
