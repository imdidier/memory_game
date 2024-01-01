import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

class NightSurchargeServices {
  static Future<bool> update(
      {required String? clientID,
      required Map<String, dynamic> newData}) async {
    try {
      if (clientID != null) {
        FirebaseServices.db
            .collection("clients")
            .doc(clientID)
            .update({"night_workshift": newData});

        return true;
      }

      BuildContext? context = NavigationService.getGlobalContext();
      if (context == null) return false;

      FirebaseServices.db
          .collection("countries_info")
          .doc("costa_rica")
          .update({"night_workshift": newData});

      context
          .read<GeneralInfoProvider>()
          .generalInfo
          .countryInfo
          .nightWorkshift = newData;

      return true;
    } catch (e) {
      if (kDebugMode) print("NightSurchargeServices, update error: $e ");
      return false;
    }
  }
}
