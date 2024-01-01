import 'package:flutter/foundation.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:huts_web/features/fares/data/datasources/fares_remote_datasource.dart';
import 'package:huts_web/features/fares/domain/repositories/job_fares_repository.dart';

class JobFaresCrudRepositoryImpl implements JobFaresRepository {
  FaresRemoteDatasource datasource;
  JobFaresCrudRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, bool>> updateJobFares(
      Map<String, dynamic> newData) async {
    try {
      return Right(await datasource.updateJobFares(newData));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  Future<String> deleteJobFare(Map<String, dynamic> data) async {
    try {
      return await datasource.deleteJobFare(data);
    } catch (e) {
      if (kDebugMode) {
        print("JobFaresCrudRepositoryImpl, deleteJobFare error: $e");
      }
      return "error";
    }
  }

  @override
  Future<String> createJob(Map<String, dynamic> data) async {
    try {
      return await datasource.createJob(data);
    } catch (e) {
      if (kDebugMode) {
        print("JobFaresCrudRepositoryImpl, createJob error: $e");
      }
      return "error";
    }
  }

  @override
  Future<String> createDoc(Map<String, dynamic> data) async {
    try {
      return await datasource.createDoc(data);
    } catch (e) {
      if (kDebugMode) {
        print("JobFaresCrudRepositoryImpl, createDoc error: $e");
      }
      return "error";
    }
  }
}
