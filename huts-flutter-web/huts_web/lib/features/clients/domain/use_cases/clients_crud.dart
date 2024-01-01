import 'package:dartz/dartz.dart';
import 'package:huts_web/features/clients/domain/repositories/clients_repository.dart';

import '../../../../core/errors/failures.dart';
import '../entities/client_entity.dart';

class ClientsCrud {
  ClientsRepository repository;
  ClientsCrud(this.repository);

  Future<bool> enableDisable(
          {required String id,
          required int status,
          required bool isAdmin,
          bool enabledWebUser = false}) async =>
      await repository.enableDisable(
        id: id,
        status: status,
        isAdmin: isAdmin,
        enabledWebUser: enabledWebUser,
      );

  void getClients() async => repository.getClients();
  Future<bool> deleteClient(String clientId) async =>
      await repository.deleteClient(clientId: clientId);
  Future<bool> createClient(ClientEntity client) async =>
      await repository.createClient(client: client);
  Future<Either<Failure, bool>> updateClientInfo(String clientId,
          Map<String, dynamic> updateInfo, String type) async =>
      await repository.updateClientInfo(
        clientId: clientId,
        updateInfo: updateInfo,
        type: type,
      );
}
