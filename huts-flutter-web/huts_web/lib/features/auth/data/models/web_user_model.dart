import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huts_web/features/auth/data/models/company_model.dart';
import '../../domain/entities/web_user_entity.dart';

class WebUserModel extends WebUser {
  WebUserModel(
    super.accountInfo,
    super.profileInfo,
    super.uid,
    super.company,
    super.clientAssociationInfo,
  );

  factory WebUserModel.fromMap(Map<String, dynamic> map) {
    return WebUserModel(
      AccountInfoModel.fromMap(map),
      ProfileInfoModel.fromMap(map),
      map['id'] ?? map["uid"],
      CompanyModel.fromMap(
          map.containsKey("company_info") ? map['company_info'] : {}),
      map["client_association_info"] ?? {},
    );
  }
}

class ProfileInfoModel extends ProfileInfo {
  ProfileInfoModel({
    required super.countryPrefix,
    required super.email,
    required super.image,
    required super.lastNames,
    required super.names,
    required super.phone,
  });

  factory ProfileInfoModel.fromMap(Map<String, dynamic> map) {
    return ProfileInfoModel(
      countryPrefix: map['profile_info']['country_prefix'],
      email: map['profile_info']['email'],
      image: map['profile_info']['image'],
      lastNames: map['profile_info']['last_names'],
      names: map['profile_info']['names'],
      phone: map['profile_info']['phone'],
    );
  }
}

class AccountInfoModel extends AccountInfo {
  AccountInfoModel({
    required super.companyId,
    required super.creationDate,
    required super.enabled,
    required super.subtype,
    required super.type,
  });

  factory AccountInfoModel.fromMap(Map<String, dynamic> map) {
    return AccountInfoModel(
      companyId: map['account_info']['company_id'],
      creationDate:
          (map['account_info']['creation_date'] as Timestamp).toDate(),
      enabled: map['account_info']['enabled'],
      subtype: map['account_info']['subtype'],
      type: map['account_info']['type'],
    );
  }
}
