import '../../entities/request_entity.dart';
import '../../repositories/get_requests_repository.dart';

class MarkArrival {
  final GetRequestsRepository repository;

  MarkArrival(this.repository);

  Future<bool> call(
          {required String idRequest, required Request request}) async =>
      await repository.markArrival(idRequest, request);
}
