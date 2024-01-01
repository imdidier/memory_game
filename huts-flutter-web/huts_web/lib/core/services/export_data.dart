import 'dart:convert';
import 'package:universal_html/html.dart';

import 'package:huts_web/core/use_cases_params/excel_params.dart';
import 'package:huts_web/core/config.dart' as config;
import 'package:http/http.dart' as http;

class ExportData {
  static Future<bool> toExcel(ExcelParams params) async {
    Uri uri =
        Uri.parse('${config.urlFunctions}/${config.endpointExportToExcel}');
    http.Response response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        {
          "headers": params.headers,
          "headers_for_client": [],
          "data": params.data,
          "other_info": params.otherInfo,
          "file_name": "",
          "for_client": false,
          "data_event": [],
        },
      ),
    );

    if (response.statusCode == 500) return false;
    if (response.statusCode == 200) {
      dynamic decodedResp = jsonDecode(response.body);

      List<int> bytes = List<int>.from(decodedResp['report']['data']);
      final String base64 = base64Encode(bytes);
      final AnchorElement anchorElement =
          AnchorElement(href: 'data:application/octet-stream;base64,$base64')
            ..target = "blank";

      anchorElement.download = "${params.fileName}.xlsx";
      document.body!.append(anchorElement);
      anchorElement.click();
      anchorElement.remove();

      return true;
    }

    return false;
  }
}
