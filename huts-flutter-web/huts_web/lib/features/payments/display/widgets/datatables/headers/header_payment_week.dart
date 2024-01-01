import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/display/widgets/datatables/headers/header_table.dart';
import 'package:huts_web/features/payments/display/widgets/item_detail_payment.dart';

import '../../../../../../core/utils/code/code_utils.dart';

class HeaderPaymentWeek extends StatefulWidget {
  final ScreenSize screenSize;
  final PaymentsProvider paymentsProvider;
  const HeaderPaymentWeek(
      {Key? key, required this.screenSize, required this.paymentsProvider})
      : super(key: key);

  @override
  State<HeaderPaymentWeek> createState() => _HeaderPaymentWeekState();
}

class _HeaderPaymentWeekState extends State<HeaderPaymentWeek> {
  @override
  Widget build(BuildContext context) {
    bool isDesktop = widget.screenSize.blockWidth >= 1300;
    List<Widget> children = [
      HeaderTable(
          isDesktop: isDesktop,
          screenSize: widget.screenSize,
          title: "Pago de clientes - semanal"),
      Column(
        crossAxisAlignment: (isDesktop || widget.screenSize.blockWidth >= 580)
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ItemDetailPayment(
            isDesktop: isDesktop,
            screenSize: widget.screenSize,
            title: "Semana a facturar",
            value: widget.paymentsProvider.paymentRangeResult.week,
          ),
          ItemDetailPayment(
            isDesktop: isDesktop,
            screenSize: widget.screenSize,
            title: "Total horas",
            value: widget.paymentsProvider.paymentRangeResult.totalHours.toString(),
          ),
          ItemDetailPayment(
            isDesktop: isDesktop,
            screenSize: widget.screenSize,
            title: "Total a pagar",
            value: CodeUtils.formatMoney(
                widget.paymentsProvider.paymentRangeResult.totalClientPays),
          ),
          // ExportToExcelBtn(
          //     title: "Exportar a Excel - Pago semanal",
          //     paymentsProvider: widget.paymentsProvider,
          //     totalHours: widget.paymentsProvider.paymentsResult.totalHours,
          //     totalHoursNormal:
          //         widget.paymentsProvider.paymentsResult.totalHoursNormal,
          //     totalHoursHoliday:
          //         widget.paymentsProvider.paymentsResult.totalHoursHoliday,
          //     totalHoursDynamic:
          //         widget.paymentsProvider.paymentsResult.totalHoursDynamic,
          //     totalToPay:
          //         widget.paymentsProvider.paymentsResult.totalClientPays,
          //     payments:
          //         widget.paymentsProvider.paymentsResult.weekIndividualPayments,
          //     fileName: "pagos_semanal")
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
