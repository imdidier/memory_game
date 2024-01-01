import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';

import '../../data/models/message_employee.dart';

abstract class MessagesRepository {
  Future<Either<Failure, List<String>>> getIds(List<String> jobs, List<int> status);
  Future<Either<Failure, List<MessageEmployee>>> getEmployees();
}
