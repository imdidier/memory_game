import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';

import '../../../auth/data/models/web_user_model.dart';

abstract class UsersRepository {
  Future<Either<Failure, List<WebUserModel>>> getUsers();
  Future<Either<Failure, bool>> deleteUser({
    required userId,
  });
  // Future<Either<Failure, String>> createUser({
  //   required user,
  // });
  Future<Either<Failure, bool>> updateUserInfo({
    required userId,
    required Map<String, dynamic> updateInfo,
  });
}
