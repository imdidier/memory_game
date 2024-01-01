import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/use_cases_params/activity_params.dart';

class ActivityService {
 static Future<void> saveChange(ActivityParams params) async =>
      await FirebaseServices.db.collection("activity").add(params.toMap());
}
