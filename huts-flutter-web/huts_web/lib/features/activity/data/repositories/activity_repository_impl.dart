import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/features/activity/data/datasources/activity_remote_datasource.dart';
import 'package:huts_web/features/activity/domain/entities/activity_report.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:huts_web/features/activity/domain/repositories/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRemoteDatasource datasource;

  ActivityRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, List<ActivityReport>>> getByEmployee(
      {required String id, required String categoryKey}) async {
    try {
      return Right(await datasource.getByEmployee(id, categoryKey));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  Future<Either<Failure, List<ActivityReport>>> getByClient(
      {required String id,
      required DateTime startDate,
      required DateTime endDate}) async {
    try {
      return Right(await datasource.getByClient(id, startDate, endDate));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  Future<Either<Failure, List<ActivityReport>>> getGeneral(
      {required DateTime startDate, required DateTime endDate}) async {
   try {
      return Right(await datasource.getGeneral(startDate, endDate));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }
}
