import 'package:dartz/dartz.dart';
import 'package:huts_web/features/messages/data/models/message_employee.dart';
import 'package:huts_web/features/messages/domain/repositories/messages_repository.dart';

import '../../../../core/errors/failures.dart';

class SendMessage {
  MessagesRepository repository;
  SendMessage(this.repository);

  Future<Either<Failure, List<String>>> getEmployeesIds(
          {required List<String> jobs, required List<int> status}) async =>
      await repository.getIds(jobs, status);

  Future<Either<Failure, List<MessageEmployee>>> getEmployees() async =>
      await repository.getEmployees();
}
