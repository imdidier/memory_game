import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

import '../../../auth/data/models/web_user_model.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_datasource.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDatasource datasource;
  UsersRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, List<WebUserModel>>> getUsers() async {
    try {
      return Right(await datasource.getUsers());
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUser({
    required userId,
  }) async {
    try {
      return Right(await datasource.deleteUser(userId: userId));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  // @override
  // Future<Either<Failure, String>> createUser({
  //   required Map<String, dynamic> user,
  // }) async {
  //   try {
  //     return Right(await datasource.createUser(user: user));
  //   } on ServerException catch (e) {
  //     return Left(ServerFailure(errorMessage: e.message));
  //   }
  // }

  @override
  Future<Either<Failure, bool>> updateUserInfo(
      {required userId, required Map<String, dynamic> updateInfo}) async {
    try {
      return Right(await datasource.updateUserInfo(
          userId: userId, updateInfo: updateInfo));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }
}
