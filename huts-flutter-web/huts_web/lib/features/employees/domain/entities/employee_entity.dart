import 'package:flutter/material.dart';

class Employee {
  String id;
  EmployeeAccountInfo accountInfo;
  Map<String, dynamic> availability;
  Map<String, dynamic> bankInfo;
  Map<String, dynamic> documents;
  List<String> jobs;
  EmployeeProfileInfo profileInfo;
  EmployeeDocsStatus docsStatus;

  Employee({
    required this.id,
    required this.accountInfo,
    required this.availability,
    required this.bankInfo,
    required this.documents,
    required this.jobs,
    required this.profileInfo,
    required this.docsStatus,
  });
}

class EmployeeAccountInfo {
  List<String> notificationIds;
  int status;
  DateTime registerDate;
  int totalAcceptedRequests;
  int totalRequests;
  DateTime unlockDate;
  DateTime? lastEntry;

  EmployeeAccountInfo({
    required this.notificationIds,
    required this.status,
    required this.registerDate,
    required this.totalAcceptedRequests,
    required this.totalRequests,
    required this.unlockDate,
    this.lastEntry,
  });
}

class EmployeeProfileInfo {
  DateTime birthday;
  String docNumber;
  String docType;
  String gender;
  String image;
  String names;
  String lastNames;
  String phone;
  Map<String, dynamic> location;
  Map<String, dynamic> rate;
  String? socialSecurityType;

  EmployeeProfileInfo({
    required this.birthday,
    required this.docNumber,
    required this.docType,
    required this.gender,
    required this.image,
    required this.names,
    required this.lastNames,
    required this.phone,
    required this.location,
    required this.rate,
    required this.socialSecurityType,
  });
}

class EmployeeDocsStatus {
  int value;
  String text;
  Widget widget;

  EmployeeDocsStatus({
    required this.value,
    required this.text,
    required this.widget,
  });
}
