import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/display/widgets/datatables/headers/header_table.dart';
import 'package:huts_web/features/payments/display/widgets/item_detail_payment.dart';

class HeaderPaymentGeneralRange extends StatefulWidget {
  final ScreenSize screenSize;
  final PaymentsProvider paymentsProvider;
  const HeaderPaymentGeneralRange(
      {Key? key, required this.screenSize, required this.paymentsProvider})
      : super(key: key);

  @override
  State<HeaderPaymentGeneralRange> createState() =>
      _HeaderPaymentGeneralRangeState();
}

class _HeaderPaymentGeneralRangeState extends State<HeaderPaymentGeneralRange> {
  @override
  Widget build(BuildContext context) {
    bool isDesktop = widget.screenSize.blockWidth >= 1300;
    List<Widget> children = [
      HeaderTable(
          isDesktop: isDesktop,
          screenSize: widget.screenSize,
          title: "Pagos generales"),
      Column(
        crossAxisAlignment: (isDesktop || widget.screenSize.blockWidth >= 580)
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            child: RichText(
              text: TextSpan(
                text: "Rango: ",
                style: TextStyle(
                  fontSize: widget.screenSize.width * 0.012,
                ),
                children: [
                  TextSpan(
                    text: !widget.paymentsProvider.isRangeDatesSelected()
                        ? "Sin seleccionar"
                        : "${CodeUtils.formatDateWithoutHour(widget.paymentsProvider.calendarProperties.rangeStart!)} - ${CodeUtils.formatDateWithoutHour(widget.paymentsProvider.calendarProperties.rangeEnd!)}",
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
          // ExportToExcelBtn(
          //     title: "Exportar a Excel - Pago rango",
          //     paymentsProvider: widget.paymentsProvider,
          //     totalHours:
          //         widget.paymentsProvider.paymentRangeResult.totalHoursMonth,
          //     totalHoursNormal: widget
          //         .paymentsProvider.paymentRangeResult.totalHoursMonthNormal,
          //     totalHoursHoliday: widget
          //         .paymentsProvider.paymentRangeResult.totalHoursMonthHoliday,
          //     totalHoursDynamic: widget
          //         .paymentsProvider.paymentRangeResult.totalHoursMonthDynamic,
          //     totalToPay: widget
          //         .paymentsProvider.paymentRangeResult.totalClientPaysMonth,
          //     payments: widget
          //         .paymentsProvider.paymentRangeResult.weekIndividualPayments,
          //     fileName: "pagos_rango")
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
