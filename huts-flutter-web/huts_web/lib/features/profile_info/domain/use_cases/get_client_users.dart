import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/profile_info/domain/repositories/profile_repository.dart';

class GetClientUsers {
  final ProfileRepository profileRepository;

  GetClientUsers(this.profileRepository);
  Future<Either<Failure, List<WebUser>?>> call(
          BuildContext context, String companyId) =>
      profileRepository.getClientUsers(context, companyId);
}
