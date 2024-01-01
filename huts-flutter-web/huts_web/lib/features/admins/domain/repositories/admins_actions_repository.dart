abstract class AdminsActionsRepository {
  Future<bool> enableDisable({required String id, required bool toEnable});
  Future<String> create(Map<String, dynamic> data);
  Future<String> delete(String uid);
  Future<String> edit(Map<String, dynamic> data, bool isFromAdmin);
}
