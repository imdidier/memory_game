import 'package:dartz/dartz.dart';
import 'package:huts_web/features/statistics/domain/entities/year_stats.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/use_cases_params/year_stats_params.dart';
import '../../domain/repositories/get_year_stats_repository.dart';
import '../datasources/get_year_stats_remote_datasource.dart';

class GetYearStatsRepositoryImpl implements GetYearStatsRepository {
  final GetYearStatsRemoteDataSource remoteDataSource;

  GetYearStatsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, YearStats?>> getYearStats(
      YearStatsParams yearStatsParams,
      [String? byClient]) async {
    try {
      return Right(
          await remoteDataSource.getYearStats(yearStatsParams, byClient));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }
}
