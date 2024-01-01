import 'package:flutter/foundation.dart';
import 'package:huts_web/features/pre_registered/data/datasources/pre_registered_remote_datasource.dart';
import 'package:huts_web/features/pre_registered/domain/repositories/pre_registered_repository.dart';

class PreRegisteredRepositoryImpl implements PreRegisteredRepository {
  PreRegisteredRemoteDatasource datasource;
  PreRegisteredRepositoryImpl(this.datasource);

  // @override
  // Future<Either<Failure, List<Employee>>> listenPreRegistered(
  //     DateTime startDate, DateTime endDate) async {
  //   try {
  //     return Right(await datasource.listenPreRegistered(startDate, endDate));
  //   } on ServerException catch (e) {
  //     return Left(ServerFailure(errorMessage: e.message));
  //   }
  // }

  @override
  void getPreRegistered(DateTime startDate, DateTime endDate) async {
    try {
      datasource.listenPreRegistered(startDate, endDate);
    } catch (e) {
      if (kDebugMode) {
        print("PreRegisterRepositoryImpl, getPreregistered error: $e");
      }
    }
  }

  @override
  Future<bool> approveEmployee(String employeeID, String employeeName) async {
    try {
      return datasource.approveEmployee(employeeID, employeeName);
    } catch (e) {
      if (kDebugMode) {
        print("PreRegisteredRepositoryImpl, approveEmployee error: $e ");
      }
      return false;
    }
  }
}
