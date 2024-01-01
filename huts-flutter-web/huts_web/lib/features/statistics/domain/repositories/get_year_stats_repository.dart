import 'package:dartz/dartz.dart';
import 'package:huts_web/features/statistics/domain/entities/year_stats.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/use_cases_params/year_stats_params.dart';

abstract class GetYearStatsRepository {
  Future<Either<Failure, YearStats?>> getYearStats(
      YearStatsParams yearStatsParams,
      [String? byClient]);
}
