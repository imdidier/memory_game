import 'package:huts_web/features/profile_info/domain/repositories/profile_repository.dart';

class EditUserInfo {
  final ProfileRepository repository;

  EditUserInfo(this.repository);

  Future<void> call(Map<String, dynamic> infoToUpdate) async {
    repository.editUserInfo(infoToUpdate);
  }
}
