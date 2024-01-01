import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huts_web/features/profile_info/domain/entities/activity.dart';

class ActivityModel extends Activity {
  ActivityModel({
    required super.description,
    required super.responsable,
    required super.userType,
    required super.date,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
        description: map['description'],
        responsable: map['responsable'],
        userType: map['userType'],
        date: (map['date'] as Timestamp).toDate());
  }
}
