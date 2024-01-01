import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../../features/employees/data/models/employee_change_model.dart';
import '../../../../../../features/employees/display/provider/employees_provider.dart';
import '../../../ui_variables.dart';

class DialogContent extends StatefulWidget {
  final List<Employee> employees;
  final List<int>? indexesList = [];
  final bool isAddFavOrLocks;
  DialogContent({
    required this.employees,
    required this.isAddFavOrLocks,
    indexesList,
    super.key,
  });

  @override
  State<DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<DialogContent> {
  ScreenSize? screenSize;
  int selectedIndex = -1;
  List<List<String>> dataTableFromResponsive = [];
  TextEditingController searchController = TextEditingController();
  late EmployeesProvider employeesProvider;
  List<EmployeeChange> employeeChange = [];
  List<EmployeeChange> allEmployees = [];

  bool isDataSetted = false;

  bool allSelected = false;

  @override
  void didChangeDependencies() {
    for (var element in widget.employees) {
      EmployeeChange employeeee = EmployeeChange(
        imageUrl: element.profileInfo.image,
        id: element.id,
        isSelected: false,
        jobs: element.jobs,
        phone: element.profileInfo.phone,
        lastNames: element.profileInfo.lastNames,
        names: element.profileInfo.names,
      );
      allEmployees.add(employeeee);
      employeeChange.add(employeeee);
    }
    super.didChangeDependencies();
  }

  @override
  void initState() {
    employeesProvider = Provider.of<EmployeesProvider>(context, listen: false);

    if (employeesProvider.filteredEmployees.isNotEmpty) {
      dataTableFromResponsive.clear();

      for (var employee in widget.employees) {
        dataTableFromResponsive.add([
          "Acciones-",
          "Foto-${employee.profileInfo.image}",
          "Nombre-${CodeUtils.getFormatedName(
            employee.profileInfo.names,
            employee.profileInfo.lastNames,
          )}",
          "Teléfono-${employee.profileInfo.phone}",
          "Cargos-${UiMethods.getJobsNamesBykeys(employee.jobs)}",
          "Id-${employee.id}",
        ]);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenSize ??=
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    dataTableFromResponsive.clear();
    employeesProvider.filteredPerJobEmployees =
        !widget.isAddFavOrLocks ? [...employeeChange] : [...allEmployees];

    return Container(
      width: screenSize!.blockWidth >= 920
          ? screenSize!.blockWidth * 0.6
          : screenSize!.blockWidth * 0.8,
      height: screenSize!.height >= 840
          ? screenSize!.height * 0.7
          : screenSize!.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(
                height: 80,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildSearchBar(),
                    _buildAceptBtn(),
                  ],
                ),
              ),
              SingleChildScrollView(
                controller: ScrollController(),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    margin: EdgeInsets.symmetric(
                      vertical: screenSize!.height * 0.02,
                    ),
                    child: screenSize!.blockWidth >= 920
                        ? EmployeesDataTable(
                            allEmployees: allEmployees,
                            employees: employeeChange,
                            screenSize: screenSize!,
                            isAddFavOrLocks: widget.isAddFavOrLocks,
                          )
                        : DataTableFromResponsive(
                            listData: dataTableFromResponsive,
                            screenSize: screenSize!,
                            type: 'add-lock')),
              ),
            ],
          ),
          _buildHeader(context),
        ],
      ),
    );
  }

  Container _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(List<Employee>.from([])),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: screenSize!.blockWidth >= 920 ? 20 : 15,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Selecciona un colaborador",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize!.blockWidth >= 920 ? 18 : 14,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAceptBtn() {
    return (screenSize!.blockWidth >= 920)
        ? InkWell(
            onTap: () {
              if (_TableSource.selectedEmployeesId.isEmpty) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes seleccionar un colaborador",
                  icon: Icons.error_outline,
                );
                return;
              }
              List<Employee> employees = [];
              for (String employeeId in _TableSource.selectedEmployeesId) {
                employees.add(widget.employees
                    .firstWhere((element) => element.id == employeeId));
              }
              Navigator.of(context).pop(employees);
              _TableSource.selectedEmployeesId = [];
            },
            child: Container(
              width: screenSize!.blockWidth > 920
                  ? screenSize!.blockWidth * 0.15
                  : 150,
              height: screenSize!.blockWidth > 920
                  ? screenSize!.height * 0.05
                  : screenSize!.height * 0.03,
              decoration: BoxDecoration(
                color: UiVariables.primaryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Aceptar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          )
        : const SizedBox();
  }

  Widget buildSearchBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        height: screenSize!.blockWidth >= 920 ? screenSize!.height * 0.055 : 30,
        width: screenSize!.blockWidth >= 920
            ? screenSize!.blockWidth * 0.25
            : screenSize!.blockWidth * 0.3,
        padding: const EdgeInsets.only(right: 10),
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
          decoration: InputDecoration(
            suffixIcon: Icon(
              Icons.search,
              size: screenSize!.blockWidth >= 920 ? 16 : 12,
            ),
            hintText: "Buscar Colaborador",
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: screenSize!.blockWidth >= 920 ? 14 : 10,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: screenSize!.blockWidth >= 920 ? 12 : 4),
          ),
          onChanged: (String query) => employeesProvider.filterPerJobEmployees(
            query,
            // widget.employees,
            !widget.isAddFavOrLocks ? employeeChange : allEmployees,
          ),
        ),
      ),
    );
  }
}

class EmployeesDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  final List<EmployeeChange> allEmployees;
  final List<EmployeeChange> employees;
  final bool isAddFavOrLocks;

  const EmployeesDataTable({
    required this.allEmployees,
    required this.screenSize,
    required this.employees,
    required this.isAddFavOrLocks,
    Key? key,
  }) : super(key: key);

  @override
  State<EmployeesDataTable> createState() => _EmployeesDataTableState();
}

class _EmployeesDataTableState extends State<EmployeesDataTable> {
  List<String> headers = [
    "Acciones",
    "Foto",
    "Nombre",
    // "Teléfono",
    "Cargos",
    // "Id",
  ];
  bool isDataSetted = false;
  bool allSelected = false;
  late EmployeesProvider employeesProvider;

  @override
  Widget build(BuildContext context) {
    employeesProvider = Provider.of<EmployeesProvider>(context);

    if (!isDataSetted && widget.isAddFavOrLocks) {
      for (var i = 0; i < widget.employees.length; i++) {
        widget.employees[i].isSelected = false;
      }
      _TableSource.selectedIndexes.clear();
      _TableSource.selectedEmployeesId.clear();
      employeesProvider
          .updateLocksOrFavsToEditIndexes(_TableSource.selectedIndexes);
      isDataSetted = true;
    }
    return SizedBox(
      height: widget.screenSize.height * 0.63,
      width: widget.screenSize.blockWidth,
      child: SelectionArea(
        child: PaginatedDataTable2(
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay información"),
            ),
          ),
          horizontalMargin: 20,
          columnSpacing: 30,
          columns: _getColums(),
          onRowsPerPageChanged: (value) {},
          availableRowsPerPage: const [10, 20, 50],
          source: _TableSource(
            employeesProvider: employeesProvider,
            employees: widget.employees,
            allEmployees: widget.allEmployees,
            onTapItem: (List<int> indexes) {
              _TableSource.selectedIndexes = indexes;
              employeesProvider
                  .updateLocksOrFavsToEditIndexes(_TableSource.selectedIndexes);
              for (var i = 0; i < widget.employees.length; i++) {
                widget.employees[i].isSelected = false;
              }
              for (int index in indexes) {
                int filteredIndex = 0;
                if (widget.isAddFavOrLocks) {
                  widget.allEmployees[index].isSelected = true;
                  filteredIndex = widget.employees.indexWhere(
                      (element) => element.id == widget.allEmployees[index].id);
                } else {
                  widget.employees[index].isSelected = true;
                  filteredIndex = widget.employees.indexWhere(
                      (element) => element.id == widget.employees[index].id);
                }
                if (filteredIndex != -1) {
                  widget.employees[filteredIndex].isSelected = true;
                }
              }
              setState(() {});
            },
            isAddFavOrLocks: widget.isAddFavOrLocks,
          ),
        ),
      ),
    );
  }

  List<DataColumn> _getColums() {
    return <DataColumn>[
      DataColumn(
        label: widget.employees.isNotEmpty && widget.isAddFavOrLocks
            ? Checkbox(
                value: widget.employees.every((element) => element.isSelected),
                onChanged: (bool? newValue) {
                  if (newValue!) {
                    for (EmployeeChange employee in widget.employees) {
                      int index = widget.allEmployees
                          .indexWhere((element) => element.id == employee.id);
                      widget.allEmployees[index].isSelected = true;
                      _TableSource.selectedIndexes.add(index);
                      _TableSource.selectedEmployeesId
                          .add(widget.employees[index].id);
                    }
                  } else {
                    for (EmployeeChange employee in widget.employees) {
                      int index = widget.employees
                          .indexWhere((element) => element.id == employee.id);
                      widget.allEmployees[index].isSelected = false;
                      _TableSource.selectedEmployeesId.clear();
                      _TableSource.selectedIndexes.clear();
                    }
                  }
                  employeesProvider.updateLocksOrFavsToEditIndexes(
                      _TableSource.selectedIndexes);
                  setState(() {});
                },
              )
            : const SizedBox(),
        tooltip: widget.employees.isNotEmpty ? 'Seleccionar todo' : '',
      ),
      const DataColumn(
        label: Text(
          "Foto",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
          label: Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold))),
      // const DataColumn(
      // label:
      // Text("Teléfono", style: TextStyle(fontWeight: FontWeight.bold))),
      const DataColumn(
          label: Text("Cargos", style: TextStyle(fontWeight: FontWeight.bold))),
      // const DataColumn(
      // label: Text("Id", style: TextStyle(fontWeight: FontWeight.bold))),
    ];
  }
}

class _TableSource extends DataTableSource {
  final EmployeesProvider employeesProvider;
  final List<EmployeeChange> allEmployees;
  final List<EmployeeChange> employees;
  final bool isAddFavOrLocks;

  final Function onTapItem;
  _TableSource({
    required this.allEmployees,
    required this.employeesProvider,
    required this.employees,
    required this.onTapItem,
    required this.isAddFavOrLocks,
  });

  static List<String> selectedEmployeesId = [];
  static List<int> selectedIndexes = [];

  @override
  DataRow? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => employeesProvider.filteredPerJobEmployees.length;
  // isAddFavOrLocks
  // ? employees.length
  // : employeesProvider.filteredPerJobEmployees.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    EmployeeChange employee = employeesProvider.filteredPerJobEmployees[index];

    // isAddFavOrLocks
    // ? employees[index]
    // : employeesProvider.filteredPerJobEmployees[index];
    int generalIndex =
        allEmployees.indexWhere((element) => element.id == employee.id);
    return <DataCell>[
      DataCell(
        Checkbox(
          value: isAddFavOrLocks
              ? selectedIndexes.contains(generalIndex) &&
                  allEmployees[generalIndex].isSelected
              : employee.isSelected,
          onChanged: (bool? newValue) {
            if (!isAddFavOrLocks) {
              onSelectedItems(generalIndex, newValue!, employee.id);
              employeesProvider.onEmployeeSelection(index, newValue);
            } else {
              onSelectedItems(generalIndex, newValue!, employee.id);
            }
          },
        ),
      ),
      DataCell(
        CircleAvatar(
          // backgroundImage: NetworkImage(employee.profileInfo.image),
          backgroundImage: NetworkImage(employee.imageUrl),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.getFormatedName(
            employee.names,
            employee.lastNames,
          ),
        ),
      ),
      // DataCell(Text(employee.phone)),
      DataCell(Text(UiMethods.getJobsNamesBykeys(employee.jobs))),
      // DataCell(Text(employee.id)),
    ];
  }

  onSelectedItems(int index, bool value, String employeeId) {
    if (value) {
      if (!isAddFavOrLocks) {
        selectedIndexes.clear();
        selectedEmployeesId.clear();
      }
      selectedIndexes.add(index);
      selectedEmployeesId.add(employeeId);
    } else {
      selectedIndexes.removeWhere((element) => element == index);
      selectedEmployeesId.removeWhere((element) => element == employeeId);
    }
    onTapItem(selectedIndexes);
  }
}
