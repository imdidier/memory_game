import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';

import '../../../../core/use_cases_params/export_payments_excel_params.dart';

class ExportToExcelBtn extends StatefulWidget {
  final String title;
  final ExportPaymentsToExcelParams excelParams;
  final PaymentsProvider paymentsProvider;
  final bool isSelectedClient;
  const ExportToExcelBtn({
    Key? key,
    required this.paymentsProvider,
    required this.excelParams,
    required this.title,
    this.isSelectedClient = false,
  }) : super(key: key);

  @override
  State<ExportToExcelBtn> createState() => _ExportToExcelBtnState();
}

class _ExportToExcelBtnState extends State<ExportToExcelBtn> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: widget.excelParams.payments.isNotEmpty
          ? ElevatedButton(
              style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  backgroundColor: UiVariables.primaryColor,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: () {
                widget.paymentsProvider.exportPaymentsToExcel(
                    params: widget.excelParams,
                    isSelectedClient: widget.isSelectedClient);
              },
              child: !widget.paymentsProvider.isLoading
                  ? Text(widget.title)
                  : const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
            )
          : const SizedBox(),
    );
  }
}
