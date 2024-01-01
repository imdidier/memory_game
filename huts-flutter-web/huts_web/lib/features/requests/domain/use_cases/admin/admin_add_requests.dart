import 'package:huts_web/features/requests/domain/repositories/admin_requests_repository.dart';

import '../../../display/providers/create_event_provider.dart';

class AdminAddRequests {
  final AdminRequestsRepository repository;

  AdminAddRequests(this.repository);

  Future<bool> call(
          {required List<JobRequest> jobsRequests,
          required String eventId}) async =>
      await repository.addRequests(jobsRequests, eventId);
}
