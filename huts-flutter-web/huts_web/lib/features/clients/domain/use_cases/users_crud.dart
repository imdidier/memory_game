import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/data/models/web_user_model.dart';
import '../repositories/users_repository.dart';

class UsersCrud {
  UsersRepository repository;
  UsersCrud(this.repository);

  Future<Either<Failure, List<WebUserModel>>> getUsers() async =>
      await repository.getUsers();
  Future<Either<Failure, bool>> deleteUser(String userId) async =>
      await repository.deleteUser(userId: userId);
  // Future<Either<Failure, String>> createUser(Map<String, dynamic> user) async =>
  //     await repository.createUser(user: user);
  Future<Either<Failure, bool>> updateUserInfo(
          String userId, Map<String, dynamic> updateInfo) async =>
      await repository.updateUserInfo(
        userId: userId,
        updateInfo: updateInfo,
      );
}
