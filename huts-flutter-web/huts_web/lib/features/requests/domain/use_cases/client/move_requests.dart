import '../../entities/request_entity.dart';
import '../../repositories/get_requests_repository.dart';

class MoveRequests {
  final GetRequestsRepository repository;

  MoveRequests(this.repository);

  Future<bool> call({
    required List<Request> requestList,
    required Map<String, dynamic> updateData,
    required bool isEventSelected,
  }) async =>
      await repository.moveRequests(
        requestList,
        updateData,
        isEventSelected,
      );
}
