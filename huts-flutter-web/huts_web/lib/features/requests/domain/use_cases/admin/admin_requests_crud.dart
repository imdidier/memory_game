import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/requests/domain/entities/event_entity.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:huts_web/features/requests/domain/repositories/admin_requests_repository.dart';

class AdminRequestsCrud {
  final AdminRequestsRepository repository;
  AdminRequestsCrud(this.repository);

  Future<bool> delete(Request request) async {
    return await repository.deleteRequest(request);
  }

  Future<Either<Failure, Event>> getEvent(String eventId) async {
    return await repository.getEvent(eventId);
  }

  Future<String> cloneOrEditRequestsByEvent(List<Request> requestsList,
      String type, bool isEventSelected, Event event) async {
    return await repository.cloneOrEditRequestsByEvent(
      requestsList,
      type,
      isEventSelected,
      event,
    );
  }

  Future<bool> updateRequest(
      Map<String, dynamic> updateMap, bool isEventSelected) async {
    return await repository.updateRequest(updateMap, isEventSelected);
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getRequestHistorical(
      String requestId) async {
    return await repository.getRequestHistorical(requestId);
  }
}
