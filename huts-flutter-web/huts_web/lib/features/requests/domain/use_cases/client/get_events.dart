import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/domain/repositories/get_requests_repository.dart';

class GetEvents {
  final GetRequestsRepository repository;

  GetEvents(this.repository);

  void call({
    required String clientId,
    required List<DateTime> filterDates,
    required GetRequestsProvider requestsProvider,
  }) async {
    repository.getEvents(
      clientId: clientId,
      dates: filterDates,
      provider: requestsProvider,
    );
  }

  Future<void> getActiveClientEvents(
    String clientId,
    GetRequestsProvider provider,
  ) async =>
      await repository.getActiveEvents(clientId, provider);

  Future<Either<Failure, Map<String, dynamic>>> getClientPrintEvents(
    String clientId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await repository.getClientPrintEvents(
      clientId,
      startDate,
      endDate,
    );
  }
}
