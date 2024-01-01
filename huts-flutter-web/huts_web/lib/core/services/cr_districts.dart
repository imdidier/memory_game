import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CrDistricts {
  static Future<List<String>> get(String stateId, String cityId) async {
    try {
      List<String> result = [];

      Uri uri = Uri.parse(
          "https://ubicaciones.paginasweb.cr/provincia/$stateId/canton/$cityId/distritos.json");

      http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        Map<String, dynamic> decodedResp = jsonDecode(response.body);
        result = [...decodedResp.values.toList()];
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print("CrDistricts, get error: $e");
      }
      return [];
    }
  }
}
