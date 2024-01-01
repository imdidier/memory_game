import 'package:huts_web/features/general_info/domain/entities/other_info_entity.dart';

class OtherInfoModel extends OtherInfo {
  OtherInfoModel({
    required super.webRoutes,
    required super.webUserTypes,
    required super.webUserSubtypes,
    required super.employeesActivityCategories,
    required super.systemRoles,
  });

  factory OtherInfoModel.fromMap(Map<String, dynamic> map) {
    return OtherInfoModel(
      webRoutes: map["web_routes"],
      webUserTypes: Map<String, dynamic>.from(map["web_user_types"]),
      webUserSubtypes: Map<String, dynamic>.from(map['web_user_subtypes']),
      employeesActivityCategories:
          Map<String, dynamic>.from(map['employees_activity_categories']),
      systemRoles: Map<String, dynamic>.from(map['system_roles']),
    );
  }
}
