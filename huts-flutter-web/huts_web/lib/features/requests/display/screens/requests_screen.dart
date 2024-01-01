// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/providers/sidebar_provider.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_date_selector.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/requests/display/providers/create_event_provider.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/display/screens/widgets/admin/admin_requests_data_table.dart';
import 'package:huts_web/features/requests/display/screens/widgets/event_item_widget.dart';
import 'package:huts_web/features/requests/display/screens/widgets/events_calendar_widget.dart';
import 'package:huts_web/features/requests/display/screens/widgets/print_employees_dialog.dart';
import 'package:huts_web/features/requests/display/screens/widgets/quick_events_actions.dart';
import 'package:huts_web/features/requests/display/screens/widgets/total_employees_widget.dart';
import 'package:huts_web/features/requests/display/screens/widgets/total_events_widget.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/code/code_utils.dart';
import '../../../../core/utils/ui/widgets/general/custom_scroll_behavior.dart';
import '../../../../core/utils/ui/widgets/general/custom_search_bar.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../clients/display/provider/clients_provider.dart';
import '../../../clients/domain/entities/client_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/request_entity.dart';
import 'widgets/client/client_requests_data_table.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({Key? key}) : super(key: key);

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late ScreenSize screenSize;
  late WebUser user;
  late GeneralInfoProvider generalInfoProvider;
  late AuthProvider authProvider;
  late GetRequestsProvider getRequestsProvider;
  late SelectorProvider selectorProvider;
  late CreateEventProvider createEventProvider;
  late ClientsProvider clientsProvider;
  bool isScreenLoaded = false;
  bool isDesktop = false;
  bool isAdmin = false;
  int selectedClientIndex = 0;
  ValueNotifier<bool> showEventsFastActions = ValueNotifier<bool>(true);
  bool isExpanded = false;
  bool requestsSnapshotDone = true;
  List<Event> filteredEvents = [];
  List<Request> filteredRequests = [];

  List<Map<String, dynamic>> adminRequestsTabs = [
    {
      "name": "Generales",
      "is_selected": true,
    },
    {
      "name": "Por cliente",
      "is_selected": false,
    },
    {
      "name": "Por evento",
      "is_selected": false,
    },
    {
      "name": "Eliminadas",
      "is_selected": false,
    }
  ];
  List<Map<String, dynamic>> clientRequestsTabs = [
    {
      "name": "Generales",
      "is_selected": true,
    },
    {
      "name": "Por solicitud",
      "is_selected": false,
    },
  ];

  String selectedClientId = "";

  TextEditingController clientSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ValueNotifier<bool> showDateWidget = ValueNotifier<bool>(true);
  List<ClientEntity> filteredClients = [];
  Map<String, dynamic> tabItemAdmin = {};
  Map<String, dynamic> tabItemClient = {};

  late ClientEntity clientItem;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      selectorProvider.resetValues();
      DateTime currentDate = DateTime.now();
      DateTime startDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        0,
        0,
      );
      DateTime endDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        23,
        59,
      );
      selectorProvider.isDateSelected = true;

      selectorProvider.calendarProperties.rangeStart =
          selectorProvider.calendarProperties.rangeStart ?? startDate;

      getRequestsProvider.adminRequestsStartDate =
          selectorProvider.calendarProperties.rangeStart ?? startDate;

      getRequestsProvider.getEventsOrFail(
        user.accountInfo.type == "client" ? user.company.id : "",
        [startDate, endDate],
        context,
      );

      getRequestsProvider.getAllRequestOrFail(dates: [
        selectorProvider.calendarProperties.rangeStart ?? startDate,
        selectorProvider.calendarProperties.rangeEnd ?? endDate,
      ], context: context, nameTab: 'Generales');
      getRequestsProvider.getAdminRequestsValuesByRange();
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    authProvider = Provider.of<AuthProvider>(context);
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    user = authProvider.webUser;
    getRequestsProvider = Provider.of<GetRequestsProvider>(context);
    selectorProvider = Provider.of<SelectorProvider>(context);

    screenSize = generalInfoProvider.screenSize;
    createEventProvider = Provider.of<CreateEventProvider>(context);
    clientsProvider = Provider.of<ClientsProvider>(context);
    isAdmin = user.accountInfo.type == "admin";
    if (isAdmin) {
      getRequestsProvider.adminRequestsType = "general";
    } else {
      getRequestsProvider.clientRequestsType = 'generales';
    }

    super.didChangeDependencies();
  }

  List<Map<String, dynamic>> listJobs = [];

  List<List<String>> dataTableFromResponsive = [];
  String selectedEventName = '';
  Event? newEvent;
  bool isExpandedHeader = true;

  @override
  Widget build(BuildContext context) {
    isDesktop = screenSize.blockWidth >= 1300;

    return SizedBox(
      height: screenSize.height,
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          SelectorProvider selectorProvider = context.read<SelectorProvider>();
          if (!selectorProvider.isEditingDate) return;
          selectorProvider.changeEditingStatus(false);
        },
        child: Stack(
          children: [
            NotificationListener(
              onNotification: (Notification notification) {
                if (_scrollController.position.pixels > 20 &&
                    showEventsFastActions.value &&
                    !isExpanded) {
                  showEventsFastActions.value = false;
                  return true;
                }

                if (_scrollController.position.pixels <= 30 &&
                    !showEventsFastActions.value) {
                  showEventsFastActions.value = true;
                }

                return true;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                primary: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: (isDesktop)
                      ? buildDesktopContent()
                      : (isAdmin)
                          ? buildDesktopContent()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OverflowBar(
                                  overflowAlignment:
                                      OverflowBarAlignment.center,
                                  overflowSpacing: 8,
                                  alignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    buildCreateWidget(),
                                    buildPrinterWidget(),
                                  ],
                                ),
                                EventsCalendarWidget(
                                  clientId: user.company.id,
                                  screenSize: screenSize,
                                ),
                                buildClientTabs(),
                                buildEventsInfo(),
                                if (getRequestsProvider.clientRequestsType ==
                                    'generales')
                                  buildEventsList(),
                                if (getRequestsProvider.clientRequestsType ==
                                    'by-request')
                                  buildRequestList()
                              ],
                            ),
                ),
              ),
            ),
            (getRequestsProvider.adminRequestsType == "by-client")
                ? Positioned(
                    top: !isExpandedHeader
                        ? generalInfoProvider.screenSize.height * 0.3
                        : isExpandedHeader &&
                                authProvider
                                    .webUser.clientAssociationInfo.isNotEmpty
                            ? generalInfoProvider.screenSize.height * 0.65
                            : generalInfoProvider.screenSize.height * 0.54,
                    right: generalInfoProvider.screenSize.width * 0.01,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: showEventsFastActions,
                      builder: (_, bool visible, __) {
                        filteredEvents = (isAdmin)
                            ? [...getRequestsProvider.adminFilteredEvents]
                            : [...getRequestsProvider.events];
                        getRequestsProvider.updateFilteredEvent(
                            filteredEvents, false);
                        return visible
                            ? QuickEventsActions(
                                selectedClientId: selectedClientId,
                                onExpansionChanged: (bool expanded) {
                                  isExpanded = expanded;
                                  getRequestsProvider.updateExpanded(expanded);
                                },
                              )
                            : const SizedBox();
                      },
                    ),
                  )
                : const SizedBox(),
            if (isAdmin)
              Positioned(
                top: generalInfoProvider.screenSize.height * 0.001,
                left: generalInfoProvider.screenSize.width * 0.0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  height: 75,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          offset: Offset(0, 2),
                          blurRadius: 2,
                          color: Colors.black12)
                    ],
                  ),
                  width: context.read<SidebarProvider>().showing
                      ? screenSize.blockWidth - 200
                      : screenSize.blockWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Solicitudes",
                        style: TextStyle(
                          fontSize: screenSize.width * 0.014,
                        ),
                      ),
                      if (isAdmin)
                        SizedBox(
                            height: screenSize.height * 0.06,
                            child: buildCreateWidget())
                    ],
                  ),
                ),
              ),
            Positioned(
                top: generalInfoProvider.screenSize.height * 0.015,
                left: generalInfoProvider.screenSize.width * 0.1,
                child: ValueListenableBuilder(
                  valueListenable: showDateWidget,
                  builder: (_, bool isVisible, __) {
                    return CustomDateSelector(
                      isVisible: isAdmin && isVisible,
                      onDateSelected:
                          (DateTime? startDate, DateTime? endDate) =>
                              getRequestsProvider.onAdminRangeSelected(
                        startDate,
                        endDate,
                        context,
                        adminRequestsTabs.firstWhere(
                            (element) => element["is_selected"])["name"],
                        filteredClients[selectedClientIndex].accountInfo.id,
                      ),
                    );
                  },
                ))
          ],
        ),
      ),
    );
  }

  Column buildDesktopContent() {
    dataTableFromResponsive.clear();
    if (getRequestsProvider.adminFilteredRequests.isNotEmpty) {
      dataTableFromResponsive.clear();
      for (var requestsAdmin in getRequestsProvider.adminFilteredRequests) {
        RequestEmployeeInfo employeeInfo = requestsAdmin.employeeInfo;
        dataTableFromResponsive.add([
          "Imagen-${requestsAdmin.clientInfo.imageUrl}",
          "Cliente-${requestsAdmin.clientInfo.name}",
          "Colaborador-${CodeUtils.getFormatedName(
            employeeInfo.names,
            employeeInfo.lastNames,
          )}",
          "Cargo-${requestsAdmin.details.job['name']}",
          "Fecha inicio-${CodeUtils.formatDate(requestsAdmin.details.startDate)}",
          "Fecha fin-${CodeUtils.formatDate(requestsAdmin.details.endDate)}",
          "T.Horas-${requestsAdmin.details.totalHours}",
          "Estado-${requestsAdmin.details.status}",
          "Evento-${requestsAdmin.eventName}",
          "Total cliente-${requestsAdmin.details.fare.totalClientPays}",
          "Total.Colab-${requestsAdmin.details.fare.totalToPayEmployee}",
          "Acciones-"
        ]);
      }
    }
    return Column(
      children: [
        SizedBox(height: (isAdmin) ? screenSize.height * 0.065 : 0.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isAdmin) buildClientTabs(),
                if (!isAdmin) buildEventsInfo(),
                if (!isAdmin &&
                    getRequestsProvider.clientRequestsType == 'generales')
                  buildEventsList(),
                if (!isAdmin &&
                    getRequestsProvider.clientRequestsType == 'by-request')
                  buildRequestList(),
              ],
            ),
            //if (isAdmin) buildCreateWidget(),
            if (!isAdmin)
              Column(
                children: [
                  buildCreateWidget(),
                  buildCustomDivider(),
                  EventsCalendarWidget(
                    clientId: user.company.id,
                    screenSize: screenSize,
                  ),
                  buildCustomDivider(),
                  const SizedBox(height: 10),
                  buildPrinterWidget(),
                ],
              ),
          ],
        ),
        if (isAdmin)
          Column(
            children: [
              OverflowBar(
                children: [
                  buildAdminTabs(),
                ],
              ),
              SizedBox(
                height: (getRequestsProvider.adminRequestsType != "by-client")
                    ? generalInfoProvider.screenSize.height * 0.0
                    : generalInfoProvider.screenSize.height * 0.0,
              ),
              if (getRequestsProvider.adminRequestsType != "deleted")
                AnimatedSize(
                  curve: Curves.easeInOut,
                  duration: const Duration(milliseconds: 700),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${isExpandedHeader ? 'Ocultar' : 'Mostrar'} encabezados',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            InkWell(
                              onTap: () {
                                isExpandedHeader = !isExpandedHeader;
                                setState(() {});
                              },
                              child: Icon(
                                isExpandedHeader
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              ),
                            )
                          ],
                        ),
                        if ((getRequestsProvider.adminRequestsType ==
                                    "by-client" &&
                                isExpandedHeader) ||
                            getRequestsProvider.adminRequestsType ==
                                    "by-event" &&
                                isExpandedHeader)
                          buildClientsWidget(),
                        if (isExpandedHeader)
                          const Divider(
                            height: 6,
                          ),
                        if (getRequestsProvider.adminRequestsType !=
                                "deleted" &&
                            getRequestsProvider.adminRequestsType !=
                                "by-event" &&
                            getRequestsProvider.adminRequestsStartDate !=
                                null &&
                            isExpandedHeader)
                          buildAdminRequestsInfo(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              if (getRequestsProvider.adminRequestsType != "by-event" &&
                  isExpandedHeader)
                const Divider(
                  height: 6,
                ),
              const SizedBox(height: 10),
              if (getRequestsProvider.adminRequestsType != "by-event")
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomTooltip(
                      message:
                          'Total solicitudes filtradas: ${getRequestsProvider.adminFilteredRequests.length}\n${showTotalWithTooltip(listJobs.toList())}',
                      child: Text(
                        "Total solicitudes filtradas: ${getRequestsProvider.adminFilteredRequests.length}",
                        style: TextStyle(
                          fontSize: isDesktop ? 20 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        buildRequestSearchField(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ],
                ),
              if (getRequestsProvider.adminRequestsType != "by-event")
                screenSize.blockWidth >= 920
                    ? AdminRequestsDataTable(
                        screenSize: screenSize,
                      )
                    : DataTableFromResponsive(
                        listData: dataTableFromResponsive,
                        screenSize: screenSize,
                        type: 'request-admin'),
              if (getRequestsProvider.adminRequestsType == "by-event")
                buildEventsList(),
            ],
          ),
      ],
    );
  }

  Column buildRequestList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: isDesktop
              ? !generalInfoProvider.showWebSideBar
                  ? screenSize.width * 0.65
                  : screenSize.width * 0.53
              : generalInfoProvider.screenSize.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Lista de solicitudes",
                style: TextStyle(
                  fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                  color: Colors.black,
                ),
              ),
              CustomSearchBar(
                onChange: getRequestsProvider.filterClientRequests,
                hint: "Buscar solicitud",
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        getRequestsProvider.clientFilteredRequests.isNotEmpty
            ? Container(
                margin: const EdgeInsets.only(top: 20),
                // height: screenSize.height * 0.7,
                width: isDesktop
                    ? !generalInfoProvider.showWebSideBar
                        ? screenSize.width * 0.65
                        : screenSize.width * 0.53
                    : generalInfoProvider.screenSize.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClientRequestsDataTable(
                  allRequests: getRequestsProvider.clientFilteredRequests,
                  screenSize: screenSize,
                  onSort: (bool sortAscending, int? sortColumnIndex) {
                    if (sortColumnIndex == 2) {
                      getRequestsProvider.clientFilteredRequests.sort((a, b) {
                        String aName = CodeUtils.getFormatedName(
                          a.employeeInfo.names,
                          a.employeeInfo.lastNames,
                        ).toLowerCase();

                        String bName = CodeUtils.getFormatedName(
                          b.employeeInfo.names,
                          b.employeeInfo.lastNames,
                        ).toLowerCase();

                        return sortAscending
                            ? aName.compareTo(bName)
                            : bName.compareTo(aName);
                      });
                    }

                    if (sortColumnIndex == 3) {
                      getRequestsProvider.clientFilteredRequests.sort((a, b) {
                        String aJob = a.details.job["name"].toLowerCase();
                        String bJob = b.details.job["name"].toLowerCase();

                        return sortAscending
                            ? aJob.compareTo(bJob)
                            : bJob.compareTo(aJob);
                      });
                    }

                    if (sortColumnIndex == 4) {
                      getRequestsProvider.clientFilteredRequests.sort((a, b) {
                        DateTime aStartDate = a.details.startDate;
                        DateTime bStartDate = b.details.startDate;

                        return sortAscending
                            ? aStartDate.compareTo(bStartDate)
                            : bStartDate.compareTo(aStartDate);
                      });
                    }

                    if (sortColumnIndex == 5) {
                      getRequestsProvider.clientFilteredRequests.sort((a, b) {
                        DateTime aEndDate = a.details.endDate;
                        DateTime bEndDate = b.details.endDate;

                        return sortAscending
                            ? aEndDate.compareTo(bEndDate)
                            : bEndDate.compareTo(aEndDate);
                      });
                    }

                    if (sortColumnIndex == 6) {
                      getRequestsProvider.clientFilteredRequests.sort((a, b) {
                        return sortAscending
                            ? a.details.totalHours
                                .compareTo(b.details.totalHours)
                            : b.details.totalHours
                                .compareTo(a.details.totalHours);
                      });
                    }

                    if (sortColumnIndex == 7) {
                      getRequestsProvider.clientFilteredRequests.sort(
                        (a, b) {
                          return sortAscending
                              ? a.details.status.compareTo(b.details.status)
                              : b.details.status.compareTo(a.details.status);
                        },
                      );
                    }
                    setState(() {});
                  },
                ),
              )
            : const SizedBox(),
      ],
    );
  }

  void setAssocitedClientData() {
    filteredClients = [
      filteredClients.firstWhere(
        (element) =>
            element.accountInfo.id ==
            authProvider.webUser.clientAssociationInfo["client_id"],
      )
    ];
  }

  Column buildClientsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowSpacing: 15,
          overflowAlignment: OverflowBarAlignment.end,
          children: [
            Transform.translate(
              offset: const Offset(0, 15),
              child: Text(
                "Selecciona un cliente.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                ),
              ),
            ),
            buildClientSearchField(),
          ],
        ),
        const SizedBox(height: 10),
        if (isExpandedHeader)
          const Divider(
            height: 6,
          ),
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 5),
          width: generalInfoProvider.screenSize.blockWidth,
          height: generalInfoProvider.screenSize.blockWidth >= 920
              ? generalInfoProvider.screenSize.height * 0.16
              : generalInfoProvider.screenSize.height * 0.15,
          child: ScrollConfiguration(
            behavior: CustomScrollBehavior(),
            child: ListView.builder(
              itemCount: filteredClients.length,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, int index) {
                clientItem = filteredClients[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 22,
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (index == selectedClientIndex &&
                              selectedClientId ==
                                  filteredClients[index].accountInfo.id) return;

                          selectedClientIndex = index;
                          selectedClientId =
                              filteredClients[index].accountInfo.id;

                          getRequestsProvider.selectedAdminCompanyIndex = index;
                          createEventProvider.addressController.text =
                              clientItem.location.address;
                          setState(() {});
                          DateTime endDate = DateTime(
                            selectorProvider
                                .calendarProperties.rangeStart!.year,
                            selectorProvider
                                .calendarProperties.rangeStart!.month,
                            selectorProvider.calendarProperties.rangeStart!.day,
                            23,
                            59,
                          );
                          if (getRequestsProvider.adminRequestsEndDate !=
                              null) {
                            getRequestsProvider.adminRequestsEndDate = DateTime(
                              getRequestsProvider.adminRequestsEndDate!.year,
                              getRequestsProvider.adminRequestsEndDate!.month,
                              getRequestsProvider.adminRequestsEndDate!.day,
                              23,
                              59,
                            );
                          }
                          if (selectedClientIndex != -1) {
                            getRequestsProvider.getAllRequestOrFail(
                              dates: [
                                selectorProvider.calendarProperties.rangeStart!,
                                getRequestsProvider.adminRequestsEndDate ??
                                    endDate
                              ],
                              context: context,
                              nameTab: getRequestsProvider.adminRequestsType !=
                                      "by-event"
                                  ? 'Por cliente'
                                  : 'Por evento',
                              idClient: filteredClients[selectedClientIndex]
                                  .accountInfo
                                  .id,
                            );

                            getRequestsProvider.getAdminRequestsValuesByRange();
                          }
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
                              color: (index == selectedClientIndex &&
                                      filteredClients[index].accountInfo.id ==
                                          selectedClientId)
                                  ? Colors.green
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          width: generalInfoProvider.screenSize.width * 0.07,
                          height: generalInfoProvider.screenSize.height * 0.1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              clientItem.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: screenSize.blockWidth * 0.07,
                        child: Center(
                          child: Text(
                            clientItem.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
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
      ],
    );
  }

  Row buildAdminRequestsInfo() {
    List<Request> request = [...getRequestsProvider.adminFilteredRequests];
    double totalHoursEvent = 0;
    List<Map<String, dynamic>> listJobsPerStatus = [];
    listJobs.clear();
    for (var element in request) {
      totalHoursEvent += element.details.totalHours;
      int indexPerstatus = listJobsPerStatus.indexWhere(
        (job) =>
            job['name'] == element.details.job['name'] &&
            job['status_request'] == element.details.status,
      );
      if (indexPerstatus != -1) {
        listJobsPerStatus[indexPerstatus]
            .update('number_repeat', (value) => value = value + 1);
      } else {
        listJobsPerStatus.add(
          {
            'name': element.details.job['name'],
            'number_repeat': 1,
            'status_request': element.details.status,
          },
        );
      }
    }
    for (var element in request) {
      int indexJob = listJobs.indexWhere(
        (job) => job['name'] == element.details.job['name'],
      );
      if (indexJob != -1) {
        listJobs[indexJob]
            .update('number_repeat', (value) => value = value + 1);
      } else {
        listJobs.add(
          {
            'name': element.details.job['name'],
            'number_repeat': 1,
            'status_request': element.details.status,
          },
        );
      }
    }
    // filteredEvents = (isAdmin)
    //     ? [...getRequestsProvider.adminFilteredEvents]
    //     : [...getRequestsProvider.events];
    // getRequestsProvider.updateFilteredEvent(filteredEvents, false);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            if (authProvider.webUser.clientAssociationInfo.isEmpty)
              Text(
                "${getRequestsProvider.adminRequestsType != 'by-client' ? 'Total clientes' : 'Total cliente'}: ${CodeUtils.formatMoney(
                  getRequestsProvider.adminFilteredRequestsInfo["money"]
                      ["clients_total"],
                )}",
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 12,
                ),
              ),
            const SizedBox(height: 6),
            if (authProvider.webUser.clientAssociationInfo.isEmpty)
              Text(
                "Total colaboradores: ${CodeUtils.formatMoney(
                  getRequestsProvider.adminFilteredRequestsInfo["money"]
                      ["employees_total"],
                )}",
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 12,
                ),
              ),
            const SizedBox(height: 6),
            if (authProvider.webUser.clientAssociationInfo.isEmpty)
              Text(
                "Diferencia: ${CodeUtils.formatMoney(
                  getRequestsProvider.adminFilteredRequestsInfo["money"]
                      ["difference"],
                )}",
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 12,
                ),
              ),
            const SizedBox(height: 10),
            Text(
              "Total horas por total eventos: $totalHoursEvent",
              style: TextStyle(
                fontSize: isDesktop ? 16 : 12,
              ),
            ),
          ],
        ),
        screenSize.blockWidth >= 920
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      buildItemTypeRequest(
                        totalTypeRequests: getRequestsProvider
                            .adminFilteredRequestsInfo["requests"]["for_search"]
                            .toString(),
                        colorTypeRequest: Colors.grey,
                        titleTypeRequest: "Por buscar",
                        listPerStatus: listJobsPerStatus
                            .where((element) => element['status_request'] == 0)
                            .toList(),
                      ),
                      const SizedBox(width: 15),
                      buildItemTypeRequest(
                        totalTypeRequests: getRequestsProvider
                            .adminFilteredRequestsInfo["requests"]["pending"]
                            .toString(),
                        colorTypeRequest: Colors.yellow[700]!,
                        titleTypeRequest: "Pendientes",
                        listPerStatus: listJobsPerStatus
                            .where((element) => element['status_request'] == 1)
                            .toList(),
                      ),
                      const SizedBox(width: 15),
                      buildItemTypeRequest(
                        totalTypeRequests: getRequestsProvider
                            .adminFilteredRequestsInfo["requests"]["confirmed"]
                            .toString(),
                        colorTypeRequest: Colors.blue,
                        titleTypeRequest: "Aceptadas",
                        listPerStatus: listJobsPerStatus
                            .where((element) => element['status_request'] == 2)
                            .toList(),
                      ),
                      const SizedBox(width: 15),
                      buildItemTypeRequest(
                        totalTypeRequests: getRequestsProvider
                            .adminFilteredRequestsInfo["requests"]["active"]
                            .toString(),
                        colorTypeRequest: Colors.green,
                        titleTypeRequest: "Activas",
                        listPerStatus: listJobsPerStatus
                            .where((element) => element['status_request'] == 3)
                            .toList(),
                      ),
                      const SizedBox(width: 15),
                      buildItemTypeRequest(
                        totalTypeRequests: getRequestsProvider
                            .adminFilteredRequestsInfo["requests"]["finalized"]
                            .toString(),
                        colorTypeRequest: Colors.red,
                        titleTypeRequest: "Finalizadas",
                        listPerStatus: listJobsPerStatus
                            .where((element) => element['status_request'] == 4)
                            .toList(),
                      ),
                      const SizedBox(width: 15),
                      buildItemTypeRequest(
                        totalTypeRequests: getRequestsProvider
                            .adminFilteredRequestsInfo["requests"]["canceled"]
                            .toString(),
                        colorTypeRequest: Colors.red,
                        titleTypeRequest: "Canceladas",
                        listPerStatus: listJobsPerStatus
                            .where((element) => element['status_request'] == 5)
                            .toList(),
                      ),
                      const SizedBox(width: 15),
                      buildItemTypeRequest(
                        totalTypeRequests: getRequestsProvider
                            .adminFilteredRequestsInfo["requests"]["rejected"]
                            .toString(),
                        colorTypeRequest: Colors.red,
                        titleTypeRequest: "Rechazadas",
                        listPerStatus: listJobsPerStatus
                            .where((element) => element['status_request'] == 6)
                            .toList(),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildItemTypeRequest(
                    totalTypeRequests: getRequestsProvider
                        .adminFilteredRequestsInfo["requests"]["for_search"]
                        .toString(),
                    colorTypeRequest: Colors.grey,
                    titleTypeRequest: "Por buscar",
                    listPerStatus: listJobsPerStatus
                        .where((element) => element['status_request'] == 0)
                        .toList(),
                  ),
                  const SizedBox(height: 15),
                  buildItemTypeRequest(
                    totalTypeRequests: getRequestsProvider
                        .adminFilteredRequestsInfo["requests"]["pending"]
                        .toString(),
                    colorTypeRequest: Colors.yellow[700]!,
                    titleTypeRequest: "Pendientes",
                    listPerStatus: listJobsPerStatus
                        .where((element) => element['status_request'] == 1)
                        .toList(),
                  ),
                  const SizedBox(height: 15),
                  buildItemTypeRequest(
                    totalTypeRequests: getRequestsProvider
                        .adminFilteredRequestsInfo["requests"]["confirmed"]
                        .toString(),
                    colorTypeRequest: Colors.blue,
                    titleTypeRequest: "Aceptadas",
                    listPerStatus: listJobsPerStatus
                        .where((element) => element['status_request'] == 2)
                        .toList(),
                  ),
                  const SizedBox(height: 15),
                  buildItemTypeRequest(
                    totalTypeRequests: getRequestsProvider
                        .adminFilteredRequestsInfo["requests"]["active"]
                        .toString(),
                    colorTypeRequest: Colors.green,
                    titleTypeRequest: "Activas",
                    listPerStatus: listJobsPerStatus
                        .where((element) => element['status_request'] == 3)
                        .toList(),
                  ),
                  const SizedBox(height: 15),
                  buildItemTypeRequest(
                    totalTypeRequests: getRequestsProvider
                        .adminFilteredRequestsInfo["requests"]["finalized"]
                        .toString(),
                    colorTypeRequest: Colors.red,
                    titleTypeRequest: "Finalizadas",
                    listPerStatus: listJobsPerStatus
                        .where((element) => element['status_request'] == 4)
                        .toList(),
                  ),
                  const SizedBox(height: 15),
                  buildItemTypeRequest(
                    totalTypeRequests: getRequestsProvider
                        .adminFilteredRequestsInfo["requests"]["canceled"]
                        .toString(),
                    colorTypeRequest: Colors.red,
                    titleTypeRequest: "Canceladas",
                    listPerStatus: listJobsPerStatus
                        .where((element) => element['status_request'] == 5)
                        .toList(),
                  ),
                  const SizedBox(height: 15),
                  buildItemTypeRequest(
                    totalTypeRequests: getRequestsProvider
                        .adminFilteredRequestsInfo["requests"]["rejected"]
                        .toString(),
                    colorTypeRequest: Colors.red,
                    titleTypeRequest: "Rechazadas",
                    listPerStatus: listJobsPerStatus
                        .where((element) => element['status_request'] == 6)
                        .toList(),
                  ),
                ],
              )
      ],
    );
  }

  List<String> getItems(String clientId) {
    List<String> items = [];
    for (Event event in filteredEvents) {
      if (event.id == clientId) {
        items.add('${event.eventName}:${event.id}');
      }
    }
    return items;
  }

  String showTotalWithTooltip(List<Map<String, dynamic>> listJobs) {
    String stringToShow = '';
    List<String> data = [];
    for (var i = 0; i < listJobs.length; i++) {
      data.add('  - ${listJobs[i]['name']} : ${listJobs[i]['number_repeat']}');
    }
    stringToShow = data.join('\n');
    return stringToShow;
  }

  Container buildClientTabs() {
    return Container(
      margin: EdgeInsets.only(
        top: generalInfoProvider.screenSize.height * 0.025,
      ),
      width: generalInfoProvider.screenSize.blockWidth * 0.35,
      child: SizedBox(
        height: generalInfoProvider.screenSize.height * 0.08,
        width: screenSize.blockWidth >= 920
            ? generalInfoProvider.screenSize.blockWidth * 0.4
            : screenSize.blockWidth * 0.3,
        child: ListView.builder(
          itemCount: clientRequestsTabs.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, int index) {
            tabItemClient = clientRequestsTabs[index];
            return Container(
              margin: const EdgeInsets.only(right: 30),
              child: ChoiceChip(
                  backgroundColor: Colors.white,
                  label: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      tabItemClient["name"],
                      style: TextStyle(
                        fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                        color: tabItemClient["is_selected"]
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                  selected: tabItemClient["is_selected"],
                  elevation: 2,
                  selectedColor: UiVariables.primaryColor,
                  onSelected: (bool newValue) {
                    int lastSelectedIndex = clientRequestsTabs.indexWhere(
                      (element) => element["is_selected"],
                    );

                    if (lastSelectedIndex == index) {
                      return;
                    }

                    if (lastSelectedIndex != -1) {
                      clientRequestsTabs[lastSelectedIndex]["is_selected"] =
                          false;
                    }
                    setState(
                      () {
                        getRequestsProvider.clientRequestsType =
                            (index == 0) ? "generales" : 'by-request';
                        clientRequestsTabs[index]["is_selected"] = newValue;
                      },
                    );
                  }),
            );
          },
        ),
      ),
    );
  }

  Container buildAdminTabs() {
    if (filteredClients.isEmpty) {
      filteredClients.addAll(clientsProvider.allClients);
    }
    return Container(
      margin: EdgeInsets.only(
        top: generalInfoProvider.screenSize.height * 0.025,
      ),
      width: generalInfoProvider.screenSize.blockWidth,
      child: SizedBox(
        height: generalInfoProvider.screenSize.height * 0.08,
        width: screenSize.blockWidth >= 920
            ? generalInfoProvider.screenSize.blockWidth * 0.4
            : screenSize.blockWidth * 0.3,
        child: ListView.builder(
          itemCount: adminRequestsTabs.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, int index) {
            tabItemAdmin = adminRequestsTabs[index];
            return Container(
              margin: const EdgeInsets.only(right: 30),
              child: ChoiceChip(
                backgroundColor: Colors.white,
                label: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    tabItemAdmin["name"],
                    style: TextStyle(
                      fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                      color: tabItemAdmin["is_selected"]
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                selected: tabItemAdmin["is_selected"],
                elevation: 2,
                selectedColor: UiVariables.primaryColor,
                onSelected: (bool newValue) {
                  int lastSelectedIndex = adminRequestsTabs.indexWhere(
                    (element) => element["is_selected"],
                  );

                  if (lastSelectedIndex == index) {
                    return;
                  }

                  if (lastSelectedIndex != -1) {
                    adminRequestsTabs[lastSelectedIndex]["is_selected"] = false;
                  }
                  setState(
                    () {
                      getRequestsProvider.adminRequestsType = (index == 0)
                          ? "general"
                          : (index == 1)
                              ? "by-client"
                              : (index == 2)
                                  ? "by-event"
                                  : "deleted";
                      adminRequestsTabs[index]["is_selected"] = newValue;
                    },
                  );

                  if (index == 1 &&
                      authProvider.webUser.clientAssociationInfo.isNotEmpty) {
                    setAssocitedClientData();
                  }

                  if (filteredClients.isNotEmpty &&
                      adminRequestsTabs[index]['name'] == "Por cliente" &&
                      selectedClientIndex == 0) {
                    selectedClientId = filteredClients.first.accountInfo.id;
                  }

                  //if (adminRequestsTabs[index]['name'] != 'Por evento') {
                  DateTime endDate = DateTime(
                    selectorProvider.calendarProperties.rangeStart!.year,
                    selectorProvider.calendarProperties.rangeStart!.month,
                    selectorProvider.calendarProperties.rangeStart!.day,
                    23,
                    59,
                  );
                  getRequestsProvider.getAllRequestOrFail(
                    dates: [
                      selectorProvider.calendarProperties.rangeStart!,
                      getRequestsProvider.adminRequestsEndDate ?? endDate,
                    ],
                    context: context,
                    nameTab: adminRequestsTabs[index]['name'],
                    idClient: selectedClientId,
                  );

                  if (getRequestsProvider.adminRequestsStartDate != null) {
                    getRequestsProvider.getAdminRequestsValuesByRange();
                  }
                  //}
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Padding buildRequestSearchField() {
    return Padding(
      padding: EdgeInsets.only(
          right: (!isExpandedHeader &&
                      isAdmin &&
                      getRequestsProvider.isExpanded &&
                      getRequestsProvider.adminRequestsType == 'by-client') ||
                  (isExpandedHeader &&
                      authProvider.webUser.clientAssociationInfo.isNotEmpty &&
                      getRequestsProvider.adminRequestsType == 'by-client' &&
                      !showEventsFastActions.value)
              ? 505
              : (!isExpandedHeader &&
                          isAdmin &&
                          showEventsFastActions.value &&
                          getRequestsProvider.adminRequestsType ==
                              'by-client') ||
                      (isExpandedHeader &&
                          authProvider
                              .webUser.clientAssociationInfo.isNotEmpty &&
                          getRequestsProvider.adminRequestsType == 'by-client')
                  ? 180
                  : 0),
      child: Container(
        margin: const EdgeInsets.only(top: 10, right: 10),
        width: screenSize.blockWidth >= 920
            ? screenSize.blockWidth * 0.25
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
          controller: getRequestsProvider.requestSearchController,
          cursorColor: UiVariables.primaryColor,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
          decoration: const InputDecoration(
            suffixIcon: Icon(Icons.search),
            hintText: "Buscar solicitud",
            hintStyle: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          onChanged: getRequestsProvider.filterAdminRequests,
        ),
      ),
    );
  }

  Column buildEventsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: (isAdmin)
              ? double.infinity
              : (isDesktop)
                  ? !generalInfoProvider.showWebSideBar
                      ? screenSize.width * 0.65
                      : screenSize.width * 0.53
                  : generalInfoProvider.screenSize.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Lista eventos",
                style: TextStyle(
                  fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                  color: Colors.black,
                ),
              ),
              CustomSearchBar(
                onChange: (String query) {
                  if (query.isEmpty) {
                    filteredEvents = isAdmin
                        ? [...getRequestsProvider.adminFilteredEvents]
                        : [...getRequestsProvider.clientFilteredEvents];
                    getRequestsProvider.updateFilteredEvent(
                        filteredEvents, mounted);
                  }
                  filteredEvents.clear();
                  for (Event event in getRequestsProvider.filteredEvents) {
                    String statusEvent =
                        CodeUtils.getEventStatusName(event.details.status)
                            .toLowerCase();
                    String nameClient = event.clientInfo.name.toLowerCase();

                    String eventName = event.eventName.trim().toLowerCase();

                    if (statusEvent.contains(query)) {
                      filteredEvents.add(event);
                      continue;
                    }
                    if (nameClient.contains(query)) {
                      filteredEvents.add(event);
                      continue;
                    }
                    if (eventName.contains(query)) {
                      filteredEvents.add(event);
                      continue;
                    }
                  }
                  getRequestsProvider.updateFilteredEvent(
                      filteredEvents, mounted);
                },
                hint: "Buscar evento",
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: (isAdmin)
              ? double.infinity
              : (isDesktop)
                  ? !generalInfoProvider.showWebSideBar
                      ? screenSize.width * 0.65
                      : screenSize.width * 0.53
                  : screenSize.blockWidth,
          child: ListView.builder(
            itemCount: getRequestsProvider.filteredEvents.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (_, int index) {
              return EventItemWidget(
                screenSize: screenSize,
                event: getRequestsProvider.filteredEvents[index],
                isAdmin: isAdmin,
              );
            },
          ),
        ),
      ],
    );
  }

  Column buildEventsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Text(
          getRequestsProvider.calendarProperties.rangeStart == null ||
                  getRequestsProvider.calendarProperties.rangeEnd == null
              ? "Resumen ${getRequestsProvider.clientRequestsType == 'generales' ? 'eventos' : 'solicitudes por eventos'}"
              : "Resumen ${getRequestsProvider.clientRequestsType == 'generales' ? 'eventos' : 'solicitudes por eventos'} ${CodeUtils.formatDateWithoutHour(getRequestsProvider.calendarProperties.rangeStart!)} - ${CodeUtils.formatDateWithoutHour(getRequestsProvider.calendarProperties.rangeEnd!)}",
          style: TextStyle(
            fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
            color: Colors.black,
          ),
        ),
        Container(
          width: isDesktop
              ? !generalInfoProvider.showWebSideBar
                  ? screenSize.width * 0.65
                  : screenSize.width * 0.53
              : generalInfoProvider.screenSize.width,
          margin: const EdgeInsets.only(bottom: 25, top: 20),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isDesktop)
                  Column(
                    children: [
                      if (!isAdmin)
                        TotalEmployeesWidget(
                          screenSize: screenSize,
                          plusValue: getRequestsProvider.clientRequestsType ==
                                  'generales'
                              ? getRequestsProvider.requestedEmployees
                              : getRequestsProvider.totalRequestsPerClient,
                        ),
                      SizedBox(height: screenSize.height * 0.04)
                    ],
                  ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(2),
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          TotalEventsWidget(
                            title: getRequestsProvider.clientRequestsType ==
                                    'generales'
                                ? "Eventos\ntotales"
                                : 'Solicitudes\ntotales',
                            value: getRequestsProvider.clientRequestsType ==
                                    'generales'
                                ? getRequestsProvider.totalEvents
                                : getRequestsProvider.totalRequestsPerClient,
                            icon: Icon(
                              Icons.assignment_outlined,
                              size: screenSize.width * 0.018,
                              color: Colors.blue,
                            ),
                            cardColor: Colors.blue[50]!,
                            screenSize: screenSize,
                          ),
                          TotalEventsWidget(
                            title: getRequestsProvider.clientRequestsType ==
                                    'generales'
                                ? "Eventos\npendientes"
                                : 'Solicitudes\npendientes',
                            value: getRequestsProvider.clientRequestsType ==
                                    'generales'
                                ? getRequestsProvider.pendingEvents
                                : getRequestsProvider.pendingRequestsPerClient,
                            icon: Icon(
                              Icons.pending_outlined,
                              size: screenSize.width * 0.018,
                              color: Colors.orange,
                            ),
                            cardColor: Colors.orange[50]!,
                            screenSize: screenSize,
                          ),
                          TotalEventsWidget(
                            title: getRequestsProvider.clientRequestsType ==
                                    'generales'
                                ? "Eventos\nfinalizados"
                                : 'Solicitudes\nfinalizadas',
                            value: getRequestsProvider.clientRequestsType ==
                                    'generales'
                                ? getRequestsProvider.finishedEvents
                                : getRequestsProvider.finishedRequestsPerClient,
                            icon: Icon(
                              Icons.check_circle_outline,
                              size: screenSize.width * 0.018,
                              color: Colors.red,
                            ),
                            cardColor: Colors.red[50]!,
                            screenSize: screenSize,
                          ),
                        ],
                      ),
                      if (isDesktop)
                        Container(
                          margin: const EdgeInsets.only(left: 20),
                          height: 120,
                          width: 0.5,
                          color: Colors.black38,
                        ),
                      if (isDesktop && !isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: TotalEmployeesWidget(
                            screenSize: screenSize,
                            plusValue: getRequestsProvider.clientRequestsType ==
                                    'generales'
                                ? getRequestsProvider.requestedEmployees
                                : getRequestsProvider.totalRequestsPerClient,
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCreateWidget() {
    return InkWell(
      hoverColor: Colors.transparent,
      onTap: () =>
          createEventProvider.updateDialogStatus(true, screenSize, null),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: (isAdmin)
            ? screenSize.width * 0.16
            : (isDesktop)
                ? screenSize.width * 0.3
                : screenSize.width * 0.16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color:
              (isAdmin) ? UiVariables.primaryColor : UiVariables.lightBlueColor,
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 2,
              color: Colors.black12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: (!isAdmin)
              ? MainAxisAlignment.spaceAround
              : MainAxisAlignment.center,
          children: [
            if (!isAdmin)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  "assets/images/jobs.jpg",
                  width: screenSize.width * 0.07,
                  filterQuality: FilterQuality.high,
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (!isAdmin)
                      ? (isDesktop)
                          ? "Crear nuevo evento"
                          : "Crear evento"
                      : "Agregar solicitudes",
                  style: TextStyle(
                    color: (isAdmin) ? Colors.white : Colors.black,
                    fontSize: screenSize.width * 0.01,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isAdmin)
                  const SizedBox(
                    height: 5,
                  ),
                if (!isAdmin)
                  Text(
                    // (!isAdmin)
                    //     ?
                    (isDesktop)
                        ? "Solicita el personal necesario para tu evento."
                        : "Solicita personal",
                    // : (isDesktop)
                    //     ? "Agrega solicitudes a los eventos de un cliente."
                    //     : "Agrega solicitudes",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: screenSize.width * 0.008,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void filterClients(String query) {
    filteredClients.clear();
    for (ClientEntity client in clientsProvider.allClients) {
      if (client.name.toLowerCase().contains(query)) {
        filteredClients.add(client);
        continue;
      }
    }
    setState(() {});
  }

  Widget buildPrinterWidget() {
    return InkWell(
      hoverColor: Colors.transparent,
      onTap: () => PrintEmployeesDialog.show(),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: (isDesktop) ? screenSize.width * 0.3 : screenSize.width * 0.16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: UiVariables.lightBlueColor,
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 2,
              color: Colors.black12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "assets/images/printer.jpg",
                width: screenSize.width * 0.07,
                filterQuality: FilterQuality.high,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (isDesktop) ? "Imprimir listado colaboradores" : "Imprimir",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenSize.width * 0.01,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                SizedBox(
                  width: (isDesktop)
                      ? screenSize.width * 0.16
                      : screenSize.width * 0.06,
                  child: Text(
                    (isDesktop)
                        ? "Visualiza e imprime el listado de colaboradores para cada evento."
                        : "Colaboradores",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: screenSize.width * 0.008,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Container buildClientSearchField() {
    return Container(
      margin: const EdgeInsets.only(top: 10, right: 10),
      width: screenSize.blockWidth >= 920
          ? screenSize.blockWidth * 0.25
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
        enabled: authProvider.webUser.clientAssociationInfo.isEmpty,
        controller: clientSearchController,
        cursorColor: UiVariables.primaryColor,
        style: TextStyle(
          color: Colors.black87,
          fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
        ),
        decoration: InputDecoration(
          suffixIcon: const Icon(Icons.search),
          hintText: "Buscar cliente",
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: screenSize.blockWidth >= 920 ? 12 : 9,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        onChanged: (value) => filterClients(value.toLowerCase()),
      ),
    );
  }

  Column buildItemTypeRequest(
      {required String totalTypeRequests,
      required Color colorTypeRequest,
      required String titleTypeRequest,
      required List<Map<String, dynamic>> listPerStatus}) {
    return Column(
      children: [
        CustomTooltip(
          message:
              'Total $titleTypeRequest : $totalTypeRequests\n${showTotalWithTooltip(listPerStatus)}',
          child: Text(
            totalTypeRequests,
            style: TextStyle(
              fontSize: isDesktop ? 16 : 12,
            ),
          ),
        ),
        Text(
          titleTypeRequest,
          style: TextStyle(
            fontSize: isDesktop ? 16 : 12,
            color: colorTypeRequest,
          ),
        ),
      ],
    );
  }

  Container buildCustomDivider() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 10),
      height: 0.5,
      width: screenSize.blockWidth * 0.3,
      color: Colors.black38,
    );
  }
}
