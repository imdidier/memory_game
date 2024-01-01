import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/auth/domain/repositories/auth_repository.dart';

class EmailSignIn {

  AuthRepository repository;
  EmailSignIn(this.repository);

  Future<Either<Failure,UserCredential?>> call(String email, String password) async{
    return await repository.emailSignIn(email,password);
  }
  
}