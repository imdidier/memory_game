import 'package:huts_web/features/auth/domain/entities/company.dart';

class WebUser {
  AccountInfo accountInfo;
  ProfileInfo profileInfo;
  String uid;
  Company company;
  bool isClicked = false;
  Map<String, dynamic> clientAssociationInfo;

  WebUser(
    this.accountInfo,
    this.profileInfo,
    this.uid,
    this.company,
    this.clientAssociationInfo,
  );
  toMap() {
    return <String, Object>{
      "account_info": accountInfo.toMap(),
      "profile_info": profileInfo.toMap(),
    };
  }
}

class AccountInfo {
  String companyId;
  DateTime creationDate;
  bool enabled;
  String subtype;
  String type;

  AccountInfo({
    required this.companyId,
    required this.creationDate,
    required this.enabled,
    required this.subtype,
    required this.type,
  });
  toMap() {
    return <String, Object>{
      "company_id": companyId,
      "creation_date": creationDate,
      'enabled': enabled,
      'subtype': subtype,
      'type': type,
    };
  }
}

class ProfileInfo {
  String countryPrefix;
  String email;
  String image;
  String lastNames;
  String names;
  String phone;

  ProfileInfo({
    required this.countryPrefix,
    required this.email,
    required this.image,
    required this.lastNames,
    required this.names,
    required this.phone,
  });
  toMap() {
    return <String, Object>{
      "country_prefix": countryPrefix,
      "email": email,
      'image': image,
      'last_names': lastNames,
      'names': names,
      'phone': phone
    };
  }
}
