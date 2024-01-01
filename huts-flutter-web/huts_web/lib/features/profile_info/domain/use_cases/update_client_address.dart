import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/profile_info/domain/repositories/profile_repository.dart';

class UpdateClientAddress {
  final ProfileRepository repository;

  UpdateClientAddress(this.repository);

  Future<Either<Failure, bool>?> call(
      Map<String, dynamic> addressToUpdate, String clientId) async {
    return repository.editClietAddress(addressToUpdate, clientId);
  }
}
