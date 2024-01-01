import 'package:huts_web/features/requests/domain/repositories/event_repository.dart';

import '../../../display/providers/create_event_provider.dart';

class CreateRequests {
  final EventRepository repository;

  CreateRequests(this.repository);

  Future<bool> call({required List<JobRequest> jobsRequests}) async =>
      await repository.createRequets(jobsRequests);
}
