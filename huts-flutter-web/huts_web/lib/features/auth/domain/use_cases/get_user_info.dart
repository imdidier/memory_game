import 'package:dartz/dartz.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/auth/domain/repositories/auth_repository.dart';

import '../../../../core/errors/failures.dart';

class GetUserInfo {
  AuthRepository authRepository;
  GetUserInfo(this.authRepository);

  Future<Either<Failure, WebUser?>> call() async =>
      authRepository.getUserInfo();
}
