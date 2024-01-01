import 'package:huts_web/features/settings/domain/repositories/system_roles_repository.dart';

class SystemRolesCrud {
  final SystemRolesRepository repository;
  SystemRolesCrud(this.repository);

  Future<bool> updateRoles(
          List<Map<String, dynamic>> updatedRoles, String type) async =>
      await repository.updateRoles(updatedRoles, type);

  Future<bool> createRole({
    required List<Map<String, dynamic>> enabledRoutes,
    required String rolType,
    required String rolName,
    required String clientId,
  }) async =>
      await repository.createRole(enabledRoutes, rolType, rolName, clientId);

  Future<String> deleteRole(
          {required Map<String, dynamic> toDeleteRol,
          required String rolType}) async =>
      await repository.deleteRole(toDeleteRol, rolType);
}
