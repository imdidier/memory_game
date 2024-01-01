import 'package:huts_web/features/requests/data/models/event_model.dart';

import '../../display/providers/create_event_provider.dart';
import '../entities/request_entity.dart';

abstract class EventRepository {
  Future<String> createEvent(EventModel event, bool isAdmin);
  Future<bool> updateNameEvent(String eventId, String nameEvent);
  Future<bool> deleteEvent(EventModel event, List<Request> requests);
  Future<bool> createRequets(List<JobRequest> jobRequests);
}
