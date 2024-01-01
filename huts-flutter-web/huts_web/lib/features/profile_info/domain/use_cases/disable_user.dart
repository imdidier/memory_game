import 'package:huts_web/features/profile_info/domain/repositories/profile_repository.dart';

class DisableUser {
  final ProfileRepository repository;

  DisableUser(this.repository);

  Future<void> call(String userId, bool isEnabled) async {
    return repository.disableUser(userId, isEnabled);
  }
}
