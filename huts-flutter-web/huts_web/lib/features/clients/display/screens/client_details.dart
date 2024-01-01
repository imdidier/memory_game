import 'package:flutter/material.dart';
import 'package:huts_web/core/services/client_services/client_services.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../../core/utils/ui/widgets/general/custom_date_selector.dart';
import '../../../activity/display/providers/activity_provider.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';
import '../../domain/entities/client_location_info.dart';
import '../provider/clients_provider.dart';
import '../widgets/blocked/client_locked_employees.dart';
import '../widgets/client_activity.dart';
import '../widgets/client_fares.dart';
import '../widgets/client_general_info.dart';
import '../widgets/client_legal_info.dart' as component;
import '../widgets/favorites/client_favs_employees.dart';
import '../widgets/users/client_users_web.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientId;
  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  bool isScreenLoaded = false;
  late ScreenSize screenSize;
  late ClientsProvider clientsProvider;
  final ScrollController _scrollController = ScrollController();
  ValueNotifier<bool> isShowingDateWidget = ValueNotifier<bool>(false);
  bool isDesktop = false;

  @override
  void didChangeDependencies() async {
    if (isScreenLoaded) return;
    isScreenLoaded = true;

    clientsProvider = context.watch<ClientsProvider>();

    ClientEntity client =
        await ClientServices.getClient(clientId: widget.clientId);

    clientsProvider.showClientDetails(client: client);

    super.didChangeDependencies();
  }

  List<Map<String, dynamic>> clientInfoTabs = [
    {
      "name": "Información",
      "is_selected": true,
    },
    {
      "name": "Información legal",
      "is_selected": false,
    },
    {
      "name": "Ubicación",
      "is_selected": false,
    },
    {
      "name": "Tarifas",
      "is_selected": false,
    },
    {
      "name": "Favoritos",
      "is_selected": false,
    },
    {
      "name": "Bloqueados",
      "is_selected": false,
    },
    {
      "name": "Usuarios",
      "is_selected": false,
    },
    {
      "name": "Actividad",
      "is_selected": false,
    }
  ];
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    screenSize = context.read<GeneralInfoProvider>().screenSize;
    isDesktop = screenSize.width >= 1120;
    return SizedBox(
      height: screenSize.height,
      width: screenSize.blockWidth,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: clientsProvider.selectedClient == null
            ? const Center(
                child: Text(
                  "Cargando información...",
                  style: TextStyle(fontSize: 20),
                ),
              )
            : Stack(
                children: [
                  NotificationListener(
                    onNotification: (Notification notification) {
                      if (_scrollController.position.pixels > 20 &&
                          isShowingDateWidget.value) {
                        isShowingDateWidget.value = false;

                        return true;
                      }

                      if (_scrollController.position.pixels <= 30 &&
                          !isShowingDateWidget.value) {
                        isShowingDateWidget.value = true;
                      }
                      return true;
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: (clientsProvider.isMovingMapCamera)
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
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
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        clientsProvider
                                            .selectedClient!.imageUrl,
                                        height: screenSize.width * 0.05,
                                        filterQuality: FilterQuality.high,
                                      )),
                                  const SizedBox(
                                    width: 15,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        clientsProvider.selectedClient!.name,
                                        style: TextStyle(
                                          fontSize: isDesktop ? 20 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      // Text(
                                      //   "ID: ${clientsProvider.selectedClient!.accountInfo.id}",
                                      //   style: TextStyle(
                                      //     fontSize: isDesktop ? 15 : 11,
                                      //     fontWeight: FontWeight.normal,
                                      //   ),
                                      // ),
                                      // const SizedBox(
                                      //   height: 2,
                                      // ),
                                      SizedBox(
                                        width: screenSize.blockWidth > 920
                                            ? screenSize.blockWidth * 0.7
                                            : screenSize.blockWidth <= 280
                                                ? screenSize.blockWidth * 0.45
                                                : screenSize.blockWidth * 0.59,
                                        child: Text(
                                          clientsProvider
                                              .selectedClient!.description,
                                          style: TextStyle(
                                              fontSize: isDesktop ? 15 : 11,
                                              fontWeight: FontWeight.normal),
                                          maxLines: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildClientTabs(),
                          Container(
                            margin: const EdgeInsets.only(top: 15),
                            width: double.infinity,
                            decoration: UiVariables.boxDecoration,
                            padding: const EdgeInsets.all(25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                selectedTab == 0
                                    ? ClientGeneralInfo(
                                        clientsProvider: clientsProvider,
                                        screenSize: screenSize,
                                      )
                                    : selectedTab == 1
                                        ? component.ClientLegalInfo(
                                            clientsProvider: clientsProvider,
                                            screenSize: screenSize,
                                          )
                                        : selectedTab == 2
                                            ? ClientLocationInfo(
                                                clientsProvider:
                                                    clientsProvider)
                                            : selectedTab == 3
                                                ? ClientFares(
                                                    clientsProvider:
                                                        clientsProvider)
                                                : selectedTab == 4
                                                    ? ClientFavsEmployees(
                                                        clientsProvider:
                                                            clientsProvider)
                                                    : selectedTab == 5
                                                        ? ClientLockedEmployees(
                                                            clientsProvider:
                                                                clientsProvider)
                                                        : selectedTab == 6
                                                            ? ClientUsers(
                                                                clientsProvider:
                                                                    clientsProvider)
                                                            : ClientActivity(
                                                                clientsProvider:
                                                                    clientsProvider,
                                                              )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenSize.height * 0.34,
                    right: 20,
                    child: ValueListenableBuilder(
                      valueListenable: isShowingDateWidget,
                      builder: (_, isVisible, __) {
                        return CustomDateSelector(
                          isVisible: selectedTab == 7 && isVisible,
                          onDateSelected:
                              (DateTime? start, DateTime? end) async {
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

                            await Provider.of<ActivityProvider>(context,
                                    listen: false)
                                .getClientActivity(
                              id: clientsProvider
                                  .selectedClient!.accountInfo.id,
                              startDate: start,
                              endDate: end,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Container _buildClientTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      width: screenSize.blockWidth,
      child: SizedBox(
        height: isDesktop ? screenSize.height * 0.08 : screenSize.height * 0.08,
        width: isDesktop ? screenSize.blockWidth : screenSize.blockWidth * 0.4,
        child: ListView.builder(
          itemCount: clientInfoTabs.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, int index) {
            Map<String, dynamic> tabItem = clientInfoTabs[index];
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
                  int lastSelectedIndex = clientInfoTabs.indexWhere(
                    (element) => element["is_selected"],
                  );

                  if (lastSelectedIndex == index) {
                    return;
                  }

                  if (lastSelectedIndex != -1) {
                    clientInfoTabs[lastSelectedIndex]["is_selected"] = false;
                  }
                  setState(
                    () {
                      clientInfoTabs[index]["is_selected"] = newValue;
                      selectedTab = index;
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
