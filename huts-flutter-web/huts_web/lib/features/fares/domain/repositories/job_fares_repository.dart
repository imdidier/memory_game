import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';

abstract class JobFaresRepository {
  Future<Either<Failure, bool>> updateJobFares(Map<String, dynamic> newData);
  Future<String> deleteJobFare(Map<String, dynamic> data);
  Future<String> createJob(Map<String, dynamic> data);
  Future<String> createDoc(Map<String, dynamic> data);
}
