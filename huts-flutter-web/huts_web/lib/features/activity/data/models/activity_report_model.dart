import 'package:huts_web/features/activity/domain/entities/activity_report.dart';

class ActivityReportModel extends ActivityReport {
  ActivityReportModel({
    required super.description,
    required super.category,
    required super.personInCharge,
    required super.affectedUser,
    required super.date,
  });

  factory ActivityReportModel.fromMap(Map<String, dynamic> map) {
    return ActivityReportModel(
      category: map["category"],
      description: map["description"],
      personInCharge: map["person_in_charge"],
      affectedUser: map["affected_user"],
      date: map["date"].toDate(),
    );
  }
}
