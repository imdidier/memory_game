import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/features/activity/data/models/activity_report_model.dart';

import '../../domain/entities/activity_report.dart';

abstract class ActivityRemoteDatasource {
  Future<List<ActivityReport>> getByEmployee(String id, String category);
  Future<List<ActivityReport>> getByClient(
    String id,
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<ActivityReport>> getGeneral(DateTime startDate, DateTime endDate);
}

class ActivityRemoteDatasourceImpl implements ActivityRemoteDatasource {
  @override
  Future<List<ActivityReport>> getByEmployee(String id, String category) async {
    try {
      Query query = (category != "all")
          ? FirebaseServices.db
              .collection("activity")
              .where("affected_user.id", isEqualTo: id)
              .where("affected_user.type_key", isEqualTo: "employee")
              .where("category.key", isEqualTo: category)
          : FirebaseServices.db
              .collection("activity")
              .where("affected_user.id", isEqualTo: id)
              .where("affected_user.type_key", isEqualTo: "employee");

      QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs
          .map(
            (doc) =>
                ActivityReportModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<List<ActivityReport>> getByClient(
      String id, DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("activity")
          .where("person_in_charge.company_id", isEqualTo: id)
          .where("date", isGreaterThanOrEqualTo: startDate)
          .where("date", isLessThanOrEqualTo: endDate)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              ActivityReportModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<List<ActivityReport>> getGeneral(
      DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("activity")
          .where("date", isGreaterThanOrEqualTo: startDate)
          .where("date", isLessThanOrEqualTo: endDate)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                ActivityReportModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
          
    } catch (e) {
      throw ServerException("$e");
    }
  }
}
