import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/settings/display/providers/settings_provider.dart';
import 'package:huts_web/features/settings/display/screens/widgets/create_role_dialog.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/code/code_utils.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';
import 'widgets/update_new_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isScreenLoaded = false;
  late ScreenSize screenSize;
  late GeneralInfoProvider generalInfoProvider;
  late SettingsProvider settingsProvider;
  TextEditingController nameHolidayController = TextEditingController();
  TextEditingController dateHolidayController = TextEditingController();

  DateTime currentDate = DateTime.now();
  DateTime? selectedDate;

  List<Map<String, dynamic>> generalTabs = [
    {
      "name": "Modificar roles",
      "is_selected": true,
    },
    {
      "name": "Modificar días festivos",
      "is_selected": false,
    },
  ];

  List<Map<String, dynamic>> rolesTabs = [
    {
      "name": "Clientes",
      "is_selected": true,
    },
    {
      "name": "Administradores",
      "is_selected": false,
    },
  ];

  List<Map<String, dynamic>> clientRoles = [];
  List<Map<String, dynamic>> adminRoles = [];

  @override
  void didChangeDependencies() async {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    settingsProvider = Provider.of<SettingsProvider>(context);
    await _getInitialData();
    super.didChangeDependencies();
  }

  Future<void> _getInitialData() async {
    if (generalInfoProvider.otherInfo.systemRoles.isEmpty) {
      await Future.delayed(
        const Duration(milliseconds: 1000),
        () async => await _getInitialData(),
      );
      return;
    }

    clientRoles.clear();
    adminRoles.clear();

    //Get client system roles
    generalInfoProvider.otherInfo.systemRoles["client"].forEach(
      (key, value) {
        clientRoles.add({
          "name": value["name"],
          "key": key,
          "routes": Map<String, dynamic>.from({}),
        });
      },
    );
    //Get admin system roles
    generalInfoProvider.otherInfo.systemRoles["admin"].forEach(
      (key, value) {
        adminRoles.add({
          "name": (value["has_client_association"])
              ? "${value["name"]} - Asociado a ${value["client_name"]}"
              : value["name"],
          "key": key,
          "has_client_association": value["has_client_association"],
          "routes": Map<String, dynamic>.from({}),
        });
      },
    );

    clientRoles.sort((a, b) => a["name"].compareTo(b["name"]));
    adminRoles.sort((a, b) => a["name"].compareTo(b["name"]));

    var mapEntries = generalInfoProvider.otherInfo.webRoutes.entries.toList()
      ..sort((a, b) =>
          a.value["info"]["position"].compareTo(b.value["info"]["position"]));

    generalInfoProvider.otherInfo.webRoutes
      ..clear()
      ..addEntries(mapEntries);

    //Get admin and client roles routes availability
    generalInfoProvider.otherInfo.webRoutes.forEach(
      (routeKey, routeValue) {
        routeValue["visibility"]["admin"].forEach(
          (key, value) {
            if (routeValue["visibility"]["admin"]["enabled"]) {
              if (key != "enabled") {
                int adminRolIndex =
                    adminRoles.indexWhere((element) => element["key"] == key);

                if (adminRolIndex != -1) {
                  adminRoles[adminRolIndex]["routes"][routeKey] = {
                    "key": routeKey,
                    "name": (routeKey == "requests")
                        ? "Solicitudes"
                        : routeValue["info"]["text"],
                    "is_enabled": value,
                  };
                }
              }
            }
          },
        );

        routeValue["visibility"]["client"].forEach(
          (key, value) {
            if (routeValue["visibility"]["client"]["enabled"]) {
              if (key != "enabled") {
                int clientRolIndex =
                    clientRoles.indexWhere((element) => element["key"] == key);

                if (clientRolIndex != -1) {
                  clientRoles[clientRolIndex]["routes"][routeKey] = {
                    "key": routeKey,
                    "name": routeValue["info"]["text"],
                    "is_enabled": value,
                  };
                }
              }
            }
          },
        );
      },
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    if (settingsProvider.newRolAdded) {
      settingsProvider.newRolAdded = false;
      _getInitialData();
    }
    return SizedBox(
      height: screenSize.height,
      width: screenSize.blockWidth,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              _buildGeneralTabs(),
              if (generalTabs[0]["is_selected"]) _buildRolesContent(),
              if (generalTabs[1]["is_selected"]) _buildHolidaysContent(),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildRolesContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRolesTabs(),
            Row(
              children: [
                _builSaveRolesBtn(),
                const SizedBox(width: 25),
                _buildAddRolBtn(),
              ],
            ),
          ],
        ),
        SizedBox(height: screenSize.height * 0.06),
        _buildRolesCards()
      ],
    );
  }

  Column _buildHolidaysContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 18),
              child: const Icon(
                Icons.calendar_month,
                size: 35,
                color: Colors.blue,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10, right: 10, left: 20),
              width: screenSize.blockWidth >= 920
                  ? screenSize.blockWidth * 0.24
                  : screenSize.width,
              height: screenSize.blockWidth >= 920
                  ? screenSize.height * 0.055
                  : screenSize.height * 0.045,
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
              child: InkWell(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: currentDate,
                    firstDate: currentDate,
                    lastDate: currentDate.add(
                      const Duration(
                        days: 365,
                      ),
                    ),
                  );
                  if (pickedDate != null) {
                    selectedDate = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                    );
                    dateHolidayController.text =
                        CodeUtils.formatDateWithoutHour(
                      selectedDate!,
                    );
                  }
                },
                child: TextField(
                  enabled: false,
                  controller: dateHolidayController,
                  readOnly: true,
                  style: TextStyle(
                    fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Fecha día festivo',
                    hintStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 20,
            ),
            Container(
              margin: const EdgeInsets.only(top: 10, right: 10),
              width: screenSize.blockWidth >= 920
                  ? screenSize.blockWidth * 0.24
                  : screenSize.width,
              height: screenSize.blockWidth >= 920
                  ? screenSize.height * 0.055
                  : screenSize.height * 0.045,
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
                cursorColor: UiVariables.primaryColor,
                controller: nameHolidayController,
                style: TextStyle(
                  fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
                ),
                decoration: const InputDecoration(
                  hintText: 'Nombre día festivo',
                  hintStyle: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
            const SizedBox(
              width: 20,
            ),
            _buildAddHolidayBtn(),
          ],
        ),
        SizedBox(height: screenSize.height * 0.03),
        _buildHolidayCards()
      ],
    );
  }

  SizedBox _buildHolidayCards() {
    List<Map<String, dynamic>> listHolidays = [];
    for (Map<String, dynamic> holiday
        in generalInfoProvider.listHolidays.values) {
      listHolidays.add({
        'name': holiday['name'],
        'day': holiday['day'] < 10 ? '0${holiday['day']}' : holiday['day'],
        'month':
            holiday['month'] < 10 ? '0${holiday['month']}' : holiday['month'],
      });
    }
    listHolidays.sort((a, b) => a['name'].toLowerCase().compareTo(
          b['name'].toLowerCase(),
        ));
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        direction: Axis.horizontal,
        spacing: 30,
        children: List.generate(
          listHolidays.length,
          (index) {
            return Container(
              margin: const EdgeInsets.only(top: 20, bottom: 20),
              padding: const EdgeInsets.all(15),
              width: screenSize.blockWidth >= 920
                  ? screenSize.blockWidth * 0.18
                  : screenSize.blockWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 2),
                    blurRadius: 2,
                    color: Colors.black12,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: screenSize.blockWidth >= 920
                        ? screenSize.blockWidth * 0.2
                        : screenSize.blockWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listHolidays[index]['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          '${listHolidays[index]['day']}/${listHolidays[index]['month']}/${currentDate.year}',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomTooltip(
                        message: "Editar",
                        child: InkWell(
                          onTap: () async {
                            Map<String, dynamic> holiday = {
                              'name': listHolidays[index]['name'],
                              'month': listHolidays[index]['month']
                                          .runtimeType ==
                                      String
                                  ? double.parse(listHolidays[index]['month'])
                                      .toInt()
                                  : listHolidays[index]['month'],
                              'day': listHolidays[index]['day'].runtimeType ==
                                      String
                                  ? double.parse(listHolidays[index]['day'])
                                      .toInt()
                                  : listHolidays[index]['day'],
                            };
                            DialogUpdateHoliday.show(holiday: holiday);
                          },
                          child: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      CustomTooltip(
                        message: "Eliminar",
                        child: InkWell(
                          onTap: () async {
                            Map<String, dynamic> holiday = {
                              'name': listHolidays[index]['name'],
                              'month': listHolidays[index]['month'],
                              'day': listHolidays[index]['day'],
                            };
                            await settingsProvider.deleteHoliday(
                              holiday: holiday,
                            );
                          },
                          child: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  SizedBox _buildRolesCards() {
    List<Map<String, dynamic>> selectedList =
        (rolesTabs[0]["is_selected"]) ? clientRoles : adminRoles;

    if (rolesTabs[1]["is_selected"]) {
      for (int i = 0; i < selectedList.length; i++) {
        if (selectedList[i]["has_client_association"]) {
          Map<String, dynamic> routesCopy = {...selectedList[i]["routes"]};
          selectedList[i]["routes"].clear();
          selectedList[i]["routes"]["employees"] = routesCopy["employees"];
          selectedList[i]["routes"]["messages"] = routesCopy["messages"];
          selectedList[i]["routes"]["pre_registered"] =
              routesCopy["pre_registered"];
          selectedList[i]["routes"]["requests"] = routesCopy["requests"];
        }
      }
    }

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        direction: Axis.horizontal,
        spacing: 30,
        children: List.generate(
          selectedList.length,
          (index) {
            return Container(
              margin: EdgeInsets.only(bottom: screenSize.height * 0.035),
              padding: const EdgeInsets.all(15),
              width: screenSize.width * 0.4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 2),
                    color: Colors.black12,
                    blurRadius: 5,
                  )
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Text(
                        selectedList[index]["name"],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isHutsAdmin(selectedList, index)
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        direction: Axis.horizontal,
                        children: List.generate(
                          selectedList[index]["routes"].length,
                          (routeIndex) {
                            List<String> routesKeys = List<String>.from(
                              selectedList[index]["routes"].keys.toList(),
                            );

                            Map<String, dynamic> routeInfo = selectedList[index]
                                ["routes"][routesKeys[routeIndex]];

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  routeInfo["name"],
                                  style: TextStyle(
                                    color: isHutsAdmin(selectedList, index)
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.7,
                                  child: CupertinoSwitch(
                                    value: routeInfo["is_enabled"],
                                    onChanged: isHutsAdmin(selectedList, index)
                                        ? null
                                        : (bool newValue) {
                                            selectedList[index]["routes"]
                                                    [routesKeys[routeIndex]]
                                                ["is_enabled"] = newValue;
                                            setState(() {});
                                          },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (!isHutsAdmin(selectedList, index))
                    Positioned(
                      top: -2,
                      right: 5,
                      child: InkWell(
                        onTap: () async => await settingsProvider.deleteRole(
                          toDeleteRol: selectedList[index],
                          rolType:
                              rolesTabs[0]["is_selected"] ? "client" : "admin",
                        ),
                        child: const CustomTooltip(
                          message: "Eliminar rol",
                          child: Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Padding _buildAddHolidayBtn() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: InkWell(
        onTap: () async {
          if (selectedDate == null) {
            LocalNotificationService.showSnackBar(
              type: 'fail',
              message: 'Debe seleccionar una fecha para el día festivo.',
              icon: Icons.warning,
            );
            return;
          }
          if (nameHolidayController.text.isEmpty) {
            LocalNotificationService.showSnackBar(
              type: 'fail',
              message: 'Debe agregar un nombre al día festivo.',
              icon: Icons.warning,
            );
            return;
          }
          Map<String, dynamic> holiday = {
            'name': nameHolidayController.text,
            'day': selectedDate!.day < 10
                ? double.parse('0${selectedDate!.day}').toInt()
                : selectedDate!.day,
            'month': selectedDate!.month < 10
                ? double.parse('0${selectedDate!.month}').toInt()
                : selectedDate!.month,
          };
          await settingsProvider.createHoliday(
            newHoliday: holiday,
          );
          nameHolidayController.clear();
          dateHolidayController.clear();
        },
        child: Container(
          width:
              screenSize.blockWidth >= 920 ? screenSize.blockWidth * 0.1 : 100,
          height: screenSize.height * 0.045,
          decoration: BoxDecoration(
            color: UiVariables.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Agregar día festivo",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding _buildAddRolBtn() {
    String titleComplement = rolesTabs[0]["is_selected"] ? "Cliente" : "Admin";

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: InkWell(
        onTap: () => CreateRoleDialog.show(
          isFromClient: rolesTabs[0]["is_selected"],
          availableRoutes: rolesTabs[0]["is_selected"]
              ? clientRoles[0]["routes"]
              : adminRoles[0]["routes"],
        ),
        child: Container(
          width:
              screenSize.blockWidth >= 920 ? screenSize.blockWidth * 0.1 : 100,
          height: screenSize.height * 0.045,
          decoration: BoxDecoration(
            color: UiVariables.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Agregar Rol $titleComplement",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding _builSaveRolesBtn() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: InkWell(
        onTap: () async {
          if (rolesTabs[0]["is_selected"]) {
            await settingsProvider.updateClientRoles(clientRoles, "client");
            return;
          }
          await settingsProvider.updateClientRoles(adminRoles, "admin");
        },
        child: Container(
          width:
              screenSize.blockWidth >= 920 ? screenSize.blockWidth * 0.1 : 100,
          height: screenSize.height * 0.045,
          decoration: BoxDecoration(
            color: UiVariables.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Guardar Cambios",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container _buildGeneralTabs() {
    return Container(
      margin: EdgeInsets.only(
        top: screenSize.height * 0.028,
      ),
      width: screenSize.blockWidth,
      height: screenSize.height * 0.06,
      child: ListView.builder(
        itemCount: generalTabs.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, int index) {
          Map<String, dynamic> tabItem = generalTabs[index];
          return Container(
            margin:
                EdgeInsets.only(right: screenSize.blockWidth >= 920 ? 30 : 15),
            child: ChoiceChip(
              backgroundColor: Colors.white,
              label: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  tabItem["name"],
                  style: TextStyle(
                    fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                    color: tabItem["is_selected"] ? Colors.white : Colors.black,
                  ),
                ),
              ),
              selected: tabItem["is_selected"],
              elevation: 2,
              selectedColor: UiVariables.primaryColor,
              onSelected: (bool newValue) {
                int lastSelectedIndex = generalTabs.indexWhere(
                  (element) => element["is_selected"],
                );
                if (lastSelectedIndex == index) {
                  return;
                }
                if (lastSelectedIndex != -1) {
                  generalTabs[lastSelectedIndex]["is_selected"] = false;
                }
                setState(() {
                  generalTabs[index]["is_selected"] = newValue;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Container _buildRolesTabs() {
    return Container(
      margin: EdgeInsets.only(top: screenSize.height * 0.025),
      width: screenSize.blockWidth * 0.5,
      height: screenSize.height * 0.06,
      child: ListView.builder(
        itemCount: rolesTabs.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, int index) {
          Map<String, dynamic> tabItem = rolesTabs[index];
          return Container(
            margin:
                EdgeInsets.only(right: screenSize.blockWidth >= 920 ? 30 : 15),
            child: ChoiceChip(
              backgroundColor: Colors.white,
              label: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  tabItem["name"],
                  style: TextStyle(
                    fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                    color: tabItem["is_selected"] ? Colors.white : Colors.black,
                  ),
                ),
              ),
              selected: tabItem["is_selected"],
              elevation: 2,
              selectedColor: UiVariables.primaryColor,
              onSelected: (bool newValue) {
                int lastSelectedIndex = rolesTabs.indexWhere(
                  (element) => element["is_selected"],
                );
                if (lastSelectedIndex == index) {
                  return;
                }
                if (lastSelectedIndex != -1) {
                  rolesTabs[lastSelectedIndex]["is_selected"] = false;
                }
                setState(() {
                  rolesTabs[index]["is_selected"] = newValue;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Column _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ajustes",
          style: TextStyle(
            color: Colors.black,
            fontSize: screenSize.width * 0.016,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "Ajustes generales de la plataforma Huts.",
          style: TextStyle(
            color: Colors.black54,
            fontSize: screenSize.width * 0.01,
          ),
        ),
      ],
    );
  }

  bool isHutsAdmin(List<Map<String, dynamic>> list, int index) {
    if (rolesTabs[0]["is_selected"]) return false;

    if (context.read<AuthProvider>().webUser.accountInfo.subtype !=
            list[index]["key"] &&
        list[index]["key"] != "admin") {
      return false;
    }

    return true;
  }
}
