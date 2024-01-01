import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/domain/repositories/get_requests_repository.dart';

import '../../entities/event_entity.dart';

class GetRequests {
  final GetRequestsRepository repository;

  GetRequests(this.repository);

  void call({
    required Event event,
    required GetRequestsProvider provider,
  }) async =>
      repository.getRequests(
        event: event,
        provider: provider,
      );

  void getAllRequests({
    required GetRequestsProvider provider,
    required List<DateTime> filterDates,
    required String nameTab,
    String idClient = '',
  }) async =>
      repository.getAllRequests(
        dates: filterDates,
        provider: provider,
        nameTab: nameTab,
        idClient: idClient,
      );
}
