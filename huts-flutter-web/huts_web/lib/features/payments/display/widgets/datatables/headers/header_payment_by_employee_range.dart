import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/display/widgets/datatables/headers/header_table.dart';
import 'package:huts_web/features/payments/display/widgets/item_detail_payment.dart';

import '../../../../../clients/display/provider/clients_provider.dart';

class HeaderPaymentByEmployeeRange extends StatefulWidget {
  final ScreenSize screenSize;
  final PaymentsProvider paymentsProvider;
  final DateTime? startDate;
  final DateTime? endDate;
  final ClientsProvider clientsProvider;

  final bool selectClient;
  const HeaderPaymentByEmployeeRange(
      {Key? key,
      required this.screenSize,
      required this.paymentsProvider,
      required this.startDate,
      required this.endDate,
      required this.clientsProvider,
      this.selectClient = false})
      : super(key: key);

  @override
  State<HeaderPaymentByEmployeeRange> createState() =>
      _HeaderPaymentByEmployeeRangeState();
}

class _HeaderPaymentByEmployeeRangeState
    extends State<HeaderPaymentByEmployeeRange> {
  @override
  Widget build(BuildContext context) {
    bool isDesktop = widget.screenSize.blockWidth >= 1300;
    List<Widget> children = [
      HeaderTable(
        isDesktop: isDesktop,
        screenSize: widget.screenSize,
        title: "Pagos Colaboradores",
      ),
      Column(
        crossAxisAlignment: (isDesktop || widget.screenSize.blockWidth >= 580)
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
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
                : widget.clientsProvider.selectedClient != null &&
                        widget.clientsProvider.selectedClient!.accountInfo
                                .totalRequests ==
                            0
                    ? '0'
                    : widget.paymentsProvider.paymentRangeResult.totalHours
                        .toString(),
          ),
          ItemDetailPayment(
            isDesktop: isDesktop,
            screenSize: widget.screenSize,
            title: "Total a pagar",
            value: CodeUtils.formatMoney(widget.selectClient &&
                    widget.clientsProvider.selectedClient == null
                ? 0
                : widget.clientsProvider.selectedClient != null &&
                        widget.clientsProvider.selectedClient!.accountInfo
                                .totalRequests ==
                            0
                    ? 0
                    : widget.paymentsProvider.paymentRangeResult
                        .totalToPayEmployee),
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
              children: children),
    );
  }
}
