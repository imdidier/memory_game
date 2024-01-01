import 'package:huts_web/features/admins/domain/repositories/admins_actions_repository.dart';

class AdminActions {
  final AdminsActionsRepository actionsRepository;
  AdminActions(this.actionsRepository);

  Future<bool> enableDisable(
          {required String id, required bool toEnable}) async =>
      await actionsRepository.enableDisable(id: id, toEnable: toEnable);

  Future<String> create(Map<String, dynamic> data) async =>
      await actionsRepository.create(data);

  Future<String> delete(String uid) async =>
      await actionsRepository.delete(uid);

  Future<String> edit(Map<String, dynamic> data,
          [bool isFromAdmin = false]) async =>
      await actionsRepository.edit(data, isFromAdmin);
}
