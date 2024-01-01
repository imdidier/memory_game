import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';

import '../entities/event_entity.dart';
import '../entities/request_entity.dart';

abstract class GetRequestsRepository {
  void getEvents({
    required String clientId,
    required List<DateTime> dates,
    required GetRequestsProvider provider,
  });

  Future<void> getActiveEvents(String clientID, GetRequestsProvider provider);

  void getRequests({
    required Event event,
    required GetRequestsProvider provider,
  });
  Future<bool> runAction({
    required Map<String, dynamic> actionInfo,
    AuthProvider? authProvider,
  });

  Future<Either<Failure, Map<String, dynamic>>> getClientPrintEvents(
    String clientId,
    DateTime startDate,
    DateTime endDate,
  );

  void getAllRequests({
    required List<DateTime> dates,
    required GetRequestsProvider provider,
    required String nameTab,
    String idClient,
  });

  Future<bool> markArrival(String idRequest, Request request);

  Future<bool> moveRequests(
    List<Request> requestList,
    Map<String, dynamic> updateData,
    bool isEvenselected,
  );
}
