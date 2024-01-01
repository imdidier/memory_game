import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/features/requests/data/datasources/admin/admin_requests_remote_datasource.dart';
import 'package:huts_web/features/requests/domain/entities/event_entity.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:huts_web/features/requests/display/providers/create_event_provider.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:huts_web/features/requests/domain/repositories/admin_requests_repository.dart';

class AdminRequestsRepositoryImpl implements AdminRequestsRepository {
  final AdminRequestsRemoteDatasource datasource;
  AdminRequestsRepositoryImpl(this.datasource);
  @override
  Future<bool> addRequests(
      List<JobRequest> jobsRequests, String eventId) async {
    try {
      return await datasource.addRequests(jobsRequests, eventId);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> cloneOrEditRequestsByEvent(List<Request> requestsList,
      String type, bool isEventSelected, Event event) async {
    try {
      return await datasource.cloneOrEditRequestsByEvent(
          requestsList, type, isEventSelected, event);
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<bool> deleteRequest(Request request) async {
    try {
      return await datasource.deleteRequest(request);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<Failure, List<Request>>> getRequests() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Event>> getEvent(String eventId) async {
    try {
      return Right(await datasource.getEvent(eventId));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  Future<bool> updateRequest(
      Map<String, dynamic> updateMap, bool isEventSelected) async {
    try {
      return await datasource.updateRequest(updateMap, isEventSelected);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getRequestHistorical(
      String requestId) async {
    try {
      return Right(await datasource.getRequestHistorical(requestId));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }
}
