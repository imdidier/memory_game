import 'package:flutter/foundation.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:huts_web/features/employees/domain/repositories/employees_repository.dart';

import '../../display/provider/employees_provider.dart';

class EmployeesRepositoryImpl implements EmployeesRepository {
  EmoployeesRemoteDataSourse dataSourse;

  EmployeesRepositoryImpl(this.dataSourse);

  @override
  void getEmployees(EmployeesProvider provider) async {
    try {
      dataSourse.listenEmployees(provider);
    } catch (e) {
      if (kDebugMode) print("EmployeesRepositoryImpl, getEmployees error: $e");
    }
    // try {
    //   return Right(await dataSourse.getEmployees());
    // } on ServerException catch (e) {
    //   return Left(ServerFailure(errorMessage: e.message));
    // }
  }

  @override
  Future<bool> updateEmployees(
      String idEmployee, Map<String, dynamic> data) async {
    try {
      return await dataSourse.updateEmployees(idEmployee, data);
    } catch (e) {
      if (kDebugMode) {
        print("EmployeesRepositoryImpl, updateEmployees error: $e");
      }
      return false;
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getEmployeesPayments(
      DateTime startDate, DateTime endDate, String type) async {
    try {
      return Right(
          await dataSourse.getEmployeesPayments(startDate, endDate, type));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  void getDetailsEmployee(String idEmployee, EmployeesProvider provider) {
    try {
      dataSourse.listenDetailsEmployee(idEmployee, provider);
    } catch (e) {
      if (kDebugMode) {
        print("EmployeesRepositoryImpl, getDetailsEmployees error: $e");
      }
    }
  }
}
