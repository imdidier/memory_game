// ignore_for_file: use_build_context_synchronously

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
// import 'package:huts_web/features/activity/domain/entities/activity_report.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/payments/domain/entities/payment_entity.dart';
import 'package:huts_web/features/statistics/domain/entities/employee_fav.dart';
import 'package:provider/provider.dart';

import '../../../../../features/activity/display/providers/activity_provider.dart';
import '../../../../../features/admins/display/providers/admin_provider.dart';
import '../../../../../features/admins/display/widgets/create_admin_dialog.dart';
import '../../../../../features/auth/display/providers/auth_provider.dart';
import '../../../../../features/auth/domain/entities/web_user_entity.dart';
import '../../../../../features/clients/display/provider/clients_provider.dart';
import '../../../../../features/clients/domain/entities/client_entity.dart';
import '../../../../../features/employees/display/provider/employees_provider.dart';
import '../../../../../features/employees/display/widgets/change_phone_dialog.dart';
import '../../../../../features/employees/display/widgets/lock_dialog.dart';
import '../../../../../features/employees/display/widgets/payment_requests_dialog.dart';
import '../../../../../features/employees/domain/entities/employee_entity.dart';
import '../../../../../features/general_info/display/providers/general_info_provider.dart';
import '../../../../../features/messages/data/models/message_employee.dart';
import '../../../../../features/messages/display/provider/messages_provider.dart';
import '../../../../../features/messages/display/widgets/message_details.dart';
import '../../../../../features/messages/domain/entities/message_entity.dart';
import '../../../../../features/payments/display/providers/payments_provider.dart';
import '../../../../../features/pre_registered/display/provider/pre_registered_provider.dart';
import '../../../../../features/requests/display/providers/get_requests_provider.dart';
import '../../../../../features/requests/display/screens/widgets/admin/request_action.dart';
import '../../../../../features/requests/display/screens/widgets/request_action_dialog.dart';
import '../../../../../features/requests/domain/entities/event_entity.dart';
import '../../../../../features/requests/domain/entities/request_entity.dart';
import '../../../../services/employee_services/employee_services.dart';
import '../../../../services/event_message_service/service.dart';
import '../../../../services/local_notification_service.dart';
import '../../../../services/navigation_service.dart';
import '../../../code/code_utils.dart';
import '../../ui_methods.dart';
import '../../ui_variables.dart';
import 'custom_scroll_behavior.dart';
import 'custom_search_bar.dart';
import 'message_attached_widget.dart';

class DataTableFromResponsive extends StatefulWidget {
  final List<List<String>> listData;
  final String type;
  final ScreenSize screenSize;
  final List<Payment>? listPayment;
  final bool? isClient;
  final Event? event;
  final bool? isAdmin;
  final String? employeeId;
  final List<Request>? listRequestEmployees;
  const DataTableFromResponsive({
    super.key,
    required this.listData,
    required this.screenSize,
    required this.type,
    this.isClient,
    this.listPayment,
    this.event,
    this.isAdmin = false,
    this.employeeId,
    this.listRequestEmployees,
  });

  @override
  State<DataTableFromResponsive> createState() =>
      _DataTableFromResponsiveState();
}

class _DataTableFromResponsiveState extends State<DataTableFromResponsive> {
  bool isWidgetLoaded = false;
  String selectedCategory = "";
  List<Map<String, dynamic>> categories = [];
  late ActivityProvider activityProvider;

  @override
  void didChangeDependencies() async {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    categories = List<Map<String, dynamic>>.from(
      Provider.of<GeneralInfoProvider>(context, listen: false)
          .otherInfo
          .employeesActivityCategories
          .values
          .toList()
          .where((element) => element["key"] != "all"),
    );

    categories[0] = {
      "key": "all",
      "name": "Todo",
    };
    selectedCategory = categories[1]["key"];
    activityProvider = Provider.of<ActivityProvider>(context);
    await activityProvider.getEmployeeActivity(
      id: widget.employeeId!,
      category: selectedCategory,
      fromStart: true,
    );

    if (mounted) setState(() {});

    super.didChangeDependencies();
  }

  int selectedIndex = -1;
  int frist = 0;
  @override
  Widget build(BuildContext context) {
    GetRequestsProvider requestProvider =
        Provider.of<GetRequestsProvider>(context);
    ActivityProvider activityProvider = Provider.of<ActivityProvider>(context);
    AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    ClientsProvider provider = Provider.of<ClientsProvider>(context);
    AdminProvider adminProvider = Provider.of<AdminProvider>(context);
    PreRegisteredProvider preRegisteredProvider =
        Provider.of<PreRegisteredProvider>(context);

    EmployeesProvider employeeProvider =
        Provider.of<EmployeesProvider>(context);
    MessagesProvider messageProvider = Provider.of<MessagesProvider>(context);
    PaymentsProvider paymentsProvider = Provider.of<PaymentsProvider>(context);
    double mainExtent = 0;
    List<ClientEntity> client = provider.filteredClients;
    List<HistoricalMessage> historyMessage = [];

    List<MessageEmployee> employeeMessage = messageProvider.filteredEmployees;
    List<Employee> preEmployee = preRegisteredProvider.filteredEmployees;
    List<Employee> colaboradorEmployee = employeeProvider.filteredEmployees;

    List<Request> adminFilteredRequest = requestProvider.adminFilteredRequests;

    List<Request> eventRequest = requestProvider.filteredRequests;
    // List<Map<String, dynamic>> historyRequest =
    //     requestProvider.selectedRequestChanges;
    // List<ActivityReport> activity = activityProvider.clientFilteredActivity;
    List<Map<String, dynamic>> fav = provider.filteredFavs;
    List<Map<String, dynamic>> lock = provider.filteredLocks;
    List<Map<String, dynamic>> webUserClient =
        authProvider.webUser.company.webUserEmployees;
    List<ClientEmployee> favClient =
        authProvider.webUser.company.favoriteEmployees;
    List<ClientEmployee> lockClient =
        authProvider.webUser.company.blockedEmployees;

    List<Map<String, dynamic>> webUser = provider.filteredWebUsers;
    List<WebUser> admin = adminProvider.filteredAdmins;
    List<Map<String, dynamic>> payment =
        employeeProvider.filteredEmployeesPayments;

    Color? favoriteIconColor;
    Color? blockedIconColor;
    Color? ratedIconColor;

    bool isEmployeeRatingEnabled = false;
    bool isEmployeeFavoriteEnabled = false;
    bool isBlockEmployeeEnabled = false;

    switch (widget.type) {
      case 'select-job':
        mainExtent = 190;
        break;
      case 'favs':
      case 'locks':
      case 'list-recipients':
        mainExtent = 370;
        break;
      case 'web-users':
      case 'historical-payment-employees':
      case 'group-payment':
        mainExtent = 435;
        break;
      case 'pre-register':
      case 'request-admin':
        mainExtent = 700;
        break;
      case 'activity':
      case 'selected-client':
      case 'messages':
      case 'activity-employee':
      case 'activity-profile-client':
        mainExtent = 300;
        break;
      case 'fav-client':
      case 'lock-client':
      case 'web-user-client':
        mainExtent = 280;
        break;
      case 'add-fav':
      case 'add-lock': //REVISAR
      case 'message-employees':
        mainExtent = 380;
        break;
      case 'employees':
        mainExtent = 610;
        break;
      case 'admin':
        mainExtent = 450;
        break;
      case 'history-messages':
        mainExtent = 420;
        break;
      case 'individual-payment':
        mainExtent = 730;
        break;
      case 'history-request':
        mainExtent = 320;
        break;
      case 'requests-event':
      case 'request-employee':
        mainExtent = 525;
        break;
      case 'request-details-employee':
        mainExtent = 810;
        break;
      default:
        mainExtent = 500;
        break;
    }
    CustomTooltip buildDetailsBtn(Employee employee) {
      return CustomTooltip(
        message: "Ver detalles",
        child: InkWell(
          onTap: () => employeeProvider.showEmployeeDetails(employee: employee),
          child: const Icon(
            Icons.account_circle,
            color: Colors.black54,
            size: 20,
          ),
        ),
      );
    }

    Row buildDeleteBtn(BuildContext? globalContext, WebUser admin) {
      return Row(
        children: [
          const SizedBox(width: 6),
          CustomTooltip(
            message: "Eliminar",
            child: InkWell(
              onTap: () async {
                if (globalContext == null) return;

                bool itsConfirmed = await confirm(
                  globalContext,
                  title: Text(
                    "Eliminar administrador",
                    style: TextStyle(
                      color: UiVariables.primaryColor,
                    ),
                  ),
                  content: Text(
                    "¿Quieres eliminar a ${admin.profileInfo.names} ${admin.profileInfo.lastNames}?",
                  ),
                  textCancel: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                  textOK: const Text(
                    "Aceptar",
                    style: TextStyle(color: Colors.blue),
                  ),
                );

                if (!itsConfirmed) return;

                await adminProvider.deleteAdmin(admin.uid);
              },
              child: const Icon(
                Icons.delete_rounded,
                color: Colors.black54,
                size: 20,
              ),
            ),
          ),
        ],
      );
    }

    Row buildEnableDisableBtn(
        WebUser admin, BuildContext? globalContext, int index) {
      return Row(
        children: [
          const SizedBox(width: 6),
          CustomTooltip(
            message: !admin.accountInfo.enabled ? "Habilitar" : "Deshabilitar",
            child: InkWell(
              onTap: () async {
                if (globalContext == null) return;

                bool itsConfirmed = await confirm(
                  globalContext,
                  title: Text(
                    (!admin.accountInfo.enabled)
                        ? "Habilitar Administrador"
                        : "Deshabilitar Administrador",
                    style: TextStyle(
                      color: UiVariables.primaryColor,
                    ),
                  ),
                  content: Text(
                    (!admin.accountInfo.enabled)
                        ? "¿Quieres habilitar a ${admin.profileInfo.names} ${admin.profileInfo.lastNames}?"
                        : "¿Quieres deshabilitar a ${admin.profileInfo.names} ${admin.profileInfo.lastNames}?",
                  ),
                  textCancel: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                  textOK: const Text(
                    "Aceptar",
                    style: TextStyle(color: Colors.blue),
                  ),
                );

                if (!itsConfirmed) return;

                await adminProvider.enableDisableAdmin(
                  index,
                  !admin.accountInfo.enabled,
                );
              },
              child: Icon(
                (!admin.accountInfo.enabled)
                    ? Icons.check_box_rounded
                    : Icons.disabled_by_default_rounded,
                color: Colors.black54,
                size: 20,
              ),
            ),
          )
        ],
      );
    }

    CustomTooltip getActionItem(
      bool isEnabled,
      String message,
      IconData icon,
      String type,
      Request request, {
      Color? iconColor,
    }) {
      return CustomTooltip(
        message: message,
        child: InkWell(
          onTap: () async => !isEnabled
              ? null
              : await RequestActionDialog.show(
                  type,
                  message,
                  request,
                  widget.event!,
                ),
          child: Icon(
            icon,
            size: 18,
            color: (iconColor != null)
                ? iconColor
                : isEnabled
                    ? Colors.black54
                    : Colors.grey.withOpacity(0.65),
          ),
        ),
      );
    }

    return Column(
      children: [
        widget.type == 'activity-employee'
            ? SizedBox(
                height: widget.screenSize.height * 0.05,
                child: ScrollConfiguration(
                  behavior: CustomScrollBehavior(),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: List<Widget>.from(
                      categories
                          .map(
                            (category) => Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: ChoiceChip(
                                  label: Text(
                                    category["name"],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  selected: selectedCategory == category["key"],
                                  selectedColor:
                                      selectedCategory == category["key"]
                                          ? UiVariables.primaryColor
                                          : Colors.grey,
                                  onSelected: (bool newValue) async {
                                    setState(() {
                                      newValue
                                          ? selectedCategory = category["key"]
                                          : selectedCategory = "";
                                    });

                                    await activityProvider.getEmployeeActivity(
                                      id: widget.employeeId!,
                                      category: selectedCategory,
                                    );
                                  }),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              )
            : const SizedBox(),
        widget.type == 'activity-employee'
            ? SizedBox(
                width: widget.screenSize.blockWidth >= 920
                    ? widget.screenSize.blockWidth / 3
                    : widget.screenSize.blockWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: widget.screenSize.blockWidth,
                    child: CustomSearchBar(
                      onChange: activityProvider.filterEmployeeActivity,
                      hint: "Buscar reporte",
                    ),
                  ),
                ),
              )
            : const SizedBox(),
        OverflowBar(
          overflowSpacing: 15,
          children: [
            widget.listData.isNotEmpty
                ? GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: widget.listData.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.screenSize.blockWidth >= 532 &&
                              widget.screenSize.blockWidth <= 1120
                          ? 2
                          : 1,
                      crossAxisSpacing: 10,
                      mainAxisExtent: mainExtent,
                    ),
                    itemBuilder: (_, int index) {
                      String employeeFullname = '';
                      String statusName = '';
                      if (widget.type == 'employees') {
                        employeeFullname = CodeUtils.getFormatedName(
                            colaboradorEmployee[index].profileInfo.names,
                            colaboradorEmployee[index].profileInfo.lastNames);

                        statusName = CodeUtils.getEmployeeStatusName(
                            colaboradorEmployee[index].accountInfo.status);
                      }

                      String status = '';

                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Column(
                            children: List.generate(
                              widget.listData[index].length,
                              (indexValue) {
                                String item =
                                    widget.listData[index][indexValue];
                                Widget statusWidget =
                                    const Chip(label: Text('Sin información'));
                                Widget actions = const Row();
                                Widget files = const Wrap();
                                List<Widget> attachments = [];
                                historyMessage.clear();
                                historyMessage =
                                    messageProvider.filteredMessages;
                                if (item.contains('Estado')) {
                                  status = item.split('-')[1];
                                }
                                if (widget.type == 'requests-event') {
                                  if (eventRequest[index].details.status <= 4) {
                                    isEmployeeRatingEnabled = true;
                                  }
                                  if (eventRequest[index].details.status >= 1 &&
                                      eventRequest[index].details.status <= 4) {
                                    isEmployeeFavoriteEnabled = true;
                                    isBlockEmployeeEnabled = true;

                                    favoriteIconColor = (authProvider
                                            .webUser.company.favoriteEmployees
                                            .any(
                                      (favoriteEmployee) =>
                                          favoriteEmployee.uid ==
                                          eventRequest[index].employeeInfo.id,
                                    ))
                                        ? Colors.red
                                        : null;

                                    blockedIconColor = (authProvider
                                            .webUser.company.blockedEmployees
                                            .any(
                                      (blockedEmployee) =>
                                          blockedEmployee.uid ==
                                          eventRequest[index].employeeInfo.id,
                                    ))
                                        ? Colors.orange
                                        : null;

                                    ratedIconColor = eventRequest[index]
                                            .details
                                            .rate
                                            .isNotEmpty
                                        ? Colors.amber
                                        : null;
                                  }
                                }
                                if (item.split('-')[0] == 'Estado') {
                                  widget.type == 'employees'
                                      ? statusWidget = CustomTooltip(
                                          message: statusName,
                                          child: Chip(
                                            label: Text(
                                              statusName,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            backgroundColor: CodeUtils
                                                .getEmployeeStatusColor(
                                              colaboradorEmployee[index]
                                                  .accountInfo
                                                  .status,
                                            ),
                                          ),
                                        )
                                      : widget.type == 'requests-event' ||
                                              widget.type == 'request-employee'
                                          ? statusWidget = Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: widget.type ==
                                                        'requests-event'
                                                    ? CodeUtils.getStatusColor(
                                                        eventRequest[index]
                                                            .details
                                                            .status,
                                                        true)
                                                    : CodeUtils.getStatusColor(
                                                        widget
                                                            .listRequestEmployees![
                                                                index]
                                                            .details
                                                            .status,
                                                        true),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Text(
                                                widget.type == 'requests-event'
                                                    ? CodeUtils.getStatusName(
                                                        eventRequest[index]
                                                            .details
                                                            .status)
                                                    : CodeUtils.getStatusName(
                                                        widget
                                                            .listRequestEmployees![
                                                                index]
                                                            .details
                                                            .status),
                                                style: const TextStyle(
                                                    color: Colors.black87),
                                              ),
                                            )
                                          : widget.type == 'request-admin'
                                              ? statusWidget = Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: CodeUtils
                                                        .getStatusColor(
                                                            adminFilteredRequest[
                                                                    index]
                                                                .details
                                                                .status,
                                                            true),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                  child: Text(
                                                    CodeUtils.getStatusName(
                                                        adminFilteredRequest[
                                                                index]
                                                            .details
                                                            .status),
                                                    style: const TextStyle(
                                                        color: Colors.black87),
                                                  ),
                                                )
                                              : widget.type ==
                                                      'message-employees'
                                                  ? statusWidget = Chip(
                                                      label: Text(
                                                        CodeUtils
                                                            .getEmployeeStatusName(
                                                                employeeMessage[
                                                                        index]
                                                                    .status),
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.black),
                                                      ),
                                                      backgroundColor: CodeUtils
                                                          .getEmployeeStatusColor(
                                                        employeeMessage[index]
                                                            .status,
                                                      ),
                                                    )
                                                  : widget.type ==
                                                          'pre-register'
                                                      ? statusWidget = Chip(
                                                          label: Text(
                                                            status == '1'
                                                                ? 'Aprobado'
                                                                : "Por aprobar",
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                          backgroundColor:
                                                              status == '1'
                                                                  ? Colors.green
                                                                  : Colors
                                                                      .orange,
                                                        )
                                                      : statusWidget = Chip(
                                                          label: Text(
                                                            status == '1' ||
                                                                    status ==
                                                                        'true'
                                                                ? 'Habilitado'
                                                                : "Deshabilitado",
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                          backgroundColor:
                                                              status == '1' ||
                                                                      status ==
                                                                          'true'
                                                                  ? Colors.green
                                                                  : Colors
                                                                      .orange,
                                                        );
                                }
                                if (item.split('-')[0] == 'Estado docs') {
                                  statusWidget = Chip(
                                    label: Text(
                                      status == '1' ? 'Completo' : "Imcompleto",
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: status == '1'
                                        ? Colors.green
                                        : Colors.orange,
                                  );
                                }

                                if (item.contains('Turnos')) {
                                  actions = InkWell(
                                    onTap: () {
                                      paymentsProvider.updateSelectedPayment(
                                          widget.listPayment![index]);
                                      paymentsProvider.updateDetailsStatus(
                                          true, widget.isClient!);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      child: const Icon(Icons.work),
                                    ),
                                  );
                                }

                                if (item.contains('Acciones')) {
                                  switch (widget.type) {
                                    case 'client':
                                      actions = Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CustomTooltip(
                                            message: "Ver detalles",
                                            child: InkWell(
                                              onTap: () =>
                                                  provider.showClientDetails(
                                                      client: client[index]),
                                              child: const Icon(
                                                Icons.account_circle,
                                                color: Colors.black54,
                                                size: 19,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          CustomTooltip(
                                            message: "Eliminar cliente",
                                            child: InkWell(
                                              onTap: () async {
                                                // if (context == null) return;
                                                bool itsConfirmed =
                                                    await confirm(
                                                  context,
                                                  title: Text(
                                                    "Eliminar cliente",
                                                    style: TextStyle(
                                                      color: UiVariables
                                                          .primaryColor,
                                                    ),
                                                  ),
                                                  content: const Text(
                                                    "¿Quieres eliminar a {client.name}?",
                                                  ),
                                                  textCancel: const Text(
                                                    "Cancelar",
                                                    style: TextStyle(
                                                        color: Colors.grey),
                                                  ),
                                                  textOK: const Text(
                                                    "Aceptar",
                                                    style: TextStyle(
                                                        color: Colors.blue),
                                                  ),
                                                );
                                                if (!itsConfirmed) return;
                                                UiMethods().showLoadingDialog(
                                                    context: context);
                                                adminProvider.allCompanies;
                                                await adminProvider.deleteAdmin(
                                                    client[index]
                                                        .accountInfo
                                                        .id);
                                                await provider.deleteClient(
                                                    id: client[index]
                                                        .accountInfo
                                                        .id);
                                                UiMethods().hideLoadingDialog(
                                                    context: context);
                                              },
                                              child: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 19,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          CustomTooltip(
                                            message: status == '0'
                                                ? "Habilitar"
                                                : "Deshabilitar",
                                            child: InkWell(
                                              onTap: () async {
                                                //if (context == null) return;

                                                bool itsConfirmed =
                                                    await confirm(
                                                  context,
                                                  title: Text(
                                                    status == '0'
                                                        ? "Habilitar Cliente"
                                                        : "Deshabilitar Cliente",
                                                    style: TextStyle(
                                                      color: UiVariables
                                                          .primaryColor,
                                                    ),
                                                  ),
                                                  content: Text(
                                                    status == '0'
                                                        ? "¿Quieres habilitar a {client.name}?"
                                                        : "¿Quieres deshabilitar a {client.name}?",
                                                  ),
                                                  textCancel: const Text(
                                                    "Cancelar",
                                                    style: TextStyle(
                                                        color: Colors.grey),
                                                  ),
                                                  textOK: const Text(
                                                    "Aceptar",
                                                    style: TextStyle(
                                                        color: Colors.blue),
                                                  ),
                                                );
                                                if (!itsConfirmed) return;
                                                //Validar si es admin
                                                await provider
                                                    .enableDisableClient(
                                                        index,
                                                        status == '1' ? 0 : 1,
                                                        true);
                                              },
                                              child: Icon(
                                                status == '0'
                                                    ? Icons.check_box_rounded
                                                    : Icons
                                                        .disabled_by_default_rounded,
                                                color: Colors.black54,
                                                size: 20,
                                              ),
                                            ),
                                          )
                                        ],
                                      );
                                      break;
                                    case 'select-job':
                                    case 'add-fav':
                                    case 'add-lock':
                                    case 'message-employees':
                                    case 'selected-client':
                                      actions = Center(
                                        child: Checkbox(
                                          value:
                                              widget.type == 'message-employees'
                                                  ? employeeMessage[index]
                                                      .isSelected
                                                  : selectedIndex == index,
                                          onChanged: widget.type ==
                                                  'message-employees'
                                              ? (bool? newValue) =>
                                                  messageProvider
                                                      .onEmployeeSelection(
                                                          index, newValue!)
                                              : (bool? newValue) {
                                                  if (newValue!) {
                                                    setState(
                                                      () {
                                                        selectedIndex = index;
                                                      },
                                                    );
                                                  } else {
                                                    selectedIndex = -1;
                                                  }
                                                },
                                        ),
                                      );
                                      break;
                                    case 'favs':
                                    case 'locks':
                                    case 'web-users':
                                      actions = Center(
                                        child: CustomTooltip(
                                          message: widget.type == 'favs'
                                              ? "Eliminar de favoritos"
                                              : widget.type == 'locks'
                                                  ? "Eliminar de bloqueados"
                                                  : "Eliminar de la lista de usuarios",
                                          child: InkWell(
                                              child: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onTap: () async {
                                                BuildContext? _ =
                                                    NavigationService
                                                        .getGlobalContext();
                                                UiMethods().showLoadingDialog(
                                                    context: context);
                                                await provider.updateClientInfo(
                                                  {
                                                    "action": "delete",
                                                    "employee": {
                                                      "uid": widget.type ==
                                                              'favs'
                                                          ? fav[index]["uid"]
                                                          : widget.type ==
                                                                  'locks'
                                                              ? lock[index]
                                                                  ["uid"]
                                                              : webUser[index]
                                                                  ['uid'],
                                                    },
                                                  },
                                                  widget.type == 'favs'
                                                      ? "favs"
                                                      : widget.type == 'lock'
                                                          ? "locks"
                                                          : "webUsers",
                                                );
                                                UiMethods().hideLoadingDialog(
                                                    context: context);
                                              }),
                                        ),
                                      );
                                      break;

                                    case 'web-user-client':
                                    case 'fav-client':
                                    case 'lock-client':
                                      actions = Center(
                                        child: CustomTooltip(
                                          message: widget.type == 'fav-client'
                                              ? "Eliminar de favoritos"
                                              : widget.type == 'lock-client'
                                                  ? "Eliminar de bloqueados"
                                                  : "Eliminar de la lista de usuarios",
                                          child: InkWell(
                                              child: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onTap: () async {
                                                BuildContext? _ =
                                                    NavigationService
                                                        .getGlobalContext();
                                                UiMethods().showLoadingDialog(
                                                    context: context);
                                                await provider.updateClientInfo(
                                                  {
                                                    "action": "delete",
                                                    "employee": {
                                                      "uid": widget.type ==
                                                              'fav-client'
                                                          ? favClient[index].uid
                                                          : widget.type ==
                                                                  'lock-client'
                                                              ? lockClient[
                                                                      index]
                                                                  .uid
                                                              : webUserClient[
                                                                  index]['uid'],
                                                    },
                                                  },
                                                  widget.type == 'fav-client'
                                                      ? "favs"
                                                      : widget.type ==
                                                              'lock-client'
                                                          ? "locks"
                                                          : "webUsers",
                                                  false,
                                                );
                                                UiMethods().hideLoadingDialog(
                                                    context: context);
                                              }),
                                        ),
                                      );
                                      break;
                                    case 'pre-register':
                                      actions = Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CustomTooltip(
                                            message: "Ver detalles",
                                            child: InkWell(
                                              onTap: () => preRegisteredProvider
                                                  .showEmployeeDetails(
                                                      employee:
                                                          preEmployee[index]),
                                              child: const Icon(
                                                Icons.account_circle,
                                                color: Colors.black54,
                                                size: 19,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          CustomTooltip(
                                            message: "Aprobar",
                                            child: InkWell(
                                              onTap: () async {
                                                BuildContext? globalContext =
                                                    NavigationService
                                                        .getGlobalContext();

                                                if (globalContext == null) {
                                                  return;
                                                }

                                                bool itsConfirmed =
                                                    await confirm(
                                                  globalContext,
                                                  title: Text(
                                                    "Aprobar colaborador",
                                                    style: TextStyle(
                                                      color: UiVariables
                                                          .primaryColor,
                                                    ),
                                                  ),
                                                  content: const Text(
                                                    "¿Quieres aprobar a este colaborador? Este cambio le permitirá recibir solicitudes",
                                                  ),
                                                  textCancel: const Text(
                                                    "Cancelar",
                                                    style: TextStyle(
                                                        color: Colors.grey),
                                                  ),
                                                  textOK: const Text(
                                                    "Aceptar",
                                                    style: TextStyle(
                                                        color: Colors.blue),
                                                  ),
                                                );

                                                if (!itsConfirmed) return;

                                                if (preEmployee[index]
                                                        .docsStatus
                                                        .value ==
                                                    0) {
                                                  LocalNotificationService
                                                      .showSnackBar(
                                                    type: "fail",
                                                    message:
                                                        "El colaborador no ha subido ningún documento requerido",
                                                    icon: Icons.error_outline,
                                                  );
                                                  return;
                                                }

                                                if (preEmployee[index]
                                                        .docsStatus
                                                        .value ==
                                                    1) {
                                                  LocalNotificationService
                                                      .showSnackBar(
                                                    type: "fail",
                                                    message:
                                                        "El colaborador aún no ha subido todos los documentos requeridos",
                                                    icon: Icons.error_outline,
                                                  );
                                                  return;
                                                }

                                                Map<String, dynamic>
                                                    generalDocsData =
                                                    Provider.of<
                                                            GeneralInfoProvider>(
                                                  globalContext,
                                                  listen: false,
                                                )
                                                        .generalInfo
                                                        .countryInfo
                                                        .requiredDocs;
                                                //Validate if all added required docs are approved
                                                bool allApproved = true;

                                                for (String generalDocKey
                                                    in generalDocsData.keys
                                                        .toList()) {
                                                  if (preEmployee[index]
                                                      .documents
                                                      .values
                                                      .toList()
                                                      .any(
                                                        (employeeDoc) =>
                                                            employeeDoc[
                                                                    "value"] ==
                                                                generalDocKey &&
                                                            generalDocsData[
                                                                    generalDocKey]
                                                                ["required"] &&
                                                            employeeDoc[
                                                                    "approval_status"] !=
                                                                1,
                                                      )) {
                                                    LocalNotificationService
                                                        .showSnackBar(
                                                      type: "fail",
                                                      message:
                                                          "Todos los documentos requeridos del colaborador deben estar aprobados",
                                                      icon: Icons.error_outline,
                                                    );
                                                    allApproved = false;

                                                    break;
                                                  }
                                                }

                                                if (!allApproved) return;

                                                UiMethods().showLoadingDialog(
                                                  context: globalContext,
                                                );

                                                await preRegisteredProvider
                                                    .approveEmployee(
                                                  preEmployee[index].id,
                                                  CodeUtils.getFormatedName(
                                                    preEmployee[index]
                                                        .profileInfo
                                                        .names,
                                                    preEmployee[index]
                                                        .profileInfo
                                                        .lastNames,
                                                  ),
                                                  context,
                                                );

                                                UiMethods().hideLoadingDialog(
                                                    context: globalContext);
                                              },
                                              child: const Icon(
                                                Icons.check_circle,
                                                color: Colors.black54,
                                                size: 19,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                      break;
                                    case 'employees':
                                      actions = Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          buildDetailsBtn(
                                              colaboradorEmployee[index]),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          buildChangePhoneBtn(
                                              colaboradorEmployee[index]),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          if (status == '1' ||
                                              status == '7' ||
                                              status == '5')
                                            buildenableDisableBtn(
                                                int.parse(status),
                                                employeeFullname,
                                                colaboradorEmployee[index],
                                                context),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          if (status != '2')
                                            buildLockUnlockBtn(
                                                colaboradorEmployee[index],
                                                employeeFullname,
                                                context),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          if (status != '2')
                                            CustomTooltip(
                                              message: "Eliminar",
                                              child: InkWell(
                                                onTap: () async {
                                                  // if (context == null) return;
                                                  bool itsConfirmed =
                                                      await confirm(
                                                    context,
                                                    title: Text(
                                                      "Eliminar colaborador",
                                                      style: TextStyle(
                                                        color: UiVariables
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      "¿Quieres eliminar a $employeeFullname?",
                                                    ),
                                                    textCancel: const Text(
                                                      "Cancelar",
                                                      style: TextStyle(
                                                          color: Colors.grey),
                                                    ),
                                                    textOK: const Text(
                                                      "Aceptar",
                                                      style: TextStyle(
                                                          color: Colors.blue),
                                                    ),
                                                  );

                                                  if (!itsConfirmed) return;

                                                  UiMethods().showLoadingDialog(
                                                      context: context);
                                                  bool resp =
                                                      await EmployeeServices
                                                          .delete(
                                                    colaboradorEmployee[index]
                                                        .id,
                                                    CodeUtils.getFormatedName(
                                                      colaboradorEmployee[index]
                                                          .profileInfo
                                                          .names,
                                                      colaboradorEmployee[index]
                                                          .profileInfo
                                                          .lastNames,
                                                    ),
                                                    context,
                                                  );
                                                  UiMethods().hideLoadingDialog(
                                                      context: context);

                                                  if (resp) {
                                                    EmployeesProvider
                                                        employeesProvider =
                                                        Provider.of<
                                                            EmployeesProvider>(
                                                      context,
                                                      listen: false,
                                                    );
                                                    employeesProvider
                                                        .updateLocalEmployeesList(
                                                      isDelete: true,
                                                      index: employeesProvider
                                                          .filteredEmployees
                                                          .indexWhere(
                                                        (element) =>
                                                            element.id ==
                                                            colaboradorEmployee[
                                                                    index]
                                                                .id,
                                                      ),
                                                    );
                                                    LocalNotificationService
                                                        .showSnackBar(
                                                      type: "success",
                                                      message:
                                                          "Colaborador eliminado correctamente",
                                                      icon: Icons.check,
                                                    );
                                                  } else {
                                                    LocalNotificationService
                                                        .showSnackBar(
                                                      type: "fail",
                                                      message:
                                                          "Ocurrió un error, intenta nuevamente",
                                                      icon: Icons.error_outline,
                                                    );
                                                  }
                                                },
                                                child: const Icon(
                                                  Icons.delete_rounded,
                                                  color: Colors.black54,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                      break;
                                    case 'historical-payment-employees':
                                    case 'history-messages':
                                      actions = CustomTooltip(
                                        message: "Ver detalles",
                                        child: InkWell(
                                          onTap: () {
                                            if (widget.type ==
                                                'history-messages') {
                                              historyMessage = [
                                                ...messageProvider.allMessages
                                              ];
                                              MessageDetails.show(
                                                  historyMessage[index]);
                                            } else {
                                              PaymentRequestsDialog.show(
                                                  payment[index]);
                                            }
                                          },
                                          child: const Icon(
                                            Icons.info_outline,
                                            color: Colors.black54,
                                            size: 20,
                                          ),
                                        ),
                                      );
                                      break;
                                    case 'admin':
                                      actions = Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          buildEnableDisableBtn(
                                            admin[index],
                                            context,
                                            index,
                                          ),
                                          Row(
                                            children: [
                                              const SizedBox(width: 6),
                                              CustomTooltip(
                                                message: "Editar",
                                                child: InkWell(
                                                  onTap: () async =>
                                                      await CreateAdminDialog
                                                          .show(
                                                              adminToEdit:
                                                                  admin[index]),
                                                  child: const Icon(
                                                    Icons.edit,
                                                    color: Colors.black54,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          buildDeleteBtn(context, admin[index]),
                                        ],
                                      );
                                      break;
                                    case 'request-admin':
                                      actions = (requestProvider
                                                  .adminRequestsType ==
                                              "deleted")
                                          ? const SizedBox()
                                          : Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CustomTooltip(
                                                  message:
                                                      "Historial solicitud",
                                                  child: InkWell(
                                                    onTap: () =>
                                                        AdminRequestAction
                                                            .showActionDialog(
                                                      type: "history",
                                                      requestIndex: index,
                                                      provider: requestProvider,
                                                    ),
                                                    child: const Icon(
                                                      Icons.history,
                                                      color: Colors.black54,
                                                      size: 19,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                CustomTooltip(
                                                  message: "Editar solicitud",
                                                  child: InkWell(
                                                    onTap: () {
                                                      if (adminFilteredRequest[
                                                                  index]
                                                              .details
                                                              .status ==
                                                          0) return;
                                                      AdminRequestAction
                                                          .showActionDialog(
                                                        type: "edit",
                                                        requestIndex: index,
                                                        provider:
                                                            requestProvider,
                                                      );
                                                    },
                                                    child: Icon(
                                                      Icons.edit,
                                                      color:
                                                          (adminFilteredRequest[
                                                                          index]
                                                                      .details
                                                                      .status ==
                                                                  0)
                                                              ? Colors.grey[300]
                                                              : Colors.black54,
                                                      size: 19,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                CustomTooltip(
                                                  message: "Clonar solicitud",
                                                  child: InkWell(
                                                    onTap: () async {
                                                      Event? event =
                                                          await requestProvider
                                                              .getRequestEvent(
                                                                  adminFilteredRequest[
                                                                      index]);
                                                      if (event == null) {
                                                        return;
                                                      }
                                                      await RequestActionDialog
                                                          .show(
                                                        "clone",
                                                        "Clonar solicitud",
                                                        adminFilteredRequest[
                                                            index],
                                                        event,
                                                      );
                                                    },
                                                    child: const Icon(
                                                      Icons.content_copy,
                                                      color: Colors.black54,
                                                      size: 19,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                CustomTooltip(
                                                  message:
                                                      "Mensaje al colaborador",
                                                  child: InkWell(
                                                    onTap: () async {
                                                      if (adminFilteredRequest[
                                                              index]
                                                          .employeeInfo
                                                          .names
                                                          .isEmpty) return;
                                                      await EventMessageService
                                                          .send(
                                                        eventItem: null,
                                                        employeesIds: [
                                                          adminFilteredRequest[
                                                                  index]
                                                              .employeeInfo
                                                              .id
                                                        ],
                                                        company: null,
                                                        screenSize:
                                                            widget.screenSize,
                                                        employeeName: CodeUtils
                                                            .getFormatedName(
                                                          adminFilteredRequest[
                                                                  index]
                                                              .employeeInfo
                                                              .names,
                                                          adminFilteredRequest[
                                                                  index]
                                                              .employeeInfo
                                                              .lastNames,
                                                        ),
                                                      );
                                                    },
                                                    child: Icon(
                                                      Icons
                                                          .circle_notifications_outlined,
                                                      color:
                                                          (adminFilteredRequest[
                                                                      index]
                                                                  .employeeInfo
                                                                  .names
                                                                  .isEmpty)
                                                              ? Colors.grey[300]
                                                              : Colors.black54,
                                                      size: 19,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                CustomTooltip(
                                                  message: "Eliminar solicitud",
                                                  child: InkWell(
                                                    onTap: () async {
                                                      // if (adminFilteredRequest[
                                                      //             index]
                                                      //         .details
                                                      //         .status >
                                                      //     2) return;
                                                      await requestProvider
                                                          .deleteRequest(
                                                              adminFilteredRequest[
                                                                  index]);
                                                    },
                                                    child: const Icon(
                                                      Icons.delete,
                                                      color:
                                                          // adminFilteredRequest[
                                                          //                 index]
                                                          //             .details
                                                          //             .status >
                                                          //         2
                                                          //     ?
                                                          //     Colors.grey[300]
                                                          //     :
                                                          Colors.black54,
                                                      size: 19,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );

                                      break;
                                    case 'requests-event':
                                      widget.isAdmin!
                                          ? actions = Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                CustomTooltip(
                                                  message:
                                                      "Historial solicitud",
                                                  child: InkWell(
                                                    onTap: () =>
                                                        AdminRequestAction
                                                            .showActionDialog(
                                                      type: "history",
                                                      requestIndex: index,
                                                      provider: requestProvider,
                                                    ),
                                                    child: const Icon(
                                                      Icons.history,
                                                      color: Colors.black54,
                                                      size: 19,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                CustomTooltip(
                                                  message: "Editar solicitud",
                                                  child: InkWell(
                                                    onTap: () async {
                                                      if (eventRequest[index]
                                                              .details
                                                              .status ==
                                                          0) return;
                                                      AdminRequestAction
                                                          .showActionDialog(
                                                        type: "edit",
                                                        requestIndex: index,
                                                        provider:
                                                            requestProvider,
                                                      );
                                                    },
                                                    child: Icon(
                                                      Icons.edit,
                                                      color:
                                                          (eventRequest[index]
                                                                      .details
                                                                      .status ==
                                                                  0)
                                                              ? Colors.grey[300]
                                                              : Colors.black54,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                CustomTooltip(
                                                  message: "Clonar solicitud",
                                                  child: InkWell(
                                                    onTap: () async {
                                                      Event? event =
                                                          await requestProvider
                                                              .getRequestEvent(
                                                                  eventRequest[
                                                                      index]);
                                                      if (event == null) return;
                                                      await RequestActionDialog
                                                          .show(
                                                        "clone",
                                                        "Clonar solicitud",
                                                        eventRequest[index],
                                                        event,
                                                      );
                                                    },
                                                    child: const Icon(
                                                      Icons.content_copy,
                                                      color: Colors.black54,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                CustomTooltip(
                                                  message:
                                                      "Mensaje al colaborador",
                                                  child: InkWell(
                                                    onTap: () async {
                                                      if (eventRequest[index]
                                                          .employeeInfo
                                                          .names
                                                          .isEmpty) return;
                                                      await EventMessageService
                                                          .send(
                                                        eventItem: null,
                                                        employeesIds: [
                                                          eventRequest[index]
                                                              .employeeInfo
                                                              .id
                                                        ],
                                                        company: null,
                                                        screenSize:
                                                            widget.screenSize,
                                                        employeeName: CodeUtils
                                                            .getFormatedName(
                                                          eventRequest[index]
                                                              .employeeInfo
                                                              .names,
                                                          eventRequest[index]
                                                              .employeeInfo
                                                              .lastNames,
                                                        ),
                                                      );
                                                    },
                                                    child: Icon(
                                                      Icons
                                                          .circle_notifications_outlined,
                                                      color:
                                                          (eventRequest[index]
                                                                  .employeeInfo
                                                                  .names
                                                                  .isEmpty)
                                                              ? Colors.grey[300]
                                                              : Colors.black54,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                CustomTooltip(
                                                  message: "Eliminar solicitud",
                                                  child: InkWell(
                                                    onTap: () async {
                                                      // if (eventRequest[index]
                                                      //         .details
                                                      //         .status >
                                                      //     2) return;
                                                      await requestProvider
                                                          .deleteRequest(
                                                        eventRequest[index],
                                                      );
                                                    },
                                                    child: const Icon(
                                                      Icons.delete,
                                                      color:
                                                          // eventRequest[index]
                                                          //             .details
                                                          //             .status >
                                                          //         2
                                                          //     ? Colors.grey[300]
                                                          //:
                                                          Colors.black54,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : actions = Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                getActionItem(
                                                    eventRequest[index]
                                                            .details
                                                            .status <
                                                        4,
                                                    "Modificar horario",
                                                    Icons.access_time,
                                                    "time",
                                                    eventRequest[index]),
                                                const SizedBox(width: 10),
                                                getActionItem(
                                                    true,
                                                    "Clonar",
                                                    Icons.content_copy,
                                                    "clone",
                                                    eventRequest[index]),
                                                const SizedBox(width: 10),
                                                getActionItem(
                                                    eventRequest[index]
                                                            .details
                                                            .status <
                                                        4,
                                                    "Editar",
                                                    Icons.create_outlined,
                                                    "edit",
                                                    eventRequest[index]),
                                                const SizedBox(width: 10),
                                                getActionItem(
                                                  isEmployeeRatingEnabled,
                                                  ratedIconColor != null
                                                      ? "Ver Calificación"
                                                      : "Calificar colaborador",
                                                  Icons.star_outline,
                                                  "rate",
                                                  eventRequest[index],
                                                  iconColor: ratedIconColor,
                                                ),
                                                const SizedBox(width: 10),
                                                getActionItem(
                                                  isEmployeeFavoriteEnabled,
                                                  favoriteIconColor != null
                                                      ? "Eliminar de favoritos"
                                                      : "Agregar a favoritos",
                                                  Icons.favorite_border,
                                                  "favorite",
                                                  eventRequest[index],
                                                  iconColor: favoriteIconColor,
                                                ),
                                                const SizedBox(width: 10),
                                                getActionItem(
                                                  isBlockEmployeeEnabled,
                                                  blockedIconColor != null
                                                      ? "Desbloquear"
                                                      : "Agregar a bloqueados",
                                                  Icons.block,
                                                  "block",
                                                  eventRequest[index],
                                                  iconColor: blockedIconColor,
                                                ),
                                              ],
                                            );
                                      break;
                                    default:
                                  }
                                }

                                if (item.split('-')[0] == 'Adjuntos') {
                                  attachments = List<Widget>.from(
                                      item.split(',').map((fileUrl) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: MessageAttachedWidget(
                                          fileUrl: fileUrl),
                                    );
                                  }).toList());
                                }
                                if (item.split('-')[0] == 'Adjuntos') {
                                  item.split('-')[1].isEmpty ||
                                          item.split('-')[1] == ''
                                      ? files = const Text("Sin Adjuntos")
                                      : files = Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          direction: Axis.horizontal,
                                          children: attachments,
                                        );
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        height: 15,
                                      ),
                                      Text(
                                        item.split('-')[0],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      item.contains('Turnos')
                                          ? actions
                                          : item.contains('¿Leído?') ||
                                                  item.contains('¿Eliminado?')
                                              ? Chip(
                                                  backgroundColor:
                                                      item.split('-')[1] ==
                                                              'true'
                                                          ? Colors.green
                                                          : Colors.grey,
                                                  label: Text(
                                                    item.split('-')[1] == 'true'
                                                        ? "Sí"
                                                        : "No",
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                )
                                              : item
                                                          .split('-')[0]
                                                          .contains('Imagen') ||
                                                      item
                                                          .split('-')[0]
                                                          .contains('Foto')
                                                  ? CircleAvatar(
                                                      backgroundImage: item
                                                                  .split(
                                                                      '-')[1] ==
                                                              ''
                                                          ? const NetworkImage(
                                                              'https://firebasestorage.googleapis.com/v0/b/huts-services.appspot.com/o/no_user_image.png?alt=media&token=697082b3-7ae8-4fc0-8943-a2efbbd0f788')
                                                          : NetworkImage(item
                                                              .split('-')[1]),
                                                    )
                                                  : item
                                                          .split('-')[0]
                                                          .contains('Estado')
                                                      ? statusWidget
                                                      : item
                                                              .split('-')[0]
                                                              .contains(
                                                                  'Acciones')
                                                          ? actions
                                                          : item
                                                                  .split('-')[0]
                                                                  .contains(
                                                                      'Adjuntos')
                                                              ? files
                                                              : Text(
                                                                  item.contains(
                                                                          'Tipo usuario')
                                                                      ? item.split(
                                                                              '-')[
                                                                          1]
                                                                      : item.contains('Tipo') &&
                                                                              widget.type ==
                                                                                  'admin'
                                                                          ? item
                                                                              .split('-')[1]
                                                                          : item.contains('Tipo responsable')
                                                                              ? item.split('-')[1]
                                                                              : item.contains('SubTipo')
                                                                                  ? item.split('-')[1]
                                                                                  : item.contains('Tipo')
                                                                                      ? '${item.split('-')[1]} -${item.split('-')[2]}' '${item.split('-')[1]} -${item.split('-')[2]}'
                                                                                      : item.split('-')[1],
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      color: Colors
                                                                          .grey),
                                                                ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        "No hay información",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
            widget.type == 'selected-client' || widget.type == 'add-fav'
                ? Positioned(
                    bottom: 20,
                    right: 30,
                    child: InkWell(
                      onTap: () {
                        if (widget.type != 'selected-client' ||
                            widget.type == 'add-fav') {
                          return;
                        }
                        if (selectedIndex == -1) {
                          LocalNotificationService.showSnackBar(
                            type: "fail",
                            message: "Debes seleccionar un cliente",
                            icon: Icons.error_outline,
                          );
                          return;
                        }
                        widget.type == 'add-fav'
                            ? Navigator.of(context).pop(
                                colaboradorEmployee[selectedIndex],
                              )
                            : Navigator.of(context).pop(
                                client[selectedIndex],
                              );
                        selectedIndex = -1;
                      },
                      child: Container(
                        width: widget.screenSize.blockWidth >= 920
                            ? widget.screenSize.blockWidth * 0.08
                            : 200,
                        height: 35,
                        decoration: BoxDecoration(
                          color: UiVariables.primaryColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "Aceptar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  widget.screenSize.blockWidth >= 920 ? 15 : 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox()
          ],
        ),
      ],
    );
  }

  Row buildLockUnlockBtn(
      Employee employee, String employeeFullname, BuildContext? globalContext) {
    return Row(
      children: [
        const SizedBox(width: 6),
        CustomTooltip(
          message:
              (employee.accountInfo.status == 3) ? "Desbloquear" : "Bloquear",
          child: InkWell(
            onTap: () async {
              if (globalContext == null) return;

              if (employee.accountInfo.status == 3) {
                bool itsConfirmed = await confirm(
                  globalContext,
                  title: Text(
                    "Desbloquear colaborador",
                    style: TextStyle(
                      color: UiVariables.primaryColor,
                    ),
                  ),
                  content: Text(
                    "¿Quieres desbloquear a $employeeFullname?",
                  ),
                  textCancel: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                  textOK: const Text(
                    "Aceptar",
                    style: TextStyle(color: Colors.blue),
                  ),
                );

                if (!itsConfirmed) return;

                UiMethods().showLoadingDialog(context: globalContext);
                bool resp = await EmployeeServices.unlock(
                  employee.id,
                  CodeUtils.getFormatedName(
                    employee.profileInfo.names,
                    employee.profileInfo.lastNames,
                  ),
                );
                UiMethods().hideLoadingDialog(context: globalContext);

                if (resp) {
                  employee.accountInfo.status = 1;
                  employee.accountInfo.unlockDate = DateTime.now();
                  Provider.of<EmployeesProvider>(
                    globalContext,
                    listen: false,
                  ).updateLocalEmployeeData(employee);
                  LocalNotificationService.showSnackBar(
                    type: "success",
                    message: "Colaborador desbloqueado correctamente",
                    icon: Icons.check,
                  );
                } else {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "Ocurrió un error, intenta nuevamente",
                    icon: Icons.error_outline,
                  );
                }
                return;
              }
              await LockDialog.show(employee);
            },
            child: Icon(
              (employee.accountInfo.status == 3)
                  ? Icons.lock_open_rounded
                  : Icons.lock_clock_rounded,
              color: Colors.black54,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  CustomTooltip buildChangePhoneBtn(Employee employee) {
    return CustomTooltip(
      message: "Cambiar número teléfono",
      child: InkWell(
        onTap: () async => await ChangePhoneDialog.show(employee),
        child: const Icon(
          Icons.phone_android_rounded,
          color: Colors.black54,
          size: 19,
        ),
      ),
    );
  }

  Row buildenableDisableBtn(int employeeStatus, String employeeFullname,
      Employee employee, BuildContext? globalContext) {
    return Row(
      children: [
        const SizedBox(width: 6),
        CustomTooltip(
          message: (employeeStatus == 5) ? "Habilitar" : "Deshabilitar",
          child: InkWell(
            onTap: () async {
              if (globalContext == null) return;

              bool itsConfirmed = await confirm(
                globalContext,
                title: Text(
                  (employeeStatus == 5)
                      ? "Habilitar colaborador"
                      : "Deshabilitar colaborador",
                  style: TextStyle(
                    color: UiVariables.primaryColor,
                  ),
                ),
                content: Text(
                  (employeeStatus == 5)
                      ? "¿Quieres habilitar a $employeeFullname?"
                      : "¿Quieres deshabilitar a $employeeFullname?",
                ),
                textCancel: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.grey),
                ),
                textOK: const Text(
                  "Aceptar",
                  style: TextStyle(color: Colors.blue),
                ),
              );

              if (!itsConfirmed) return;

              UiMethods().showLoadingDialog(context: globalContext);
              int newStatus = employeeStatus == 5 ? 1 : 5;
              bool resp = await EmployeeServices.enableDisable(
                {
                  "name": CodeUtils.getFormatedName(
                    employee.profileInfo.names,
                    employee.profileInfo.lastNames,
                  ),
                  "id": employee.id,
                  "to_disable": employeeStatus != 5,
                  "new_status": newStatus
                },
                globalContext,
              );
              UiMethods().hideLoadingDialog(context: globalContext);

              String doneAction =
                  employeeStatus == 5 ? "Habilitado" : "Deshabilitado";
              if (resp) {
                employee.accountInfo.status = newStatus;
                Provider.of<EmployeesProvider>(
                  globalContext,
                  listen: false,
                ).updateLocalEmployeeData(employee);
                LocalNotificationService.showSnackBar(
                  type: "success",
                  message: "Colaborador $doneAction correctamente",
                  icon: Icons.check,
                );
              } else {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Ocurrió un error, intenta nuevamente",
                  icon: Icons.error_outline,
                );
              }
            },
            child: Icon(
              (employeeStatus == 5)
                  ? Icons.check_box_rounded
                  : Icons.disabled_by_default_rounded,
              color: Colors.black54,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
