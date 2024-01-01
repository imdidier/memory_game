import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';

abstract class ClientsRepository {
  void getClients();
  Future<bool> deleteClient({
    required clientId,
  });
  Future<bool> enableDisable({
    required String id,
    required int status,
    required bool isAdmin,
    bool enabledWebUser = false,
  });

  Future<bool> createClient({
    required client,
  });
  Future<Either<Failure, bool>> updateClientInfo({
    required clientId,
    required Map<String, dynamic> updateInfo,
    required String type,
  });
}
