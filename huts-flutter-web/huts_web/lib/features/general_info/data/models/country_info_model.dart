import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/country_info_entity.dart';

class CountryInfoModel extends CountryInfo {
  CountryInfoModel({
    required super.areaCode,
    required super.name,
    required super.shortName,
    required super.value,
    required super.enabled,
    required super.banks,
    required super.banksNames,
    required super.jobsFares,
    required super.requiredDocs,
    required super.socialSecurity,
    required super.documenType,
    required super.phoneLength,
    required super.defaultLocation,
    required super.paymentsTimes,
    required super.currency,
    required super.holidays,
    required super.nightWorkshift,
    required super.employeesStatus,
    required super.statesCities,
  });

  factory CountryInfoModel.fromMap(Map<String, dynamic> map) {
    List<String> socialSecurityList = [];

    map['social_security']?.forEach((type) {
      socialSecurityList.add(type.toString());
    });

    List<String> banksNamesList = [];

    map['banks']?.forEach((bank) {
      banksNamesList.add(bank['name'].toString());
    });

    List<String> documentTypesList = [];
    map['document_types']?.forEach((type) {
      documentTypesList.add(type.toString());
    });
    return CountryInfoModel(
      areaCode: map["area_code"] ?? '',
      name: map["name"] ?? '',
      enabled: map["enabled"] ?? false,
      shortName: map["short_name"] ?? '',
      banks: map["banks"] ?? [],
      banksNames: banksNamesList,
      requiredDocs: map['required_docs'] ?? {},
      value: map["value"] ?? '',
      jobsFares: map["jobs_fares"] ?? {},
      socialSecurity: socialSecurityList,
      documenType: documentTypesList,
      phoneLength: map['phone_length'] ?? 0,
      defaultLocation: map['default_location'] ?? const GeoPoint(0, 0),
      paymentsTimes: map['payments_times'] ?? {},
      currency: map['currency'] ?? '',
      holidays: map['holidays'] ?? {},
      nightWorkshift: map['night_workshift'] ?? {},
      employeesStatus: map['employees_status'] ?? {},
      statesCities: [],
    );
  }
}
