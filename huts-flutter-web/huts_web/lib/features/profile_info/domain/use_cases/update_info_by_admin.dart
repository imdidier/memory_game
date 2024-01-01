import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/profile_info/domain/repositories/profile_repository.dart';

class UpdateInfoByAdmin {
  final ProfileRepository profileRepository;

  UpdateInfoByAdmin(this.profileRepository);

  Future<Either<Failure, bool>?> call(
      String idToUpdate,
      Map<String, dynamic> adminInfoToUpdate,
      Map<String, dynamic> updatedSubtype) {
    return profileRepository.updateInfo(
        idToUpdate, adminInfoToUpdate, updatedSubtype);
  }
}
