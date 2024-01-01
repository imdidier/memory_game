import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/display/widgets/datatables/headers/header_table.dart';
import 'package:huts_web/features/payments/display/widgets/item_detail_payment.dart';

class HeaderPaymentMonth extends StatefulWidget {
  final ScreenSize screenSize;
  final PaymentsProvider paymentsProvider;
  const HeaderPaymentMonth(
      {Key? key, required this.screenSize, required this.paymentsProvider})
      : super(key: key);

  @override
  State<HeaderPaymentMonth> createState() => _HeaderPaymentMonthState();
}

class _HeaderPaymentMonthState extends State<HeaderPaymentMonth> {
  @override
  Widget build(BuildContext context) {
    bool isDesktop = widget.screenSize.blockWidth >= 1300;
    List<Widget> children = [
      HeaderTable(
          isDesktop: isDesktop,
          screenSize: widget.screenSize,
          title: "Pago de clientes - Mensual"),
      Column(
        crossAxisAlignment: (isDesktop || widget.screenSize.blockWidth >= 580)
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ItemDetailPayment(
            isDesktop: isDesktop,
            screenSize: widget.screenSize,
            title: "Mes a facturar",
            value: widget.paymentsProvider.paymentRangeResult.month,
          ),
          ItemDetailPayment(
            isDesktop: isDesktop,
            screenSize: widget.screenSize,
            title: "Total horas",
            value: widget.paymentsProvider.paymentRangeResult.totalHours
                .toString(),
          ),
          ItemDetailPayment(
            isDesktop: isDesktop,
            screenSize: widget.screenSize,
            title: "Total a pagar",
            value: CodeUtils.formatMoney(
                widget.paymentsProvider.paymentRangeResult.totalClientPays),
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
