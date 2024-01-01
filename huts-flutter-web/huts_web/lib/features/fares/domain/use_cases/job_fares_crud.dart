import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/fares/domain/repositories/job_fares_repository.dart';

class JobFaresCrud {
  JobFaresRepository repository;

  JobFaresCrud({required this.repository});

  Future<Either<Failure, bool>> updateJobFares(
      {required Map<String, dynamic> jobFares}) async {
    return await repository.updateJobFares(jobFares);
  }

  Future<String> deleteJob(Map<String, dynamic> data) async =>
      await repository.deleteJobFare(data);

  Future<String> createJob(Map<String, dynamic> data) async =>
      await repository.createJob(data);

  Future<String> createDoc(Map<String, dynamic> data) async =>
      await repository.createDoc(data);
}
