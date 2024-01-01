import '../../domain/entities/employee_entity.dart';
import 'package:flutter/material.dart';

class EmployeeModel extends Employee {
  EmployeeModel({
    required super.id,
    required super.accountInfo,
    required super.availability,
    required super.bankInfo,
    required super.documents,
    required super.jobs,
    required super.profileInfo,
    required super.docsStatus,
  });

  factory EmployeeModel.fromMap(Map<String, dynamic> generalMap) {
    Map<String, dynamic> accountMap = generalMap["account_info"];
    Map<String, dynamic> profileMap = generalMap["profile_info"];
    return EmployeeModel(
      id: generalMap["uid"],
      accountInfo: EmployeeAccountInfo(
        notificationIds: List<String>.from(accountMap["notification_ids"]),
        registerDate: accountMap["register_date"].toDate(),
        status: accountMap["status"],
        totalAcceptedRequests: accountMap["total_accepted"],
        totalRequests: accountMap["total_requests"],
        unlockDate: accountMap["unlock_date"].toDate(),
        lastEntry: accountMap.containsKey('last_entry')
            ? accountMap['last_entry'].toDate()
            : accountMap['last_entry'] = null,
      ),
      availability: generalMap["availability"],
      bankInfo: generalMap["bank_info"],
      documents: generalMap["documents"],
      jobs: List<String>.from(generalMap["jobs"]),
      profileInfo: EmployeeProfileInfo(
        birthday: profileMap["birthday"].toDate(),
        docNumber: profileMap["doc_number"],
        docType: profileMap["doc_type"],
        gender: profileMap["gender"],
        image: profileMap["image"],
        names: profileMap["names"],
        lastNames: profileMap["last_names"],
        location: profileMap["location"],
        phone: profileMap["phone"],
        socialSecurityType: profileMap["social_security_type"],
        rate: profileMap["rate"] ?? {},
      ),
      docsStatus: EmployeeDocsStatus(
        text: "Error",
        value: -1,
        widget: const Chip(
          backgroundColor: Colors.orange,
          label: Text(
            "Error",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
