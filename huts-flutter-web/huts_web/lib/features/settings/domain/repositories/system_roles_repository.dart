abstract class SystemRolesRepository {
  Future<bool> updateRoles(
    List<Map<String, dynamic>> updatedRoles,
    String type,
  );
  Future<bool> createRole(
      List<Map<String, dynamic>> enabledRoutes, String rolType, String rolName, String clientId);
  Future<String> deleteRole(Map<String, dynamic> toDeleteRol, String rolType);
}
