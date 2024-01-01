import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_date_selector.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/display/widgets/datatables/headers/header_payment_by_client_range.dart';
import 'package:huts_web/features/payments/display/widgets/datatables/headers/header_payment_by_employee_range.dart';
import 'package:huts_web/features/payments/display/widgets/datatables/tables/group_payments_data_table.dart';
import 'package:huts_web/features/payments/display/widgets/group_payments_dialog.dart';
import 'package:huts_web/features/payments/display/widgets/datatables/tables/individual_payments_data_table.dart';
import 'package:huts_web/features/payments/domain/entities/payment_result_entity.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui/providers/sidebar_provider.dart';

// import '../../../auth/domain/entities/screen_size_entity.dart';
// import '../../../general_info/display/providers/general_info_provider.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController controller;
  bool isScreenLoaded = false;
  late ScreenSize screenSize;
  late AuthProvider authProvider;
  late PaymentsProvider paymentsProvider;
  late ClientsProvider clientsProvider;
  late GeneralInfoProvider generalInfoProvider;
  DateTime selectedDate = DateTime.now();
  late WebUser user;
  bool isAdmin = false;
  DateTime? startDate;
  DateTime? endDate;

  ValueNotifier<bool> showDateWidget = ValueNotifier<bool>(true);

  List<Map<String, dynamic>> mainTabs = [
    {
      "name": "Generales",
      "is_selected": true,
      "index": 0,
      "has_sub_tabs": true,
    },
    {
      "name": "Por cliente",
      "is_selected": false,
      "index": 1,
      "has_sub_tabs": true,
    },
  ];

  List<Map<String, dynamic>> subTabs = [
    {
      "name": "Clientes",
      "is_selected": true,
      "index": 0,
    },
    {
      "name": "Colaboradores",
      "is_selected": false,
      "index": 1,
    },
  ];

  Map<String, dynamic> selectedTab = {
    "name": "Pagos generales",
    "is_selected": true,
    "index": 0,
    "has_sub_tabs": true,
  };

  List<Map<String, dynamic>> tablesTabs = [
    {
      "name": "Individuales",
      "is_selected": true,
      "index": 0,
    },
    {
      "name": "Agrupados",
      "is_selected": false,
      "index": 1,
    },
  ];

  bool userTabsSetted = false;

  @override
  Widget build(BuildContext context) {
    ScreenSize screenSize =
        Provider.of<GeneralInfoProvider>(context).screenSize;
    bool isDesktop = screenSize.blockWidth >= 1300;
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
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenSize.height * 0.11),
                    buildPaymentTabs(),
                    const SizedBox(height: 30),
                    SelectionArea(child: _buidDataTables())
                  ],
                ),
              ),
            ),

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
                    Row(
                      children: [
                        Text(
                          "Pagos",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize:
                                  (isDesktop || screenSize.blockWidth >= 580)
                                      ? screenSize.width * 0.016
                                      : screenSize.width * 0.025),
                        ),
                        // if (paymentsProvider.isLoading)
                        //   Padding(
                        //     padding: const EdgeInsets.only(left: 15),
                        //     child: SizedBox(
                        //       width: 30,
                        //       height: 30,
                        //       child: CircularProgressIndicator(
                        //         color: UiVariables.primaryColor,
                        //       ),
                        //     ),
                        //   )
                      ],
                    ),
                  ],
                ),
              ),
            ),

            //Filtro de busqueda
            Positioned(
                top: generalInfoProvider.screenSize.height * 0.017,
                left: generalInfoProvider.screenSize.width * 0.07,
                child: ValueListenableBuilder(
                    valueListenable: showDateWidget,
                    builder: (_, bool isvisible, __) {
                      return CustomDateSelector(
                        isVisible: isvisible,
                        onDateSelected: (DateTime? startDateSelected,
                            DateTime? endDateSelected) {
                          startDate = startDateSelected;
                          if (endDateSelected != null) {
                            endDate = DateTime(
                              endDateSelected.year,
                              endDateSelected.month,
                              endDateSelected.day,
                              23,
                              59,
                            );
                          } else {
                            endDate = DateTime(
                              startDateSelected!.year,
                              startDateSelected.month,
                              startDateSelected.day,
                              23,
                              59,
                            );
                          }

                          if (startDate != null) {
                            if (clientsProvider.selectedClient != null &&
                                selectedTab["index"] == 1) {
                              paymentsProvider.getClientPaymentsByRange(
                                  clientId: clientsProvider
                                      .selectedClient!.accountInfo.id,
                                  startDate: startDate!,
                                  endDate: endDate);
                            } else if (selectedTab["index"] == 0) {
                              paymentsProvider.onRangeSelected(
                                startDate,
                                endDate,
                                context,
                              );
                            }
                          }
                        },
                      );
                    })),

            if (paymentsProvider.isShowingDetails)
              Center(
                child: GroupPaymentsDialog(
                  screenSize: screenSize,
                  payment: paymentsProvider.selectedPayment,
                  isClient: paymentsProvider.isClient,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Container getGeneralPaymentsByClient(ScreenSize screenSize) {
    return Container(
      margin: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        children: <Widget>[
          SingleChildScrollView(
            child: Column(
              children: [
                HeaderPaymentByClientRange(
                  screenSize: screenSize,
                  paymentsProvider: paymentsProvider,
                  clientsProvider: clientsProvider,
                  startDate: startDate,
                  endDate: endDate,
                  selectClient: false,
                  isClient: subTabs[0]["is_selected"],
                ),
                _buildTableTabs(),
                (tablesTabs[0]["is_selected"])
                    ? IndividualPaymentsDataTable(
                        payments:
                            //  isAdmin
                            //     ?
                            paymentsProvider
                                .paymentRangeResult.individualPayments,
                        // : paymentsProvider
                        //     .paymentRangeByClientResult.individualPayments,
                        screenSize: screenSize,
                        isClient: true,
                        isSelectedClient: false,
                      )
                    : GroupPaymentsDataTable(
                        payments:
                            //  isAdmin
                            //     ?
                            paymentsProvider.paymentRangeResult.groupPayments,
                        // : paymentsProvider
                        //     .paymentRangeByClientResult.groupPayments,
                        screenSize: screenSize,
                        isClient: true,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container getGeneralPaymentsByEmployee(ScreenSize screenSize) {
    return Container(
      margin: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        children: <Widget>[
          SingleChildScrollView(
            child: Column(
              children: [
                HeaderPaymentByEmployeeRange(
                  screenSize: screenSize,
                  paymentsProvider: paymentsProvider,
                  startDate: startDate,
                  endDate: endDate,
                  clientsProvider: clientsProvider,
                  selectClient: false,
                ),
                _buildTableTabs(),
                (tablesTabs[0]["is_selected"])
                    ? IndividualPaymentsDataTable(
                        payments: paymentsProvider
                            .paymentRangeResult.individualPayments,
                        screenSize: screenSize,
                        isClient: false,
                        isSelectedClient: false,
                      )
                    : GroupPaymentsDataTable(
                        payments:
                            paymentsProvider.paymentRangeResult.groupPayments,
                        screenSize: screenSize,
                        isClient: false,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container getPaymentsByClient(ScreenSize screenSize) {
    return authProvider.webUser.accountInfo.type == "client"
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, offset: Offset(0, 2), blurRadius: 2),
              ],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Listado de cargos",
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Wrap(
                  alignment: WrapAlignment.start,
                  direction: Axis.horizontal,
                  spacing: 20,
                  runSpacing: 15,
                  children: List.generate(
                    paymentsProvider.requiredJobsByRange.length,
                    (index) {
                      Map<String, dynamic> item =
                          paymentsProvider.requiredJobsByRange[index];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${item["job_name"]}: ",
                            style: const TextStyle(
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            "${item["counter"]}",
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        : Container(
            margin: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Column(
              children: <Widget>[
                SingleChildScrollView(
                  child: Column(
                    children: [
                      HeaderPaymentByClientRange(
                        screenSize: screenSize,
                        paymentsProvider: paymentsProvider,
                        clientsProvider: clientsProvider,
                        startDate: startDate,
                        endDate: endDate,
                        selectClient: true,
                        isClient: subTabs[0]["is_selected"],
                      ),
                      _buildTableTabs(),
                      (tablesTabs[0]["is_selected"])
                          ? IndividualPaymentsDataTable(
                              payments: paymentsProvider
                                  .paymentRangeResult.individualPayments,
                              screenSize: screenSize,
                              isClient: true,
                              isSelectedClient: true,
                            )
                          : GroupPaymentsDataTable(
                              payments: paymentsProvider
                                  .paymentRangeResult.groupPayments,
                              screenSize: screenSize,
                              isClient: true,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Container getPaymentsByClientByEmployees(ScreenSize screenSize) {
    return Container(
      margin: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        children: <Widget>[
          SingleChildScrollView(
            child: Column(
              children: [
                HeaderPaymentByClientRange(
                  screenSize: screenSize,
                  paymentsProvider: paymentsProvider,
                  startDate: startDate,
                  endDate: endDate,
                  selectClient: true,
                  clientsProvider: clientsProvider,
                  isClient: subTabs[0]["is_selected"],
                ),
                _buildTableTabs(),
                (tablesTabs[0]["is_selected"])
                    ? IndividualPaymentsDataTable(
                        payments: paymentsProvider
                            .paymentRangeResult.individualPayments,
                        screenSize: screenSize,
                        isClient: false,
                        isSelectedClient: true,
                      )
                    : GroupPaymentsDataTable(
                        payments:
                            paymentsProvider.paymentRangeResult.groupPayments,
                        screenSize: screenSize,
                        isClient: false,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    authProvider = Provider.of<AuthProvider>(context);
    paymentsProvider = Provider.of<PaymentsProvider>(context);
    clientsProvider = Provider.of<ClientsProvider>(context, listen: false);
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    screenSize = generalInfoProvider.screenSize;
    controller = TabController(
        length: paymentsProvider.isRangeSelected ? 2 : 3, vsync: this);
    DateTime startDate = DateTime.now();
    user = authProvider.webUser;
    isAdmin = user.accountInfo.type == "admin";
    if (!isAdmin) {
      paymentsProvider.getClientPaymentsByRange(
        clientId: authProvider.webUser.accountInfo.companyId,
        startDate: startDate,
        endDate: null,
      );
    } else {
      paymentsProvider.getGeneralPayments(
          startDate: startDate, endDate: startDate);
    }
    super.didChangeDependencies();
  }

  SizedBox buildPaymentTabs() {
    if (!isAdmin && !userTabsSetted) {
      userTabsSetted = true;
      mainTabs = [
        {
          "name": "Pago por rango",
          "is_selected": true,
          "index": 0,
          "has_sub_tabs": true,
        },
        {
          "name": "Total cargos por rango",
          "is_selected": false,
          "index": 1,
          "has_sub_tabs": true,
        },
      ];
    }

    return SizedBox(
      height: isAdmin == true
          ? generalInfoProvider.screenSize.height * 0.16
          : generalInfoProvider.screenSize.height * 0.08,
      width: generalInfoProvider.screenSize.blockWidth,
      child: Column(
        children: [
          SizedBox(
            height: screenSize.height * 0.08,
            child: ListView.builder(
              itemCount: mainTabs.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, int index) {
                Map<String, dynamic> tabItem = mainTabs[index];
                if (tabItem["is_selected"]) {
                  selectedTab = {...tabItem};
                }
                return Container(
                  margin: const EdgeInsets.only(right: 30),
                  child: ChoiceChip(
                    backgroundColor: Colors.white,
                    selected: tabItem["is_selected"],
                    elevation: 2,
                    selectedColor: UiVariables.primaryColor,
                    label: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: screenSize.blockWidth * 0.025),
                      child: Text(
                        tabItem["name"],
                        style: TextStyle(
                          color: tabItem["is_selected"]
                              ? Colors.white
                              : Colors.black,
                          fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                        ),
                      ),
                    ),
                    onSelected: (bool newValue) {
                      if (index == selectedTab["index"]) return;
                      setState(() {
                        mainTabs[selectedTab["index"]]["is_selected"] = false;
                        mainTabs[index]["is_selected"] = true;
                        selectedTab = {...mainTabs[index]};

                        if (isAdmin) {
                          startDate = null;
                          paymentsProvider.paymentRangeResult =
                              PaymentResult.empty();

                          SelectorProvider selectorProvider =
                              context.read<SelectorProvider>();
                          clientsProvider.unselectClient();
                          selectorProvider.isDateSelected = false;
                          selectorProvider.calendarProperties.selectedDay =
                              null;
                          selectorProvider.calendarProperties.rangeStart = null;
                          selectorProvider.calendarProperties.rangeEnd = null;
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          if (selectedTab["has_sub_tabs"] && isAdmin == true)
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 20, top: 16),
                  child: ChoiceChip(
                    backgroundColor: Colors.white,
                    selected: subTabs[0]["is_selected"],
                    elevation: 2,
                    selectedColor: UiVariables.primaryColor,
                    label: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: screenSize.blockWidth * 0.01,
                      ),
                      child: Text(
                        subTabs[0]["name"],
                        style: TextStyle(
                          color: subTabs[0]["is_selected"]
                              ? Colors.white
                              : Colors.black,
                          fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                        ),
                      ),
                    ),
                    onSelected: (bool newValue) {
                      if (subTabs[0]["is_selected"]) return;
                      setState(() {
                        subTabs[1]["is_selected"] = false;
                        subTabs[0]["is_selected"] = true;
                      });
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 20, top: 16),
                  child: ChoiceChip(
                    backgroundColor: Colors.white,
                    selected: subTabs[1]["is_selected"],
                    elevation: 2,
                    selectedColor: UiVariables.primaryColor,
                    label: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: screenSize.blockWidth * 0.01,
                      ),
                      child: Text(
                        subTabs[1]["name"],
                        style: TextStyle(
                          color: subTabs[1]["is_selected"]
                              ? Colors.white
                              : Colors.black,
                          fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                        ),
                      ),
                    ),
                    onSelected: (bool newValue) {
                      if (subTabs[1]["is_selected"]) return;
                      setState(() {
                        subTabs[0]["is_selected"] = false;
                        subTabs[1]["is_selected"] = true;
                      });
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buidDataTables() {
    if (selectedTab["index"] == 0 && selectedTab["has_sub_tabs"]) {
      return subTabs[0]["is_selected"]
          ? getGeneralPaymentsByClient(screenSize)
          : getGeneralPaymentsByEmployee(screenSize);
    } else if (selectedTab["index"] == 1 && selectedTab["has_sub_tabs"]) {
      return subTabs[0]["is_selected"]
          ? getPaymentsByClient(screenSize)
          : getPaymentsByClientByEmployees(screenSize);
    }

    return const SizedBox();
  }

  Row _buildTableTabs() {
    return Row(
      children: List.generate(
        tablesTabs.length,
        (index) => Padding(
          padding: const EdgeInsets.only(
            right: 30,
            top: 40,
            bottom: 30,
          ),
          child: ChoiceChip(
            elevation: 2,
            selectedColor: UiVariables.primaryColor,
            backgroundColor: Colors.white,
            label: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 6,
                horizontal: screenSize.blockWidth * 0.01,
              ),
              child: Text(
                tablesTabs[index]["name"],
                style: TextStyle(
                  color: tablesTabs[index]["is_selected"]
                      ? Colors.white
                      : Colors.black,
                  fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                ),
              ),
            ),
            selected: tablesTabs[index]["is_selected"],
            onSelected: (bool newValue) {
              if (tablesTabs[index]["is_selected"]) return;

              for (var i = 0; i < tablesTabs.length; i++) {
                tablesTabs[i]["is_selected"] = false;
              }

              tablesTabs[index]["is_selected"] = true;

              setState(() {});
            },
          ),
        ),
      ),
    );
  }
}
