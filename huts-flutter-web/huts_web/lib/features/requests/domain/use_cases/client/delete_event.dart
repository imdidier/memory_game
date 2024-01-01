import 'package:huts_web/features/requests/domain/repositories/event_repository.dart';

import '../../../data/models/event_model.dart';
import '../../entities/request_entity.dart';

class DeleteEvent {
  final EventRepository repository;

  DeleteEvent(this.repository);

  Future<bool> call(
          {required EventModel event, required List<Request> requests}) async =>
      await repository.deleteEvent(event, requests);
}
