import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/profile_info/domain/repositories/profile_repository.dart';

class AddNewUser {
  final ProfileRepository repository;

  AddNewUser(this.repository);
  Future<Either<Failure, bool>?> call(BuildContext context, String idClient) {
    return repository.addNewUser(context, idClient);
  }
}
