import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/settings/display/providers/settings_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/navigation_service.dart';
import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../core/utils/ui/widgets/general/custom_scroll_behavior.dart';
import '../../../../auth/domain/entities/screen_size_entity.dart';
import '../../../../clients/domain/entities/client_entity.dart';
import '../../../../general_info/display/providers/general_info_provider.dart';

class CreateRoleDialog {
  static void show(
      {required bool isFromClient,
      required Map<String, dynamic> availableRoutes}) {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;
    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (_) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: EdgeInsets.zero,
            title: _DialogContent(
              isFromClient: isFromClient,
              availableRoutes: availableRoutes,
            ),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatefulWidget {
  final bool isFromClient;
  final Map<String, dynamic> availableRoutes;
  const _DialogContent(
      {Key? key, required this.isFromClient, required this.availableRoutes})
      : super(key: key);

  @override
  State<_DialogContent> createState() => __DialogContentState();
}

class __DialogContentState extends State<_DialogContent> {
  bool isWidgetLoaded = false;
  late ScreenSize screenSize;
  TextEditingController rolNameController = TextEditingController();
  late GeneralInfoProvider generalInfoProvider;
  late SettingsProvider settingsProvider;
  late ClientsProvider clientsProvider;

  Map<String, dynamic> webRoutes = {};
  Map<String, dynamic> originalWebRoutes = {};

  String rolType = "";

  bool isGeneralTabSelected = true;
  TextEditingController clientSearchController = TextEditingController();
  String selectedClientId = "";
  List<ClientEntity> filteredClients = [];

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    generalInfoProvider = context.read<GeneralInfoProvider>();
    settingsProvider = context.read<SettingsProvider>();
    clientsProvider = context.read<ClientsProvider>();

    filteredClients = [...clientsProvider.allClients];

    rolType = widget.isFromClient ? "client" : "admin";

    Map<String, dynamic> providerWebRoutes = {
      ...generalInfoProvider.otherInfo.webRoutes
    };

    var mapEntries = providerWebRoutes.entries.toList()
      ..sort((a, b) =>
          a.value["info"]["position"].compareTo(b.value["info"]["position"]));

    providerWebRoutes
      ..clear()
      ..addEntries(mapEntries);

    providerWebRoutes.forEach(
      (routeKey, routeValue) {
        if (widget.availableRoutes.containsKey(routeKey)) {
          webRoutes[routeKey] = {
            "key": routeKey,
            "data": routeValue,
            "name": routeValue["info"]["text"],
            "is_selected": false,
          };
        }
      },
    );
    originalWebRoutes = {...webRoutes};

    if (mounted) setState(() {});

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    return Container(
      width: screenSize.blockWidth * 0.42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          _buildBody(),
          _buildHeader(),
          _buildFooter(),
        ],
      ),
    );
  }

  Container _buildHeader() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: screenSize.width * 0.018,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              (widget.isFromClient)
                  ? "Agregar un nuevo rol de tipo cliente"
                  : "Agregar un nuevo rol de tipo administrador",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenSize.blockWidth >= 920
                    ? screenSize.width * 0.011
                    : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildBody() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      margin: EdgeInsets.symmetric(
        vertical: screenSize.height * 0.09,
      ),
      height: (widget.isFromClient) ? 300 : 450,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            _buildRolNameField(),
            if (!widget.isFromClient) _buildTypeSelection(),
            const SizedBox(height: 30),
            // if (widget.isFromClient ||
            //     !widget.isFromClient && isGeneralTabSelected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Permisos",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildWebRoutes(),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Column _buildTypeSelection() {
    return Column(
      children: [
        const SizedBox(height: 25),
        Row(
          children: [
            const SizedBox(width: 1),
            InkWell(
              child: Chip(
                elevation: 2,
                label: Text(
                  "General",
                  style: TextStyle(
                    color: isGeneralTabSelected ? Colors.white : Colors.black,
                  ),
                ),
                backgroundColor: isGeneralTabSelected
                    ? UiVariables.primaryColor
                    : Colors.white,
              ),
              onTap: () => setState(() {
                if (isGeneralTabSelected) return;
                isGeneralTabSelected = true;

                webRoutes = {...originalWebRoutes};
                webRoutes.forEach((key, value) {
                  webRoutes[key]["is_selected"] = false;
                });
              }),
            ),
            const SizedBox(width: 20),
            InkWell(
              child: Chip(
                elevation: 2,
                label: Text(
                  "Asociado a un cliente",
                  style: TextStyle(
                    color: !isGeneralTabSelected ? Colors.white : Colors.black,
                  ),
                ),
                backgroundColor: !isGeneralTabSelected
                    ? UiVariables.primaryColor
                    : Colors.white,
              ),
              onTap: () => setState(() {
                if (!isGeneralTabSelected) return;
                isGeneralTabSelected = false;

                webRoutes.clear();

                originalWebRoutes.forEach((key, value) {
                  if (key == "employees" ||
                      key == "messages" ||
                      key == "pre_registered" ||
                      key == "requests") {
                    webRoutes[key] = value;
                  }
                });

                webRoutes.forEach((key, value) {
                  webRoutes[key]["is_selected"] = false;
                });
              }),
            ),
          ],
        ),
        if (!isGeneralTabSelected)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Selecciona un cliente.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenSize.blockWidth >= 920 ? 14 : 11,
                    ),
                  ),
                  _buildClientSearchField(),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 6),
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 5),
                width: generalInfoProvider.screenSize.blockWidth,
                height: generalInfoProvider.screenSize.height * 0.145,
                child: ScrollConfiguration(
                  behavior: CustomScrollBehavior(),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredClients.length,
                    itemBuilder: (_, int index) {
                      ClientEntity clientItem = filteredClients[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (filteredClients[index].accountInfo.id ==
                                      selectedClientId) {
                                    selectedClientId = "";
                                    return;
                                  }
                                  selectedClientId =
                                      filteredClients[index].accountInfo.id;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 2,
                                      color: Colors.black12,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: (filteredClients[index]
                                                .accountInfo
                                                .id ==
                                            selectedClientId)
                                        ? Colors.green
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                width: generalInfoProvider.screenSize.width *
                                    0.045,
                                height: generalInfoProvider.screenSize.width *
                                    0.045,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    clientItem.imageUrl,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: screenSize.blockWidth * 0.085,
                              child: Center(
                                child: CustomTooltip(
                                  message: clientItem.name,
                                  child: Text(
                                    clientItem.name,
                                    style: TextStyle(
                                      fontSize:
                                          screenSize.blockWidth >= 920 ? 12 : 9,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Divider(height: 6),
            ],
          ),
      ],
    );
  }

  Column _buildRolNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nombre del rol",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Container(
          height: 50,
          width: double.infinity,
          margin: EdgeInsets.only(
            left: 2,
            right: 2,
            top: screenSize.height * 0.01,
            bottom: screenSize.height * 0.02,
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: rolNameController,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Wrap _buildWebRoutes() {
    List<String> webRoutesKeys = webRoutes.keys.toList();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      direction: Axis.horizontal,
      children: List.generate(
        webRoutesKeys.length,
        (index) {
          String key = webRoutesKeys[index];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                webRoutes[key]["name"],
                style: const TextStyle(fontSize: 14),
              ),
              Transform.scale(
                scale: 0.7,
                child: CupertinoSwitch(
                  value: webRoutes[key]["is_selected"],
                  onChanged: (bool newValue) {
                    webRoutes[key]["is_selected"] = newValue;
                    setState(() {});
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Positioned _buildFooter() {
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
          left: 8.0,
          right: 14.0,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () async {
              if (rolNameController.text.isEmpty) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes agregar el nombre del rol",
                  icon: Icons.error_outline,
                );
                return;
              }

              String rolName = rolNameController.text.trim();

              if (generalInfoProvider.otherInfo.systemRoles[rolType].values
                  .toList()
                  .any((element) =>
                      element["name"].trim().toLowerCase() ==
                      rolName.toLowerCase())) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Ya existe un rol con el nombre agregado",
                  icon: Icons.error_outline,
                );
                return;
              }

              if (webRoutes.values
                  .toList()
                  .every((element) => !element["is_selected"])) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes habilitar al menos un permiso para el rol",
                  icon: Icons.error_outline,
                );
                return;
              }

              if (!widget.isFromClient &&
                  !isGeneralTabSelected &&
                  selectedClientId.isEmpty) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes seleccionar un cliente para el rol",
                  icon: Icons.error_outline,
                );
                return;
              }

              List<Map<String, dynamic>> enabledRoutes = [];

              webRoutes.forEach((key, value) {
                if (value["is_selected"]) {
                  enabledRoutes.add(webRoutes[key]);
                }
              });

              rolType == 'admin' && !isGeneralTabSelected
                  ? selectedClientId =
                      "$selectedClientId-${clientsProvider.allClients.firstWhere((element) => element.accountInfo.id == selectedClientId).name}"
                  : selectedClientId = '';
              await settingsProvider.createRole(
                routes: enabledRoutes,
                type: rolType,
                name: rolName,
                clientId: selectedClientId,
              );
            },
            child: Container(
              width: 150,
              height: 35,
              decoration: BoxDecoration(
                color: UiVariables.primaryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  "Crear rol",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container _buildClientSearchField() {
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 10),
      width: screenSize.blockWidth >= 920
          ? screenSize.blockWidth * 0.11
          : screenSize.blockWidth,
      height: screenSize.height * 0.054,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(blurRadius: 2, color: Colors.black26, offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        controller: clientSearchController,
        cursorColor: UiVariables.primaryColor,
        style: TextStyle(
            color: Colors.black87,
            fontSize: screenSize.blockWidth >= 920 ? 14 : 11),
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.search, size: 14),
          ),
          border: InputBorder.none,
          hintText: "Buscar cliente",
          hintStyle: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 12 : 9,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 19),
        ),
        onChanged: ((value) {
          if (selectedClientId.isNotEmpty) {
            setState(() {
              selectedClientId = "";
            });
          }
          _filterClients(value.toLowerCase());
        }),
      ),
    );
  }

  void _filterClients(String query) {
    if (query.isEmpty) {
      filteredClients = [...clientsProvider.allClients];
      setState(() {});
      return;
    }

    filteredClients.clear();
    for (ClientEntity client in clientsProvider.allClients) {
      if (client.name.toLowerCase().contains(query)) {
        filteredClients.add(client);
        continue;
      }
    }
    setState(() {});
  }
}
