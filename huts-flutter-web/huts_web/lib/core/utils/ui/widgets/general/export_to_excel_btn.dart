import 'package:flutter/material.dart';
import 'package:huts_web/core/services/export_data.dart';
import 'package:huts_web/core/use_cases_params/excel_params.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';

import '../../ui_variables.dart';

class ExportToExcelBtn extends StatelessWidget {
  final String? title;
  final ExcelParams params;
  final bool? isPrintingEmployees;
  const ExportToExcelBtn(
      {Key? key,
      required this.params,
      this.title,
      this.isPrintingEmployees = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return !isPrintingEmployees!
        ? ElevatedButton(
            onPressed: () async {
              UiMethods().showLoadingDialog(context: context);
              ExportData.toExcel(params).then((value) {
                UiMethods().hideLoadingDialog(context: context);
              });
            },
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              backgroundColor: UiVariables.primaryColor,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            child: Text(title ?? "Exportar datos a excel"),
          )
        : InkWell(
            onTap: () async {
              UiMethods().showLoadingDialog(context: context);
              ExportData.toExcel(params).then((value) {
                UiMethods().hideLoadingDialog(context: context);
              });
            },
            child: Container(
              width: 150,
              height: 35,
              decoration: BoxDecoration(
                color: UiVariables.primaryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
  }
}
