// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/employee_services/employee_services.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/code/code_utils.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../../core/utils/ui/widgets/employees/employee_tab_info.dart';
import '../../../../core/utils/ui/widgets/general/custom_date_selector.dart';
import '../../../messages/domain/entities/message_entity.dart';
import '../../../requests/domain/entities/request_entity.dart';
import '../../domain/entities/employee_entity.dart';
import '../provider/employees_provider.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final String employeeId;
  const EmployeeDetailsScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  bool isScreenLoaded = false;
  late ScreenSize screenSize;
  late EmployeesProvider employeesProvider;
  late AuthProvider authProvider;
  bool imageAvailable = false;
  Uint8List? imageFile;
  String imageUrl = '';
  int selectedEmployeeTab = 0;
  ValueNotifier<bool> showDateWidget = ValueNotifier<bool>(false);
  bool employeeFound = true;

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

  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() async {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    authProvider = context.read<AuthProvider>();
    employeesProvider = context.watch<EmployeesProvider>();

    Employee? employee = await EmployeeServices.getById(widget.employeeId);

    if (employee == null) {
      employeeFound = false;
      if (mounted) setState(() {});
      return;
    }

    employeesProvider.showEmployeeDetails(employee: employee);

    await employeesProvider.getDetailsEmployee(employee.id, context);
    employeesProvider.setInitialDaysValues();

    if (mounted) setState(() {});

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = context.read<GeneralInfoProvider>().screenSize;
    return SizedBox(
      height: screenSize.height,
      width: screenSize.blockWidth,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: employeesProvider.selectedEmployee == null
            ? Center(
                child: Text(
                  employeeFound
                      ? "Cargando información..."
                      : "No se encontró información.",
                  style: const TextStyle(fontSize: 20),
                ),
              )
            : Stack(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            decoration: UiVariables.boxDecoration,
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final image = (await FilePicker.platform
                                          .pickFiles(type: FileType.image));
                                      if (image == null) return;

                                      setState(() {
                                        imageFile = image.files.first.bytes;
                                        imageAvailable = true;
                                      });
                                      LocalNotificationService.showSnackBar(
                                        type: 'success',
                                        message:
                                            'Presiona el botón "Guardar cambios" para almacenar los cambios.',
                                        icon: Icons.check,
                                      );

                                      TaskSnapshot uploadTask =
                                          await FirebaseStorage.instance
                                              .ref(
                                                  'employees/${employeesProvider.selectedEmployee!.id}/profile_pic')
                                              .putData(
                                                imageFile!,
                                                SettableMetadata(
                                                    contentType: 'image/jpeg'),
                                              );
                                      imageUrl =
                                          await uploadTask.ref.getDownloadURL();
                                    },
                                    child: imageAvailable
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Stack(
                                              children: [
                                                Image.memory(
                                                  imageFile!,
                                                  width:
                                                      screenSize.width * 0.075,
                                                  height:
                                                      screenSize.width * 0.075,
                                                  filterQuality:
                                                      FilterQuality.high,
                                                  fit: BoxFit.cover,
                                                ),
                                                Positioned(
                                                  top: 3,
                                                  right: 3,
                                                  child: Icon(
                                                    Icons
                                                        .change_circle_outlined,
                                                    color: UiVariables
                                                        .primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Stack(
                                              children: [
                                                (employeesProvider
                                                        .selectedEmployee!
                                                        .profileInfo
                                                        .image
                                                        .isNotEmpty)
                                                    ? Image.network(
                                                        employeesProvider
                                                            .selectedEmployee!
                                                            .profileInfo
                                                            .image,
                                                        width:
                                                            screenSize.width *
                                                                0.075,
                                                        height:
                                                            screenSize.width *
                                                                0.075,
                                                        filterQuality:
                                                            FilterQuality.high,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Icon(
                                                        Icons
                                                            .hide_image_outlined,
                                                        size: screenSize.width *
                                                            0.055,
                                                        color: Colors.grey,
                                                      ),
                                                Positioned(
                                                  top: 3,
                                                  right: 3,
                                                  child: Icon(
                                                    Icons
                                                        .change_circle_outlined,
                                                    color: UiVariables
                                                        .primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  const SizedBox(
                                    width: 15,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        CodeUtils.getFormatedName(
                                          employeesProvider.selectedEmployee!
                                              .profileInfo.names,
                                          employeesProvider.selectedEmployee!
                                              .profileInfo.lastNames,
                                        ),
                                        style: TextStyle(
                                            fontSize:
                                                screenSize.blockWidth >= 920
                                                    ? 25
                                                    : 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      // const SizedBox(height: 5),
                                      // Text(
                                      //   "ID: ${employeesProvider.selectedEmployee!.id}",
                                      //   style: TextStyle(
                                      //     fontSize: screenSize.blockWidth >= 920
                                      //         ? 15
                                      //         : 11,
                                      //     fontWeight: FontWeight.normal,
                                      //   ),
                                      // ),
                                      const SizedBox(height: 2),
                                      SizedBox(
                                        width: screenSize.blockWidth * 0.68,
                                        child: Text(
                                          "Cargos: ${UiMethods.getJobsNamesBykeys(employeesProvider.selectedEmployee!.jobs)}",
                                          style: TextStyle(
                                              fontSize:
                                                  screenSize.blockWidth >= 920
                                                      ? 15
                                                      : 11,
                                              fontWeight: FontWeight.normal),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildEmployeeTabs(),
                          EmployeeTabInfo(
                            tabInfo: employeeInfoTabs[selectedEmployeeTab],
                            employee: employeesProvider.selectedEmployee!,
                            newImage: imageAvailable
                                ? imageUrl
                                : employeesProvider
                                    .selectedEmployee!.profileInfo.image,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // if (authProvider.webUser.clientAssociationInfo.isEmpty)
                  //   Positioned(
                  //     top: screenSize.height * 0.1,
                  //     right: 10,
                  //     child: ValueListenableBuilder(
                  //       valueListenable: showDateWidget,
                  //       builder: (_, bool isvisible, __) {
                  //         return CustomDateSelector(
                  //           isVisible: tabs[1]["is_selected"] && isvisible,
                  //           onDateSelected:
                  //               (DateTime? startDate, DateTime? endDate) async =>
                  //                   await employeesProvider.getPayments(
                  //                       startDate, endDate),
                  //         );
                  //       },
                  //     ),
                  //   ),

                  //This seems have no sense but its a hack to build the same widget//
                  //depending of the tab selected, this is necessary//
                  _buildCustomDatePicker(),
                ],
              ),
      ),
    );
  }

  Positioned _buildCustomDatePicker() {
    return Positioned(
      top: screenSize.height * 0.32,
      right: 10,
      child: ValueListenableBuilder(
        valueListenable: showDateWidget,
        builder: (_, bool isVisible, Widget? child) {
          return CustomDateSelector(
            isVisible: _shouldShowDateWidget() && isVisible,
            onDateSelected: (DateTime? start, DateTime? end) async {
              if (start == null) return;
              start = DateTime(
                start.year,
                start.month,
                start.day,
                00,
                00,
              );

              end ??= DateTime(
                start.year,
                start.month,
                start.day,
                23,
                59,
              );

              if (end.day != start.day) {
                end = DateTime(
                  end.year,
                  end.month,
                  end.day,
                  23,
                  59,
                );
              }

              if (selectedEmployeeTab == 4) {
                List<HistoricalMessage>? messages =
                    await EmployeeServices.getMessages(
                  employeesProvider.selectedEmployee!.id,
                  start,
                  end,
                );

                if (messages != null) {
                  setState(() {
                    employeeInfoTabs[selectedEmployeeTab]["messages"] =
                        messages;
                  });
                }
                return;
              }

              List<Request>? requests = await EmployeeServices.getRequests(
                employeesProvider.selectedEmployee!.id,
                start,
                end,
              );

              if (requests != null) {
                setState(() {
                  employeeInfoTabs[selectedEmployeeTab]["requests"] = requests;
                });
              }
            },
          );
        },
      ),
    );
  }

  bool _shouldShowDateWidget() {
    if (employeesProvider.selectedEmployee != null) {
      if (selectedEmployeeTab == 4 && showDateWidget.value) return true;
      if (selectedEmployeeTab == 5 && showDateWidget.value) return true;
      return false;
    }
    return false;
  }

  Container _buildEmployeeTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      width: screenSize.blockWidth,
      child: SizedBox(
        height: screenSize.height * 0.08,
        width: screenSize.blockWidth * 0.6,
        child: ListView.builder(
          itemCount: employeeInfoTabs.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, int index) {
            Map<String, dynamic> tabItem = employeeInfoTabs[index];
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
                  int lastSelectedIndex = employeeInfoTabs.indexWhere(
                    (element) => element["is_selected"],
                  );

                  if (lastSelectedIndex == index) {
                    return;
                  }

                  if (lastSelectedIndex != -1) {
                    employeeInfoTabs[lastSelectedIndex]["is_selected"] = false;
                  }
                  setState(
                    () {
                      employeeInfoTabs[index]["is_selected"] = newValue;
                      selectedEmployeeTab = index;

                      if (_shouldShowDateWidget()) {
                        Provider.of<SelectorProvider>(context, listen: false)
                            .resetValues();
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
