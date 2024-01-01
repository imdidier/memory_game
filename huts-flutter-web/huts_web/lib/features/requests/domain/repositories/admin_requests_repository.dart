import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../display/providers/create_event_provider.dart';
import '../entities/event_entity.dart';
import '../entities/request_entity.dart';

abstract class AdminRequestsRepository {
  Future<Either<Failure, List<Request>>> getRequests();
  Future<bool> addRequests(List<JobRequest> jobsRequests, String eventId);
  Future<bool> deleteRequest(Request request);
  Future<bool> updateRequest(
    Map<String, dynamic> updateMap,
    bool isEventSelected,
  );
  Future<String> cloneOrEditRequestsByEvent(List<Request> requestsList,
      String type, bool isEventSelected, Event event);
  Future<Either<Failure, Event>> getEvent(String eventId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getRequestHistorical(
      String requestId);
}
