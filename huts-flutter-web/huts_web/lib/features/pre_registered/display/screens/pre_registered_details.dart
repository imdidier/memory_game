import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/pre_registered/display/provider/pre_registered_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/employee_services/employee_services.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/code/code_utils.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../../core/utils/ui/widgets/employees/employee_tab_info.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';

class PreRegisteredDeteailsScreen extends StatefulWidget {
  final String employeeId;
  const PreRegisteredDeteailsScreen({super.key, required this.employeeId});

  @override
  State<PreRegisteredDeteailsScreen> createState() =>
      _PreRegisteredDeteailsScreenState();
}

class _PreRegisteredDeteailsScreenState
    extends State<PreRegisteredDeteailsScreen> {
  bool isScreenLoaded = false;
  late ScreenSize screenSize;
  late PreRegisteredProvider provider;
  bool imageAvailable = false;
  Uint8List? imageFile;
  String imageUrl = '';
  bool isDesktop = false;
  int selectedEmployeeTab = 0;
  bool employeeFound = true;

  List<Map<String, dynamic>> employeeInfoTabs = [
    {
      "name": "Información",
      "text": "Información general del colaborador",
      "value": "info",
      "is_selected": true,
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
  ];

  @override
  void didChangeDependencies() async {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    provider = context.watch<PreRegisteredProvider>();

    Employee? employee = await EmployeeServices.getById(widget.employeeId);

    if (employee == null) {
      employeeFound = false;
      if (mounted) setState(() {});
      return;
    }

    provider.showEmployeeDetails(employee: employee);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = context.read<GeneralInfoProvider>().screenSize;
    isDesktop = screenSize.width >= 1120;
    return SizedBox(
      height: screenSize.height,
      width: screenSize.blockWidth,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: provider.selectedEmployee == null
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
                  SingleChildScrollView(
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
                                Stack(
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
                                                    'employees/${provider.selectedEmployee!.id}/profile_pic')
                                                .putData(
                                                  imageFile!,
                                                  SettableMetadata(
                                                      contentType:
                                                          'image/jpeg'),
                                                );
                                        imageUrl = await uploadTask.ref
                                            .getDownloadURL();
                                      },
                                      child: imageAvailable
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Stack(
                                                children: [
                                                  Image.memory(
                                                    imageFile!,
                                                    width: screenSize.width *
                                                        0.075,
                                                    height: screenSize.width *
                                                        0.075,
                                                    filterQuality:
                                                        FilterQuality.high,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  const Positioned(
                                                    top: 5,
                                                    right: 5,
                                                    child: Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
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
                                                  (provider
                                                          .selectedEmployee!
                                                          .profileInfo
                                                          .image
                                                          .isNotEmpty)
                                                      ? Image.network(
                                                          provider
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
                                                              FilterQuality
                                                                  .high,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : Icon(
                                                          Icons
                                                              .hide_image_outlined,
                                                          size:
                                                              screenSize.width *
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
                                  ],
                                ),
                                const SizedBox(
                                  width: 15,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      CodeUtils.getFormatedName(
                                        provider.selectedEmployee!.profileInfo
                                            .names,
                                        provider.selectedEmployee!.profileInfo
                                            .lastNames,
                                      ),
                                      style: TextStyle(
                                          fontSize: isDesktop ? 25 : 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    // const SizedBox(height: 5),
                                    // Text(
                                    //   "ID: ${provider.selectedEmployee!.id}",
                                    //   style: TextStyle(
                                    //     fontSize: isDesktop ? 15 : 11,
                                    //     fontWeight: FontWeight.normal,
                                    //   ),
                                    // ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Cargos: ${UiMethods.getJobsNamesBykeys(provider.selectedEmployee!.jobs)}",
                                      style: TextStyle(
                                        fontSize: isDesktop ? 15 : 11,
                                        fontWeight: FontWeight.normal,
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
                          employee: provider.selectedEmployee!,
                          newImage: imageAvailable
                              ? imageUrl
                              : provider.selectedEmployee!.profileInfo.image,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Container _buildEmployeeTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      width: screenSize.blockWidth,
      child: SizedBox(
        height: isDesktop ? screenSize.height * 0.08 : screenSize.height * 0.08,
        width: isDesktop
            ? screenSize.blockWidth * 0.6
            : screenSize.blockWidth * 0.4,
        child: ListView.builder(
          itemCount: employeeInfoTabs.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, int index) {
            Map<String, dynamic> tabItem = employeeInfoTabs[index];
            return Container(
              margin: EdgeInsets.only(right: isDesktop ? 30 : 15),
              child: ChoiceChip(
                backgroundColor: Colors.white,
                label: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    tabItem["name"],
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 12,
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
