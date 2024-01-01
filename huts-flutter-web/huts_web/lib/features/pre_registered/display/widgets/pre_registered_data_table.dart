// ignore_for_file: use_build_context_synchronously

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/pre_registered/display/provider/pre_registered_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/router.dart';
import '../../../../core/services/employee_services/employee_services.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/code/code_utils.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../../core/utils/ui/widgets/general/custom_tooltip.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../employees/display/provider/employees_provider.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import 'dart:html' as html;

class PreRegisteredDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  const PreRegisteredDataTable({required this.screenSize, super.key});

  @override
  State<PreRegisteredDataTable> createState() => _PreRegisteredDataTableState();
}

class _PreRegisteredDataTableState extends State<PreRegisteredDataTable> {
  bool _sortAscending = true;
  int? _sortColumnIndex;

  late PreRegisteredProvider provider;

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<PreRegisteredProvider>(context);
    return SizedBox(
      height: provider.filteredEmployees.length > 10
          ? widget.screenSize.height
          : widget.screenSize.height * 0.5,
      width: widget.screenSize.blockWidth,
      child: SelectionArea(
        child: PaginatedDataTable2(
          lmRatio: 2,
          minWidth: widget.screenSize.blockWidth,
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay información"),
            ),
          ),
          horizontalMargin: 20,
          columnSpacing: 10,
          dataRowHeight: kMinInteractiveDimension + 15,
          fixedLeftColumns: 3,
          rowsPerPage: 10,
          onRowsPerPageChanged: (value) {},
          columns: _getColums(),
          source: _EmployeesTableSource(provider: provider),
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
        provider.filteredEmployees.sort((a, b) {
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

      if (columnIndex == 3) {
        provider.filteredEmployees.sort((a, b) {
          String aDoc = a.profileInfo.docNumber.toLowerCase().trim();
          String bDoc = b.profileInfo.docNumber.toLowerCase().trim();

          if (ascending) return aDoc.compareTo(bDoc);

          return bDoc.compareTo(aDoc);
        });
        return;
      }

      if (columnIndex == 4) {
        provider.filteredEmployees.sort((a, b) {
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
        provider.filteredEmployees.sort((a, b) {
          String aDoc = a.profileInfo.phone.toLowerCase().trim();
          String bDoc = b.profileInfo.phone.toLowerCase().trim();

          if (ascending) return aDoc.compareTo(bDoc);

          return bDoc.compareTo(aDoc);
        });
        return;
      }

      if (columnIndex == 6) {
        provider.filteredEmployees.sort((a, b) {
          DateTime aBirthday = a.profileInfo.birthday;
          DateTime bBirthday = b.profileInfo.birthday;

          if (ascending) return aBirthday.compareTo(bBirthday);

          return bBirthday.compareTo(aBirthday);
        });
        return;
      }

      if (columnIndex == 8) {
        provider.filteredEmployees.sort((a, b) {
          String aJobs = UiMethods.getJobsNamesBykeys(a.jobs);
          String bJobs = UiMethods.getJobsNamesBykeys(b.jobs);

          if (ascending) return aJobs.compareTo(bJobs);

          return bJobs.compareTo(aJobs);
        });
        return;
      }

      if (columnIndex == 9) {
        provider.filteredEmployees.sort((a, b) {
          String aDocsStatus = a.docsStatus.text.toLowerCase();
          String bDocsStatus = b.docsStatus.text.toLowerCase();

          if (ascending) return aDocsStatus.compareTo(bDocsStatus);

          return bDocsStatus.compareTo(aDocsStatus);
        });
        return;
      }

      if (columnIndex == 10) {
        provider.filteredEmployees.sort((a, b) {
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
    List<String> headers = [
      "Acciones",
      "Img",
      "Nombre",
      "Documento",
      'Último ingreso',
      "Teléfono",
      "Nacimineto:Fecha de nacimiento",
      "País",
      "Cargos",
      "Estado docs:Estado documentos",
      "Estado",
      "Registro:Fecha registro",
      "Id",
    ];

    List<DataColumn2> columns = headers.map(
      (String header) {
        return DataColumn2(
          onSort: _sort,
          size: header == "Img" ? ColumnSize.M : ColumnSize.L,
          label: CustomTooltip(
            message: header.contains(":")
                ? header.split(":")[1]
                : header.contains('Último ingreso')
                    ? 'Último ingreso a la app'
                    : header,
            child: Text(
              header.split(":")[0],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    ).toList();
    return columns;
  }
}

class _EmployeesTableSource extends DataTableSource {
  final PreRegisteredProvider provider;
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
    Employee employee = provider.filteredEmployees[index];

    Widget statusWidget = Chip(
      label: Text(
        CodeUtils.getEmployeeStatusName(employee.accountInfo.status),
        style: TextStyle(
          color: employee.accountInfo.status == 0 ||
                  employee.accountInfo.status == 4 ||
                  employee.accountInfo.status == 6 ||
                  employee.accountInfo.status == 7
              ? Colors.black
              : Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: CodeUtils.getEmployeeStatusColor(
        employee.accountInfo.status,
      ),
    );

    String employeeFullname = CodeUtils.getFormatedName(
        employee.profileInfo.names, employee.profileInfo.lastNames);

    BuildContext? globalContext = NavigationService.getGlobalContext();

    return <DataCell>[
      DataCell(
        Row(
          children: [
            CustomTooltip(
              message: "Ver detalles",
              child: InkWell(
                onTap: () => html.window.open(
                    "/admin-v2/#${CustomRouter.preRegisteredDetails.replaceAll(":id", employee.id)}",
                    "_blank"),
                child: const Icon(
                  Icons.account_circle,
                  color: Colors.black54,
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 10),
            CustomTooltip(
              message: "Aprobar",
              child: InkWell(
                onTap: () async {
                  BuildContext? globalContext =
                      NavigationService.getGlobalContext();

                  if (globalContext == null) return;

                  bool itsConfirmed = await confirm(
                    globalContext,
                    title: Text(
                      "Aprobar colaborador",
                      style: TextStyle(
                        color: UiVariables.primaryColor,
                      ),
                    ),
                    content: const SizedBox(
                      width: 400,
                      child: Text(
                        "¿Quieres aprobar a este colaborador? Este cambio le permitirá recibir solicitudes",
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

                  if (employee.docsStatus.value == 0) {
                    bool aproveWithoutDocs = await confirm(
                      globalContext,
                      title: Text(
                        "Sin documentos requeridos",
                        style: TextStyle(
                          color: UiVariables.primaryColor,
                        ),
                      ),
                      content: const SizedBox(
                        width: 400,
                        child: Text(
                          "El colaborador no ha subido ningún documento requerido. ¿Quieres aprobarlo de todas formas?",
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

                    if (aproveWithoutDocs) {
                      UiMethods().showLoadingDialog(
                        context: globalContext,
                      );

                      await provider.approveEmployee(
                        employee.id,
                        CodeUtils.getFormatedName(
                          employee.profileInfo.names,
                          employee.profileInfo.lastNames,
                        ),
                        globalContext,
                      );

                      UiMethods().hideLoadingDialog(context: globalContext);
                    }

                    // LocalNotificationService.showSnackBar(
                    //   type: "fail",
                    //   message:
                    //       "El colaborador no ha subido ningún documento requerido",
                    //   icon: Icons.error_outline,
                    // );
                    return;
                  }

                  if (employee.docsStatus.value == 1) {
                    bool aproveWithSomeDocs = await confirm(
                      globalContext,
                      title: Text(
                        "Faltan documentos requeridos",
                        style: TextStyle(
                          color: UiVariables.primaryColor,
                        ),
                      ),
                      content: const SizedBox(
                        width: 400,
                        child: Text(
                          "El colaborador no ha subido todos los documentos requeridos. ¿Quieres aprobarlo de todas formas?",
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

                    if (aproveWithSomeDocs) {
                      UiMethods().showLoadingDialog(
                        context: globalContext,
                      );

                      await provider.approveEmployee(
                        employee.id,
                        CodeUtils.getFormatedName(
                          employee.profileInfo.names,
                          employee.profileInfo.lastNames,
                        ),
                        globalContext,
                      );

                      UiMethods().hideLoadingDialog(context: globalContext);
                    }

                    // LocalNotificationService.showSnackBar(
                    //   type: "fail",
                    //   message:
                    //       "El colaborador aún no ha subido todos los documentos requeridos",
                    //   icon: Icons.error_outline,
                    // );
                    return;
                  }

                  Map<String, dynamic> generalDocsData =
                      Provider.of<GeneralInfoProvider>(
                    globalContext,
                    listen: false,
                  ).generalInfo.countryInfo.requiredDocs;
                  //Validate if all added required docs are approved
                  bool allApproved = true;

                  for (String generalDocKey in generalDocsData.keys.toList()) {
                    if (employee.documents.values.toList().any(
                          (employeeDoc) =>
                              employeeDoc["value"] == generalDocKey &&
                              generalDocsData[generalDocKey]["required"] &&
                              employeeDoc["approval_status"] != 1,
                        )) {
                      allApproved = false;

                      break;
                    }
                  }

                  if (!allApproved) {
                    bool aproveWithoutDocsAprovement = await confirm(
                      globalContext,
                      title: Text(
                        "Documentos requeridos sin aprobados",
                        style: TextStyle(
                          color: UiVariables.primaryColor,
                        ),
                      ),
                      content: const SizedBox(
                        width: 400,
                        child: Text(
                          "Aún no se han aprobado todos los documentos requeridos del colaborador. ¿Quieres aprobarlo de todas formas?",
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

                    if (aproveWithoutDocsAprovement) {
                      UiMethods().showLoadingDialog(
                        context: globalContext,
                      );

                      await provider.approveEmployee(
                        employee.id,
                        CodeUtils.getFormatedName(
                          employee.profileInfo.names,
                          employee.profileInfo.lastNames,
                        ),
                        globalContext,
                      );

                      UiMethods().hideLoadingDialog(context: globalContext);
                    }

                    //  LocalNotificationService.showSnackBar(
                    //     type: "fail",
                    //     message:
                    //         "Todos los documentos requeridos del colaborador deben estar aprobados",
                    //     icon: Icons.error_outline,
                    //   );

                    return;
                  }

                  UiMethods().showLoadingDialog(
                    context: globalContext,
                  );

                  await provider.approveEmployee(
                    employee.id,
                    CodeUtils.getFormatedName(
                      employee.profileInfo.names,
                      employee.profileInfo.lastNames,
                    ),
                    globalContext,
                  );

                  UiMethods().hideLoadingDialog(context: globalContext);
                },
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.black54,
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 10),
            CustomTooltip(
              message: "Eliminar",
              child: InkWell(
                onTap: () async {
                  if (globalContext == null) return;

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
            ),
          ],
        ),
      ),
      DataCell(
        CircleAvatar(
          backgroundImage: NetworkImage(employee.profileInfo.image),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.getFormatedName(
              employee.profileInfo.names, employee.profileInfo.lastNames),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(Text(
        employee.profileInfo.docNumber,
        style: const TextStyle(fontSize: 13),
      )),
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
      DataCell(Text(
        employee.profileInfo.phone,
        style: const TextStyle(fontSize: 13),
      )),
      DataCell(Text(
        CodeUtils.formatDateWithoutHour(employee.profileInfo.birthday),
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
      DataCell(employee.docsStatus.widget),
      DataCell(statusWidget),
      DataCell(Text(
        CodeUtils.formatDate(employee.accountInfo.registerDate),
        style: const TextStyle(fontSize: 13),
      )),
      DataCell(Text(
        employee.id,
        style: const TextStyle(fontSize: 13),
      )),
    ];
  }
}
