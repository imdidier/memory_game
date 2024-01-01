import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, WebUser?>> getUserInfo();
  Future<Either<Failure, UserCredential?>> emailSignIn(
      String email, String password);
  Future<Either<Failure, bool?>> recoverPassword(String email);
}
