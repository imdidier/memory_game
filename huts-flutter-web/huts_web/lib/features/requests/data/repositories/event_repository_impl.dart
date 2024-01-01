import 'package:huts_web/features/requests/data/datasources/reomote/create_event_datasource.dart';
import 'package:huts_web/features/requests/domain/repositories/event_repository.dart';

import '../../display/providers/create_event_provider.dart';
import '../../domain/entities/request_entity.dart';
import '../models/event_model.dart';

class EventRepositoryImpl implements EventRepository {
  final CreateEventDatasource datasource;
  EventRepositoryImpl(this.datasource);

  @override
  Future<String> createEvent(EventModel event, bool isAdmin) async =>
      await datasource.createEvent(event, isAdmin);

  @override
  Future<bool> createRequets(List<JobRequest> jobRequests) async =>
      datasource.createRequests(jobRequests);

  @override
  Future<bool> updateNameEvent(String eventId, String nameEvent) async =>
      datasource.updateNameEvent(eventId, nameEvent);

  @override
  Future<bool> deleteEvent(EventModel event, List<Request> requests) async => datasource.deleteEvent(event, requests);
}
