import 'package:huts_web/features/auth/display/providers/auth_provider.dart';

import '../../repositories/get_requests_repository.dart';

class RunRequestAction {
  final GetRequestsRepository requestRepository;
  RunRequestAction(this.requestRepository);

  Future<bool> call(
          {required Map<String, dynamic> actionInfo,
          AuthProvider? authProvider}) async =>
      await requestRepository.runAction(
          actionInfo: actionInfo, authProvider: authProvider);
}
