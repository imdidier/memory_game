import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/activity/domain/entities/activity_report.dart';

import '../repositories/activity_repository.dart';

class ActivityCrud {
  ActivityRepository repository;
  ActivityCrud({required this.repository});

  Future<Either<Failure, List<ActivityReport>>> getByEmployee({
    required String id,
    required String category,
  }) async {
    return await repository.getByEmployee(id: id, categoryKey: category);
  }

  Future<Either<Failure, List<ActivityReport>>> getByClient({
    required String id,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await repository.getByClient(
        id: id, startDate: startDate, endDate: endDate);
  }

  Future<Either<Failure, List<ActivityReport>>> getGeneral({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await repository.getGeneral(startDate: startDate, endDate: endDate);
  }
}
