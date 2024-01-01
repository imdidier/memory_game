import 'package:huts_web/features/requests/domain/repositories/event_repository.dart';

class CreateEvent {
  final EventRepository repository;

  CreateEvent(this.repository);

  Future<bool> call(
          {required String eventId, required String nameEvent}) async =>
      await repository.updateNameEvent(eventId, nameEvent);
}
