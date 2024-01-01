// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_date_selector.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_scroll_behavior.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/statistics/display/providers/dashboard_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../clients/display/provider/clients_provider.dart';
import '../widgets/bar_graph_card.dart';
import '../widgets/graph_expenses_card.dart';
import '../widgets/list_employees.dart';
import '../widgets/pie_graph_jobs.dart';
import '../widgets/stats_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoaded = false;
  late ScreenSize screenSize;
  late DashboardProvider dashboardProvider;
  UiVariables uiVariables = UiVariables();
  late ClientsProvider clientsProvider;

  late AuthProvider authProvider;
  late GeneralInfoProvider generalInfoProvider;
  int triesCheckGeneralInfo = 0;
  bool isAdmin = false;
  bool isDesktop = false;
  bool isMovil = false;
  bool isTabletBig = false;
  bool isTabletSmall = false;

  int selectedClientIndex = 0;

  String tabSelected = 'general';

  List<Map<String, dynamic>> adminDashboardTabs = [
    {
      "name": "Estádisticas generales",
      "is_selected": true,
    },
    {
      "name": "Estádisticas por cliente",
      "is_selected": false,
    }
  ];

  TextEditingController clientSearchController = TextEditingController();
  List<ClientEntity> filteredClients = [];

  ValueNotifier<bool> showRangeWidget = ValueNotifier<bool>(true);
  final ScrollController _scrollController = ScrollController();
  bool isFirstTime = true;

  @override
  void didChangeDependencies() async {
    if (!isLoaded) {
      isLoaded = true;
      screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
      dashboardProvider = Provider.of<DashboardProvider>(context);
      authProvider = Provider.of<AuthProvider>(context);
      generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
      clientsProvider = Provider.of<ClientsProvider>(context);

      isAdmin = authProvider.webUser.accountInfo.type == "admin";
      dashboardProvider.getYearsToPick();
      dashboardProvider.yearPicked = '${DateTime.now().year}';
      if (isAdmin) {
        dashboardProvider.adminDashboardType = "general";
      }
      if (isFirstTime) dashboardProvider.daysDifference = 31;
      await checkCanGetStats();
    }
    super.didChangeDependencies();
  }

  checkCanGetStats() async {
    if (generalInfoProvider.generalInfo.countryInfo.paymentsTimes.isEmpty &&
        triesCheckGeneralInfo < 10) {
      await Future.delayed(const Duration(seconds: 1));
      triesCheckGeneralInfo++;
      checkCanGetStats();
      return;
    }
    dashboardProvider.eitherFailOrGetYearStats(
        authProvider, generalInfoProvider,
        isFirstTime: true, adminDasboardType: tabSelected);
  }

  @override
  Widget build(BuildContext context) {
    isDesktop = screenSize.blockWidth >= 1300;

    return SizedBox(
      height: screenSize.height,
      width: screenSize.width,
      child: Stack(
        children: [
          NotificationListener(
            onNotification: (Notification notification) {
              if (_scrollController.position.pixels > 20 &&
                  showRangeWidget.value) {
                showRangeWidget.value = false;
                return true;
              }

              if (_scrollController.position.pixels <= 30 &&
                  !showRangeWidget.value) {
                showRangeWidget.value = true;
              }

              return true;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  if (dashboardProvider.yearStats != null &&
                      authProvider.webUser.accountInfo.type != 'client' &&
                      dashboardProvider.cutOfWeekTotals != null)
                    buildStatsRow(),
                  buildLogoAndYearPicker(),
                  if (dashboardProvider.yearStats != null &&
                      authProvider.webUser.accountInfo.type != 'client' &&
                      dashboardProvider.cutOfWeekTotals != null)
                    buildAdminDashboardTab(),
                  if (dashboardProvider.adminDashboardType == "by_client" &&
                      isAdmin)
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenSize.width * 0.02,
                        right: screenSize.width * 0.02,
                      ),
                      child: Column(
                        children: [
                          buildClientsWidgetDashboard(),
                          const Divider(
                            height: 6,
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: screenSize.width * 0.02,
                        right: screenSize.width * 0.02,
                        top: screenSize.height * 0.02),
                    child: OverflowBar(
                      alignment: MainAxisAlignment.spaceBetween,
                      overflowSpacing: 10,
                      children: [
                        SizedBox(
                          width:
                              isDesktop && !generalInfoProvider.showWebSideBar
                                  ? screenSize.width / 1.95
                                  : isDesktop
                                      ? screenSize.width / 2.2
                                      : screenSize.width,
                          child: GraphExpensesCard(
                            uiVariables: uiVariables,
                            screenSize: screenSize,
                            dashboardProvider: dashboardProvider,
                            tapSelected: tabSelected,
                            daysDifference: dashboardProvider.daysDifference,
                          ),
                        ),
                        SizedBox(
                          width:
                              isDesktop && !generalInfoProvider.showWebSideBar
                                  ? screenSize.width * 0.43
                                  : isDesktop
                                      ? screenSize.width * 0.36
                                      : screenSize.width,
                          // height: isDesktop
                          //     ? screenSize.height * 0.44
                          //     : screenSize.height,
                          child: PieGraphJobs(
                            uiVariables: uiVariables,
                            screenSize: screenSize,
                            dashboardProvider: dashboardProvider,
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.02,
                        vertical: screenSize.height * 0.04),
                    child: OverflowBar(
                      alignment: MainAxisAlignment.spaceBetween,
                      overflowSpacing: 10,
                      children: [
                        if (dashboardProvider.yearStats != null &&
                            dashboardProvider
                                .yearStats!.favoriteEmployees.isNotEmpty)
                          // &&
                          // authProvider.webUser.accountInfo.type == 'client')
                          ListViewEmployees(
                            isDesktop: isDesktop,
                            screenSize: screenSize,
                            uiVariables: uiVariables,
                            titleList: 'Colaboradores favoritos',
                            employeesToShow:
                                dashboardProvider.yearStats!.favoriteEmployees,
                            showWorkedHours: false,
                          ),
                        // if (authProvider.webUser.accountInfo.type == 'client')
                        //   const SizedBox(
                        //     width: 20,
                        //   ),
                        Container(
                          decoration: UiVariables.boxDecoration,
                          width: isDesktop &&
                                  (dashboardProvider.adminDashboardType ==
                                          "by_client" ||
                                      !isAdmin) &&
                                  dashboardProvider
                                      .yearStats!.favoriteEmployees.isNotEmpty
                              ? screenSize.width * 0.33
                              : isDesktop
                                  ? screenSize.width / 2.45
                                  : screenSize.width,
                          height: screenSize.height * 0.42,
                          child: (dashboardProvider.yearStats == null)
                              ? const SizedBox()
                              : BarGraphCard(
                                  screenSize: screenSize,
                                  dashboardProvider: dashboardProvider,
                                  barGroups:
                                      dashboardProvider.yearStats!.yearEvents,
                                  totalToShow: dashboardProvider
                                      .yearStats!.totalEvents
                                      .toString(),
                                  barTitle: 'Eventos realizados',
                                  daysDifference:
                                      dashboardProvider.daysDifference,
                                ),
                        ),
                        Container(
                          decoration: UiVariables.boxDecoration,
                          width: isDesktop &&
                                  (dashboardProvider.adminDashboardType ==
                                          "by_client" ||
                                      !isAdmin) &&
                                  dashboardProvider
                                      .yearStats!.favoriteEmployees.isNotEmpty
                              ? screenSize.width * 0.33
                              : isDesktop
                                  ? screenSize.width / 2.45
                                  : screenSize.width,
                          height: screenSize.height * 0.42,
                          child: (dashboardProvider.yearStats == null)
                              ? const SizedBox()
                              : BarGraphCard(
                                  screenSize: screenSize,
                                  dashboardProvider: dashboardProvider,
                                  barGroups:
                                      dashboardProvider.yearStats!.yearRequests,
                                  totalToShow: dashboardProvider
                                      .yearStats!.totalRequests
                                      .toString(),
                                  barTitle: 'Solicitudes realizadas',
                                  daysDifference:
                                      dashboardProvider.daysDifference,
                                ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: screenSize.width * 0.02,
                        right: screenSize.width * 0.02,
                        top: screenSize.height * 0.01,
                        bottom: screenSize.height * 0.04),
                    child: OverflowBar(
                      spacing: 15,
                      overflowSpacing: 10,
                      alignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: UiVariables.boxDecoration,
                          width: isDesktop
                              ? screenSize.width / 2.45
                              : screenSize.width,
                          height: screenSize.height * 0.42,
                          child: (dashboardProvider.yearStats == null)
                              ? const SizedBox()
                              : BarGraphCard(
                                  screenSize: screenSize,
                                  dashboardProvider: dashboardProvider,
                                  totalToShow: dashboardProvider
                                      .yearStats!.totalHours
                                      .toString(),
                                  barGroups:
                                      dashboardProvider.yearStats!.yearHours,
                                  barTitle: 'Horas solicitadas',
                                  daysDifference:
                                      dashboardProvider.daysDifference,
                                ),
                        ),
                        // SizedBox(
                        //   width: screenSize.width * 0.02,
                        // ),
                        (dashboardProvider.yearStats == null ||
                                dashboardProvider
                                    .yearStats!.topEmployeesByHour.isEmpty)
                            ? Container(
                                width: screenSize.width / 2.45,
                                height: screenSize.height * 0.42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        child: Lottie.asset(
                                          'gifs/no_data.json',
                                          height:
                                              screenSize.absoluteHeight * 0.35,
                                        ),
                                      ),
                                      const Text(
                                        'No existen datos',
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListViewEmployees(
                                screenSize: screenSize,
                                uiVariables: uiVariables,
                                isDesktop: isDesktop,
                                titleList:
                                    'Top colaboradores por horas trabajadas',
                                employeesToShow:
                                    dashboardProvider.filteredEmployees,
                                showWorkedHours: true,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: !isFirstTime && isAdmin
                ? generalInfoProvider.screenSize.height * 0.3
                : generalInfoProvider.screenSize.height * 0.02,
            right: generalInfoProvider.screenSize.width * 0.016,
            child: ValueListenableBuilder<bool>(
              valueListenable: showRangeWidget,
              builder: (_, bool visible, Widget? widget) {
                return CustomDateSelector(
                  isVisible: visible,
                  onDateSelected:
                      (DateTime? startDate, DateTime? endDate) async {
                    if (startDate == null || endDate == null) return;
                    dashboardProvider.startDate = startDate;
                    endDate = DateTime(
                      endDate.year,
                      endDate.month,
                      endDate.day,
                      23,
                      59,
                      59,
                    );
                    dashboardProvider.endDate = endDate;
                    dashboardProvider.daysDifference =
                        endDate.difference(startDate).inDays;
                    isFirstTime = false;
                    await dashboardProvider.eitherFailOrGetYearStats(
                      authProvider,
                      generalInfoProvider,
                    );
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Padding buildLogoAndYearPicker() {
    return Padding(
      padding: EdgeInsets.only(
          left: screenSize.width * 0.02,
          right: screenSize.width * 0.03,
          top: screenSize.height * 0.03),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 5,
              ),
            ],
          ),
          // if (dashboardProvider.yearsToPick.isNotEmpty)
          //   Flexible(
          //     flex: 1,
          //     child: DropdownButton(
          //       style: const TextStyle(fontSize: 19),
          //       underline: const SizedBox(),
          //       value: dashboardProvider.yearPicked,
          //       icon: const Icon(Icons.keyboard_arrow_down),
          //       items: dashboardProvider.yearsToPick.map((String items) {
          //         return DropdownMenuItem(
          //           value: items,
          //           child: Text(
          //             items,
          //           ),
          //         );
          //       }).toList(),
          //       onChanged: (String? newYear) {
          //         if (newYear == null) return;
          //         dashboardProvider.updateYearPicked(
          //             newYear, authProvider, generalInfoProvider);
          //       },
          //     ),
          //   ),
        ],
      ),
    );
  }

  Padding buildStatsRow() {
    return Padding(
      padding: EdgeInsets.only(
          left: screenSize.width * 0.02,
          right: screenSize.width * 0.02,
          top: screenSize.height * 0.03),
      child: Column(
        children: [
          Row(
            children: [
              ClipOval(
                child: (authProvider.webUser.accountInfo.type == 'client')
                    ? Image.network(
                        authProvider.webUser.company.image,
                        height: screenSize.width * 0.034,
                        filterQuality: FilterQuality.high,
                      )
                    : Image.asset(
                        authProvider.webUser.company.image,
                        height: screenSize.width * 0.034,
                        filterQuality: FilterQuality.high,
                      ),
              ),
              const SizedBox(width: 10),
              Text(
                authProvider.webUser.company.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenSize.width * 0.014,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowSpacing: 8,
            children: [
              StatsCard(
                isDesktop: isDesktop,
                screenSize: screenSize,
                uiVariables: uiVariables,
                title: 'Total recibir de clientes',
                value: CodeUtils.formatMoney(
                    (dashboardProvider.cutOfWeekTotals!.totalClientsPay)),
                subtitle: dashboardProvider.cutOfWeekTotals!.cutOfWeekText,
              ),
              StatsCard(
                isDesktop: isDesktop,
                screenSize: screenSize,
                uiVariables: uiVariables,
                title: 'Total pagar a colaboradores',
                value: CodeUtils.formatMoney(
                    (dashboardProvider.cutOfWeekTotals!.totalToPayEmployees)),
                subtitle: dashboardProvider.cutOfWeekTotals!.cutOfWeekText,
              ),
              StatsCard(
                isDesktop: isDesktop,
                screenSize: screenSize,
                uiVariables: uiVariables,
                title: 'Total ganancias',
                value: CodeUtils.formatMoney(
                    (dashboardProvider.cutOfWeekTotals!.totalRevenue)),
                subtitle: dashboardProvider.cutOfWeekTotals!.cutOfWeekText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Column buildClientsWidgetDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OverflowBar(
          overflowSpacing: 20,
          alignment: MainAxisAlignment.spaceBetween,
          children: [
            Transform.translate(
              offset: const Offset(0, 15),
              child: const Text(
                'Selecciona un cliente.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            buildClientSearchField(),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        const Divider(
          height: 6,
        ),
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 5),
          width: generalInfoProvider.screenSize.blockWidth,
          height: generalInfoProvider.screenSize.height * 0.18,
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
                        vertical: 10, horizontal: 10),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(
                              () {
                                dashboardProvider.companyId =
                                    filteredClients[index].accountInfo.id;
                                selectedClientIndex = index;
                                dashboardProvider.eitherFailOrGetYearStats(
                                  authProvider,
                                  generalInfoProvider,
                                  adminDasboardType: adminDashboardTabs,
                                );
                              },
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 2,
                                  color: Colors.black12,
                                  offset: Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: (index == selectedClientIndex)
                                    ? Colors.green
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            width: generalInfoProvider.screenSize.width * 0.04,
                            height:
                                generalInfoProvider.screenSize.height * 0.07,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                clientItem.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          width: screenSize.blockWidth * 0.07,
                          child: Center(
                            child: Text(
                              overflow: TextOverflow.ellipsis,
                              clientItem.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
          ),
        )
      ],
    );
  }

  Container buildAdminDashboardTab() {
    return Container(
        margin: EdgeInsets.only(
            top: generalInfoProvider.screenSize.height * 0.01, left: 20),
        width: generalInfoProvider.screenSize.blockWidth,
        child: SizedBox(
          height: generalInfoProvider.screenSize.height * 0.08,
          width: generalInfoProvider.screenSize.blockWidth * 0.4,
          child: ListView.builder(
            itemCount: adminDashboardTabs.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              Map<String, dynamic> dashboardTabItem = adminDashboardTabs[index];
              return Container(
                margin: const EdgeInsets.only(right: 15),
                child: ChoiceChip(
                  backgroundColor: Colors.white,
                  elevation: 2,
                  label: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        dashboardTabItem["name"],
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 10,
                          color: dashboardTabItem["is_selected"]
                              ? Colors.white
                              : Colors.black,
                        ),
                      )),
                  selected: dashboardTabItem["is_selected"],
                  selectedColor: UiVariables.primaryColor,
                  onSelected: (bool newValue) {
                    int lastSelectedIndex = adminDashboardTabs.indexWhere(
                      (element) => element["is_selected"],
                    );

                    if (lastSelectedIndex == index) {
                      return;
                    }

                    if (lastSelectedIndex != -1) {
                      adminDashboardTabs[lastSelectedIndex]["is_selected"] =
                          false;
                    }
                    setState(() {
                      dashboardProvider.adminDashboardType =
                          (index == 0) ? "general" : "by_client";

                      adminDashboardTabs[index]["is_selected"] = newValue;
                      tabSelected = dashboardProvider.adminDashboardType;

                      dashboardProvider.companyId = clientsProvider
                          .allClients[selectedClientIndex].accountInfo.id;
                      dashboardProvider.eitherFailOrGetYearStats(
                          authProvider, generalInfoProvider);
                      if (dashboardProvider.adminDashboardType == 'by_client') {
                        filteredClients = [...clientsProvider.allClients];
                      }
                    });
                  },
                ),
              );
            },
          ),
        ));
  }

  Container buildClientSearchField() {
    return Container(
      width: screenSize.blockWidth >= 920
          ? screenSize.blockWidth / 3
          : screenSize.blockWidth,
      height: screenSize.height * 0.055,
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
        controller: clientSearchController,
        cursorColor: UiVariables.primaryColor,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.search),
          hintText: "Buscar cliente",
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        onChanged: (value) => filterClients(
          value.toLowerCase(),
        ),
      ),
    );
  }

  void filterClients(String query) {
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
