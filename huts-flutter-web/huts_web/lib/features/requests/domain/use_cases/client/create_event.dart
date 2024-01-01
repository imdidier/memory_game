import 'package:huts_web/features/requests/data/models/event_model.dart';
import 'package:huts_web/features/requests/domain/repositories/event_repository.dart';

class CreateEvent {
  final EventRepository repository;

  CreateEvent(this.repository);

  Future<String> call(
          {required EventModel event, required bool isAdmin}) async =>
      await repository.createEvent(event, isAdmin);
}
