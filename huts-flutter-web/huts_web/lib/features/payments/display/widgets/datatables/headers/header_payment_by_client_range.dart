import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/employees/client_selection/dialog_client.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/display/widgets/datatables/headers/header_table.dart';
import 'package:huts_web/features/payments/display/widgets/item_detail_payment.dart';
import 'package:provider/provider.dart';

import '../../../../../auth/display/providers/auth_provider.dart';
import '../../../../../auth/domain/entities/web_user_entity.dart';
import '../../../../domain/entities/payment_entity.dart';

class HeaderPaymentByClientRange extends StatefulWidget {
  final ScreenSize screenSize;
  final PaymentsProvider paymentsProvider;
  final ClientsProvider clientsProvider;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool selectClient;
  final bool isClient;
  const HeaderPaymentByClientRange({
    Key? key,
    required this.screenSize,
    required this.paymentsProvider,
    required this.clientsProvider,
    required this.startDate,
    required this.endDate,
    required this.selectClient,
    required this.isClient,
  }) : super(key: key);

  @override
  State<HeaderPaymentByClientRange> createState() =>
      _HeaderPaymentByClientRangeState();
}

class _HeaderPaymentByClientRangeState
    extends State<HeaderPaymentByClientRange> {
  late AuthProvider authProvider;
  late WebUser user;
  List<Payment> filteredPayments = [];
  bool isLoaded = false;

  bool isAdmin = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authProvider = Provider.of<AuthProvider>(context);
    user = authProvider.webUser;
    isAdmin = user.accountInfo.type == "admin";
  }

  @override
  Widget build(BuildContext context) {
    ClientsProvider clientsProvider = Provider.of<ClientsProvider>(context);
    bool isDesktop = widget.screenSize.blockWidth >= 1300;
    if (widget.startDate != null && !isAdmin) {
      isLoaded = false;
      if (!isLoaded) {
        isLoaded = true;
        filteredPayments.clear();
        for (var element in widget
            .paymentsProvider.paymentRangeResult.individualPayments) {
          int statusRequest = element.requestInfo.details.status;
          if (statusRequest >= 1 && statusRequest <= 4) {
            filteredPayments.add(element);
          }
        }
      }
    }
    List<Widget> children = [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderTable(
            isDesktop: isDesktop,
            screenSize: widget.screenSize,
            title: isAdmin ? "Pagos Clientes" : "Pagos Generales",
          ),
          if (clientsProvider.selectedClient != null && widget.selectClient)
            Column(
              children: [
                Text(
                  clientsProvider.selectedClient!.name,
                  style: TextStyle(
                    fontSize: widget.screenSize.blockWidth >= 920 ? 16 : 13,
                  ),
                ),
                const SizedBox(
                  height: 3,
                )
              ],
            ),
          isAdmin
              ? widget.selectClient
                  ? buildSelectClientBtn(
                      widget.screenSize,
                      context,
                      widget.paymentsProvider,
                      clientsProvider,
                      widget.startDate,
                      widget.endDate)
                  : const SizedBox()
              : const SizedBox(),
          const SizedBox(
            height: 10,
          )
        ],
      ),
      Column(
        crossAxisAlignment: (isDesktop || widget.screenSize.blockWidth >= 580)
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10, top: 6),
            child: RichText(
              text: TextSpan(
                text: widget.startDate == null && widget.endDate == null
                    ? ""
                    : widget.startDate != null && widget.endDate != null
                        ? "Rango: "
                        : "Día: ",
                style: TextStyle(
                  fontSize: widget.screenSize.width * 0.012,
                ),
                children: [
                  TextSpan(
                    text: widget.startDate == null && widget.endDate == null
                        ? "Rango sin seleccionar"
                        : widget.startDate != null && widget.endDate != null
                            ? "${CodeUtils.formatDateWithoutHour(widget.startDate!)} - ${CodeUtils.formatDateWithoutHour(widget.endDate!)}"
                            : widget.startDate != null
                                ? CodeUtils.formatDateWithoutHour(
                                    widget.startDate!)
                                : CodeUtils.formatDateWithoutHour(
                                    widget.endDate!),
                    style: TextStyle(
                        fontSize: widget.screenSize.width * 0.012,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          ItemDetailPayment(
            isDesktop: isDesktop,
            screenSize: widget.screenSize,
            title: "Total horas",
            value: widget.selectClient &&
                    widget.clientsProvider.selectedClient == null
                ? '0'
                : "${widget.paymentsProvider.paymentRangeResult.totalHours}",

            //  isAdmin
            //     ? widget.clientsProvider.selectedClient != null &&
            //             widget.clientsProvider.selectedClient!.accountInfo
            //                     .totalRequests ==
            //                 0
            //         ? '0'
            //         : widget.paymentsProvider.paymentRangeResult.totalHours
            //             .toString()
            //     : filteredPayments.isEmpty
            //         ? '0'
            //         : ((widget.paymentsProvider.paymentRangeByClientResult
            //                 .totalHours))
            //             .toString(),
          ),
          ItemDetailPayment(
            isDesktop: isDesktop,
            screenSize: widget.screenSize,
            title: "Total a pagar",
            value: CodeUtils.formatMoney(
              widget.selectClient &&
                      widget.clientsProvider.selectedClient == null
                  ? 0
                  : widget.isClient
                      ? widget.paymentsProvider.paymentRangeResult
                          .totalClientPays
                      : widget.paymentsProvider.paymentRangeResult
                          .totalToPayEmployee,

              // isAdmin
              //     ? widget.clientsProvider.selectedClient != null &&
              //             widget.clientsProvider.selectedClient!.accountInfo
              //                     .totalRequests ==
              //                 0
              //         ? 0
              //         : widget.paymentsProvider.paymentRangeResult
              //             .totalClientPays
              //     : filteredPayments.isEmpty
              //         ? 0
              //         : (widget.paymentsProvider.paymentRangeByClientResult
              //             .totalClientPays),
            ),
          ),
        ],
      ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: UiVariables.boxDecoration,
      child: (isDesktop || widget.screenSize.blockWidth >= 580)
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children,
            ),
    );
  }
}

InkWell buildSelectClientBtn(
    ScreenSize screenSize,
    BuildContext context,
    PaymentsProvider paymentsProvider,
    ClientsProvider clientsProvider,
    DateTime? startDate,
    DateTime? endDate) {
  return InkWell(
    onTap: () async {
      ClientEntity? client =
          await ClientSelectionDialog.show(clients: clientsProvider.allClients);
      clientsProvider.selectClient(client: client!);
      if (startDate != null) {
        paymentsProvider.getClientPaymentsByRange(
            clientId: clientsProvider.selectedClient!.accountInfo.id,
            startDate: startDate,
            endDate: endDate);
      }
    },
    child: Container(
      width: screenSize.blockWidth >= 920 ? screenSize.blockWidth * 0.15 : 150,
      height: screenSize.height * 0.045,
      padding: EdgeInsets.symmetric(horizontal: screenSize.blockWidth * 0.01),
      decoration: BoxDecoration(
        color: UiVariables.primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          "Seleccionar cliente",
          style: TextStyle(
              color: Colors.white,
              fontSize: screenSize.blockWidth >= 920 ? 15 : 12),
        ),
      ),
    ),
  );
}
