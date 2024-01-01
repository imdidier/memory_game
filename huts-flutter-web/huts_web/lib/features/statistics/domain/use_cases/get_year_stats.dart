import 'package:dartz/dartz.dart';
import 'package:huts_web/core/use_cases_params/year_stats_params.dart';
import 'package:huts_web/features/statistics/domain/entities/year_stats.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/get_year_stats_repository.dart';

class GetYearStats {
  final GetYearStatsRepository getYearStatsRepository;
  GetYearStats(this.getYearStatsRepository);
  Future<Either<Failure, YearStats?>> getYearStats(
          YearStatsParams yearStatsParams,
          [String? byClient]) async =>
      getYearStatsRepository.getYearStats(yearStatsParams, byClient);
}
