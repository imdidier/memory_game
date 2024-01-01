import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:huts_web/features/messages/data/datasources/messages_remote_datasource.dart';
import 'package:huts_web/features/messages/data/models/message_employee.dart';
import 'package:huts_web/features/messages/domain/repositories/messages_repository.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRemoteDataSource dataSource;

  MessagesRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<String>>> getIds(
      List<String> jobs, List<int> status) async {
    try {
      return Right(await dataSource.getIds(jobs, status));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  Future<Either<Failure, List<MessageEmployee>>> getEmployees() async {
    try {
      return Right(await dataSource.getEmployees());
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }
}
