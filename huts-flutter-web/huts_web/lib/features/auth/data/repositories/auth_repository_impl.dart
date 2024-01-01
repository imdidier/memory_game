import 'package:firebase_auth/firebase_auth.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:huts_web/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, WebUser?>> getUserInfo() async {
    try {
      return Right(await dataSource.getUserInfo());
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  Future<Either<Failure, UserCredential?>> emailSignIn(
      String email, String password) async {
    try {
      return Right(await dataSource.emailSignIn(email, password));
    } on ServerException catch (e) {
      return Left(
        ServerFailure(errorMessage: e.message),
      );
    }
  }

  @override
  Future<Either<Failure, bool?>> recoverPassword(String email) async {
    try {
      return Right(await dataSource.recoverPassword(email));
    } on ServerException catch (e) {
      return Left(
        ServerFailure(errorMessage: e.message),
      );
    }
  }
}
