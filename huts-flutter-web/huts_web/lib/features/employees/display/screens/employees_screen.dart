import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_date_selector.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/employees/display/widgets/employees_widget.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';
import '../provider/employees_provider.dart';
import '../widgets/employees_payments_widget.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({Key? key}) : super(key: key);

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  bool isScreenLoaded = false;
  late ScreenSize screenSize;
  late EmployeesProvider employeesProvider;
  bool imageAvailable = false;
  Uint8List? imageFile;
  String imageUrl = '';

  List<Map<String, dynamic>> tabs = [
    {
      "name": "Lista colaboradores",
      "is_selected": true,
    },
    {
      "name": "Historial pagos",
      "is_selected": false,
    },
  ];

  List<Map<String, dynamic>> tabsEmployeeStatus = [
    {
      "name": "Todos",
      "is_selected": true,
      "value": 0,
    },
    {
      "name": "Disponibles",
      "is_selected": false,
      "value": 1,
    },
    {
      "name": "En turno",
      "is_selected": false,
      "value": 2,
    },
    {
      "name": "Bloqueados",
      "is_selected": false,
      "value": 3,
    },
    {
      "name": "Deshabilitados por admin",
      "is_selected": false,
      "value": 5,
    },
    {
      "name": "Deshabilitados por horas",
      "is_selected": false,
      "value": 6,
    },
    {
      "name": "Documentos vencido",
      "is_selected": false,
      "value": 7,
    },
  ];

  List<Map<String, dynamic>> employeeInfoTabs = [
    {
      "name": "Información",
      "text": "Información general del colaborador",
      "value": "info",
      "is_selected": true,
    },
    {
      "name": "Disponibilidad",
      "text": "Edita la disponibilidad del colaborador",
      "value": "availability",
      "is_selected": false,
    },
    {
      "name": "Documentos",
      "text": "Visualiza, aprueba o rechaza los documentos del colaborador",
      "value": "docs",
      "is_selected": false,
    },
    {
      "name": "Cargos",
      "text": "Visualiza y modifica los cargos del colaborador",
      "value": "jobs",
      "is_selected": false,
    },
    {
      "name": "Mensajes",
      "text": "Visualiza los mensajes enviados al colaborador",
      "value": "messages",
      "is_selected": false,
    },
    {
      "name": "Solicitudes",
      "text": "Visualiza las solicitudes del colaborador",
      "value": "requests",
      "is_selected": false,
    },
    {
      "name": "Actividad",
      "text": "Visualiza la actividad relacionada con el colaborador",
      "value": "activity",
      "is_selected": false,
    },
  ];

  int selectedEmployeeTab = 0;

  final ScrollController _scrollController = ScrollController();
  ValueNotifier<bool> showDateWidget = ValueNotifier<bool>(false);
  late AuthProvider authProvider;

  @override
  void didChangeDependencies() async {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    employeesProvider = Provider.of<EmployeesProvider>(context);
    authProvider = context.watch<AuthProvider>();
    if (employeesProvider.employees.isNotEmpty) {
      employeesProvider.filteredEmployees = employeesProvider.employees;
    }
    await setTabsInfo();
    super.didChangeDependencies();
  }

  Future<void> setTabsInfo() async {
    await Future.delayed(const Duration(milliseconds: 1200), () {
      if (authProvider.webUser.clientAssociationInfo.isNotEmpty) {
        tabs = [
          {
            "name": "Lista colaboradores",
            "is_selected": true,
          },
        ];
      }
    });
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;

    return SizedBox(
      height: screenSize.height,
      width: screenSize.blockWidth,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            NotificationListener(
              onNotification: (Notification notification) {
                if (_scrollController.position.pixels > 20 &&
                    showDateWidget.value) {
                  showDateWidget.value = false;

                  return true;
                }

                if (_scrollController.position.pixels <= 30 &&
                    !showDateWidget.value) {
                  showDateWidget.value = true;
                }
                return true;
              },
              child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child:
                      //(employeesProvider.selectedEmployee == null)
                      //?
                      Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildTitle(),
                      if (tabs[0]["is_selected"]) buildEmployeeStatusTabs(),
                      (tabs[0]["is_selected"])
                          ? EmployeesWidget(
                              typeFilter: selectedEmployeeTab,
                            )
                          : const EmployeesPaymentsWidgets(),
                    ],
                  )),
            ),
            if (authProvider.webUser.clientAssociationInfo.isEmpty)
              Positioned(
                top: screenSize.height * 0.1,
                right: 10,
                child: ValueListenableBuilder(
                  valueListenable: showDateWidget,
                  builder: (_, bool isvisible, __) {
                    return CustomDateSelector(
                      isVisible: tabs[1]["is_selected"] && isvisible,
                      onDateSelected:
                          (DateTime? startDate, DateTime? endDate) async =>
                              await employeesProvider.getPayments(
                                  startDate, endDate),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }


  Container buildEmployeeStatusTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      width: screenSize.blockWidth,
      child: SizedBox(
        height: screenSize.height * 0.08,
        width: screenSize.blockWidth * 0.6,
        child: ListView.builder(
          itemCount: tabsEmployeeStatus.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, int index) {
            Map<String, dynamic> tabItem = tabsEmployeeStatus[index];
            return Container(
              margin: EdgeInsets.only(
                  right: screenSize.blockWidth >= 920 ? 30 : 15),
              child: ChoiceChip(
                backgroundColor: Colors.white,
                label: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    tabItem["name"],
                    style: TextStyle(
                      fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                      color:
                          tabItem["is_selected"] ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                selected: tabItem["is_selected"],
                elevation: 2,
                selectedColor: UiVariables.primaryColor,
                onSelected: (bool newValue) {
                  int lastSelectedIndex = tabsEmployeeStatus.indexWhere(
                    (element) => element["is_selected"],
                  );

                  if (lastSelectedIndex == index) {
                    return;
                  }

                  if (lastSelectedIndex != -1) {
                    tabsEmployeeStatus[lastSelectedIndex]["is_selected"] =
                        false;
                  }

                  setState(
                    () {
                      tabsEmployeeStatus[index]["is_selected"] = newValue;
                      selectedEmployeeTab = index;

                      if (shouldShowDateWidget()) {
                        Provider.of<SelectorProvider>(context, listen: false)
                            .resetValues();
                      }
                    },
                  );
                  employeesProvider.selectedEmployeesTabStatus =
                      tabsEmployeeStatus[selectedEmployeeTab]["value"];
                  employeesProvider.updateFilteredEmployeesByStatus(
                    tabsEmployeeStatus[selectedEmployeeTab]["value"],
                  );

                  if (employeesProvider
                      .currentEmployeesTextFieldValue.isNotEmpty) {
                    employeesProvider.filterEmployees(
                      employeesProvider.currentEmployeesTextFieldValue,
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }


  bool shouldShowDateWidget() {
    if (employeesProvider.selectedEmployee != null) {
      if (selectedEmployeeTab == 4 && showDateWidget.value) return true;
      if (selectedEmployeeTab == 5 && showDateWidget.value) return true;
      return false;
    }
    return false;
  }

  Row buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Colaboradores",
              style: TextStyle(
                color: Colors.black,
                fontSize: screenSize.width * 0.016,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              "Colaboradores aprobados en Huts.",
              style: TextStyle(
                color: Colors.black54,
                fontSize: screenSize.width * 0.01,
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: screenSize.blockWidth <= 920 ? 60 : 5),
          child: buildTabs(),
        ),
      ],
    );
  }

  SizedBox buildTabs() {
    return SizedBox(
      //   color: Colors.red,
      width: screenSize.blockWidth * 0.3,
      height: screenSize.height * 0.06,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin:
                EdgeInsets.only(right: screenSize.blockWidth >= 920 ? 30 : 15),
            child: ChoiceChip(
              backgroundColor: Colors.white,
              label: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  tabs[0]["name"],
                  style: TextStyle(
                    fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                    color: tabs[0]["is_selected"] ? Colors.white : Colors.black,
                  ),
                ),
              ),
              selected: tabs[0]["is_selected"],
              elevation: 2,
              selectedColor: UiVariables.primaryColor,
              onSelected: (bool newValue) {
                int lastSelectedIndex = tabs.indexWhere(
                  (element) => element["is_selected"],
                );
                if (lastSelectedIndex == 0) {
                  return;
                }
                if (lastSelectedIndex != -1) {
                  tabs[lastSelectedIndex]["is_selected"] = false;
                }
                setState(() {
                  tabs[0]["is_selected"] = newValue;
                });
              },
            ),
          ),
          if (authProvider.webUser.clientAssociationInfo.isEmpty)
            ChoiceChip(
              backgroundColor: Colors.white,
              label: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  tabs[1]["name"],
                  style: TextStyle(
                    fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                    color: tabs[1]["is_selected"] ? Colors.white : Colors.black,
                  ),
                ),
              ),
              selected: tabs[1]["is_selected"],
              elevation: 2,
              selectedColor: UiVariables.primaryColor,
              onSelected: (bool newValue) {
                int lastSelectedIndex = tabs.indexWhere(
                  (element) => element["is_selected"],
                );
                if (lastSelectedIndex == 1) {
                  return;
                }
                if (lastSelectedIndex != -1) {
                  tabs[lastSelectedIndex]["is_selected"] = false;
                }
                setState(() {
                  tabs[1]["is_selected"] = newValue;
                });
              },
            ),
        ],
      ),
    );
  }
}
