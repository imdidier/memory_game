import 'package:flutter/foundation.dart';
import 'package:huts_web/features/settings/data/datatsources/settings_remote_datasourse.dart';
import 'package:huts_web/features/settings/domain/repositories/system_roles_repository.dart';

class SystemRolesRepositoryImpl implements SystemRolesRepository {
  final SettingsRemoteDatasourse remoteDatasourse;

  SystemRolesRepositoryImpl(this.remoteDatasourse);

  @override
  Future<bool> createRole(List<Map<String, dynamic>> enabledRoutes,
      String rolType, String rolName, String clientId) async {
    try {
      return await remoteDatasourse.createRole(enabledRoutes, rolType, rolName, clientId);
    } catch (e) {
      if (kDebugMode) {
        print("SystemRolesRepositoryImpl, createRole error: $e");
      }
      return false;
    }
  }

  @override
  Future<bool> updateRoles(
      List<Map<String, dynamic>> updatedRoles, String type) async {
    try {
      return await remoteDatasourse.updateRoles(updatedRoles, type);
    } catch (e) {
      if (kDebugMode) {
        print("SystemRolesRepositoryImpl, updateClientRoles error: $e");
      }
      return false;
    }
  }

  @override
  Future<String> deleteRole(
      Map<String, dynamic> toDeleteRol, String rolType) async {
    try {
      return await remoteDatasourse.deleteRol(toDeleteRol, rolType);
    } catch (e) {
      if (kDebugMode) {
        print("SystemRolesRepositoryImpl, deleteRole error: $e");
      }
      return "fail";
    }
  }
}
