import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/features/requests/data/models/request_model.dart';

import '../../../features/requests/domain/entities/request_entity.dart';

class EmployeeAvailabilityService {
  static Future<(bool, double)?> get(
    DateTime startDate,
    DateTime endDate,
    String employeeId, [
    String currentRequestId = "",
    String type = '',
  ]) async {
    try {
      bool isAvailable = true;
      double hoursDirefence = 0.0;

      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("requests")
          .where("employee_info.id", isEqualTo: employeeId)
          .where("details.status", isGreaterThanOrEqualTo: 1)
          .where("details.status", isLessThan: 4)
          .get();
      List<Request> newRequestList = querySnapshot.docs
          .map((e) => RequestModel.fromMap(e.data() as Map<String, dynamic>))
          .toList();
      newRequestList
          .sort((a, b) => a.details.startDate.compareTo(b.details.startDate));
      for (Request request in newRequestList) {
        if (currentRequestId.isNotEmpty &&
            request.id == currentRequestId &&
            type != 'clone-requests' &&
            type != 'move-requests') {
          continue;
        }

        DateTime requestStartDate = request.details.startDate;
        DateTime requestEndDate = request.details.endDate;

        double requestStartSeconds =
            (requestStartDate.millisecondsSinceEpoch.abs()) / 1000;
        double requestEndSeconds =
            (requestEndDate.millisecondsSinceEpoch.abs()) / 1000;

        double startSeconds = (startDate.millisecondsSinceEpoch.abs()) / 1000;
        double endSeconds = (endDate.millisecondsSinceEpoch.abs()) / 1000;
        if (requestStartSeconds >= startSeconds &&
            requestEndSeconds <= endSeconds) {
          hoursDirefence =
              (getMinutesDiference(requestStartDate, endDate) / 60).toDouble();
          hoursDirefence -= 2.0;
          isAvailable = false;
          break;
        }

        if (startSeconds >= requestStartSeconds &&
            endSeconds <= requestEndSeconds) {
          hoursDirefence =
              (getMinutesDiference(requestStartDate, endDate) / 60).toDouble();
          hoursDirefence -= 2.0;
          isAvailable = false;
          break;
        }

        if ((startSeconds >= requestStartSeconds &&
                startSeconds <= requestEndSeconds) &&
            endSeconds >= requestEndSeconds) {
          hoursDirefence =
              (getMinutesDiference(requestStartDate, endDate) / 60).toDouble();
          hoursDirefence -= 2.0;
          isAvailable = false;
          break;
        }

        if ((requestStartSeconds >= startSeconds &&
                requestStartSeconds <= endSeconds) &&
            requestEndSeconds >= endSeconds) {
          hoursDirefence =
              (getMinutesDiference(requestStartDate, endDate) / 60).toDouble();
          hoursDirefence -= 2.0;
          isAvailable = false;
          break;
        }
      }
      hoursDirefence = (hoursDirefence + .1).abs();
      return (isAvailable, hoursDirefence);
    } catch (e) {
      if (kDebugMode) print("EmployeeAvailabilityService, error: $e ");
      return null;
    }
  }

  static int getMinutesDiference(DateTime startDate, DateTime endDate) {
    return startDate.difference(endDate).inMinutes;
  }
}
