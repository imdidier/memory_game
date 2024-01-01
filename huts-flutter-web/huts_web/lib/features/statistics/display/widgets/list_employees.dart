import 'package:flutter/material.dart';

import '../../../../core/use_cases_params/excel_params.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../../core/utils/ui/widgets/general/export_to_excel_btn.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../domain/entities/employee_fav.dart';
import 'employee_fav_card.dart';

class ListViewEmployees extends StatefulWidget {
  const ListViewEmployees({
    Key? key,
    required this.screenSize,
    required this.uiVariables,
    required this.titleList,
    required this.employeesToShow,
    required this.showWorkedHours,
    required this.isDesktop,
  }) : super(key: key);

  final ScreenSize screenSize;
  final UiVariables uiVariables;
  final String titleList;
  final List<ClientEmployee> employeesToShow;
  final bool showWorkedHours;
  final bool isDesktop;

  @override
  State<ListViewEmployees> createState() => _ListViewEmployeesState();
}

class _ListViewEmployeesState extends State<ListViewEmployees> {
  TextEditingController topEmployeesSearchController = TextEditingController();
  bool isLoaded = false;
  bool isFirstTime = true;
  List<ClientEmployee> filteredEmployees = [];
  List<ClientEmployee> oldEmployeesToShow = [];

  @override
  void didChangeDependencies() {
    if (!isLoaded) {
      isLoaded = true;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (widget.isDesktop && widget.titleList == 'Colaboradores favoritos')
          ? widget.screenSize.blockWidth * 0.15
          : (widget.isDesktop &&
                  widget.titleList == 'Top colaboradores por horas trabajadas')
              ? widget.screenSize.width / 2.45
              : widget.screenSize.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.titleList,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              widget.employeesToShow.isEmpty ||
                      widget.titleList == 'Colaboradores favoritos'
                  ? const SizedBox()
                  : ExportToExcelBtn(
                      params: _getExcelParams(filteredEmployees.isEmpty
                          ? widget.employeesToShow
                          : filteredEmployees),
                      title: 'Exportar Excel',
                    )
            ],
          ),
          SizedBox(
            height: widget.screenSize.height * 0.02,
          ),
          Column(
            children: [
              if (widget.titleList != 'Colaboradores favoritos')
                buildClientSearchField(),
              const SizedBox(height: 15),
              SizedBox(
                height: widget.screenSize.height * 0.34,
                child: filteredEmployees
                        .any((element) => element.fullname == "null null")
                    ? const Center(
                        child: Text("No hay información disponible"),
                      )
                    : ListView.builder(
                        itemCount: isFirstTime
                            ? widget.employeesToShow.length
                            : filteredEmployees.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: 10, left: 4, right: 6),
                          child: (isFirstTime
                                  ? widget.employeesToShow[index].fullname !=
                                      "null null"
                                  : filteredEmployees[index].fullname !=
                                      "null null")
                              ? EmployeeFavCard(
                                  screenSize: widget.screenSize,
                                  uiVariables: widget.uiVariables,
                                  index: index,
                                  employeesToShow: isFirstTime
                                      ? widget.employeesToShow
                                      : filteredEmployees,
                                  showHoursWorked: widget.showWorkedHours,
                                )
                              : const SizedBox(),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ExcelParams _getExcelParams(List<ClientEmployee> filteredEmployees) {
    return ExcelParams(
      headers: [
        {
          "key": "employee_fullname",
          "display_name": "Nombre colaborador",
          "width": 300,
        },
        {
          "key": "phone",
          "display_name": "Número celular",
          "width": 130,
        },
        {
          "key": "hours_worked",
          "display_name": "Horas trabajadas",
          "width": 130,
        },
      ],
      data: List.generate(
        filteredEmployees.length,
        (index) {
          ClientEmployee employee = filteredEmployees[index];

          return {
            "employee_fullname": employee.fullname,
            "phone": employee.phone,
            "hours_worked": employee.hoursWorked,
          };
        },
      ),
      otherInfo: {},
      fileName: "listado_top_colaboradorespor_horas_trabajadas",
    );
  }

  Container buildClientSearchField() {
    return Container(
      height: widget.screenSize.height * 0.055,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 2),
            color: Colors.black26,
            blurRadius: 2,
          )
        ],
      ),
      child: TextField(
        controller: topEmployeesSearchController,
        cursorColor: UiVariables.primaryColor,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.search),
          hintText: "Buscar en top colaboradores",
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        onChanged: (value) => filterTopEmployees(
          value.toLowerCase(),
        ),
      ),
    );
  }

  void filterTopEmployees(String query) {
    oldEmployeesToShow = [...widget.employeesToShow];
    isFirstTime = false;

    if (query.isEmpty) {
      filteredEmployees = [...widget.employeesToShow];
      setState(() {});
      return;
    }
    filteredEmployees.clear();

    for (ClientEmployee employee in widget.employeesToShow) {
      if (employee.fullname.toLowerCase().contains(query)) {
        filteredEmployees.add(employee);
        continue;
      }
    }
    setState(() {});
  }
}
