import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/activity/domain/entities/activity_report.dart';

abstract class ActivityRepository {
  Future<Either<Failure, List<ActivityReport>>> getByEmployee({
    required String id,
    required String categoryKey,
  });
  Future<Either<Failure, List<ActivityReport>>> getByClient({
    required String id,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, List<ActivityReport>>> getGeneral({
    required DateTime startDate,
    required DateTime endDate,
  });
}
