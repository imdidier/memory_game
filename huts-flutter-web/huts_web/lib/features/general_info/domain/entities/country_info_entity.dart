import 'package:cloud_firestore/cloud_firestore.dart';

class CountryInfo {
  final String areaCode;
  final String name;
  final String shortName;
  final String value;
  final bool enabled;
  final List<dynamic> banks;
  final List<String> banksNames;
  final Map<String, dynamic> jobsFares;
  Map<String, dynamic> requiredDocs;
  final List<String> socialSecurity;
  final List<String> documenType;
  final int phoneLength;
  final GeoPoint defaultLocation;
  final Map<String, dynamic> paymentsTimes;
  final String currency;
  final Map<String, dynamic> holidays;
  Map<String, dynamic> nightWorkshift;
  final Map<String, dynamic> employeesStatus;
  final List<Map<String, dynamic>> statesCities;

  CountryInfo({
    required this.areaCode,
    required this.name,
    required this.shortName,
    required this.value,
    required this.enabled,
    required this.banks,
    required this.banksNames,
    required this.jobsFares,
    required this.requiredDocs,
    required this.socialSecurity,
    required this.documenType,
    required this.phoneLength,
    required this.defaultLocation,
    required this.paymentsTimes,
    required this.currency,
    required this.holidays,
    required this.nightWorkshift,
    required this.employeesStatus,
    required this.statesCities,
  });
}
