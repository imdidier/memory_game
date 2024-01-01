

import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';

import '../repositories/auth_repository.dart';

class RecoverPassword {
 final AuthRepository repository;
 RecoverPassword(this.repository);

 Future<Either<Failure,bool?>> call(String email) async{
   return await repository.recoverPassword(email);
 }
  
}