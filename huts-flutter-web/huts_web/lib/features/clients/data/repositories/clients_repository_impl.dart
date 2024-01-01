import 'package:flutter/foundation.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:huts_web/features/clients/domain/repositories/clients_repository.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  final ClientsRemoteDatasource datasource;
  ClientsRepositoryImpl(this.datasource);

  @override
  Future<bool> enableDisable(
      {required String id,
      required int status,
      required bool isAdmin,
      bool enabledWebUser = false}) async {
    try {
      await datasource.enableDisabled(id, status, isAdmin, enabledWebUser);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("AdminsActionsRepositoryImpl, enableDisable error: $e");
      }
      return false;
    }
  }

  @override
  void getClients() async {
    try {
      datasource.listenClients();
    } catch (e) {
      if (kDebugMode) {
        print("ClientsRepositoryImpl, getClients error: $e");
      }
    }
  }

  @override
  Future<bool> deleteClient({
    required clientId,
  }) async {
    try {
      return await datasource.deleteClient(clientId: clientId);
    } on ServerException {
      return false;
    }
  }

  @override
  Future<bool> createClient({
    required client,
  }) async {
    try {
      return await datasource.createClient(client: client);
    } on ServerException {
      return false;
    }
  }

  @override
  Future<Either<Failure, bool>> updateClientInfo(
      {required clientId,
      required Map<String, dynamic> updateInfo,
      required String type}) async {
    try {
      if (type == "general") {
        return Right(await datasource.updateGeneralInfo(
            clientId: clientId, updateInfo: updateInfo));
      }

      if (type == "favs") {
        return Right(await datasource.updateFavs(
            clientId: clientId, updateInfo: updateInfo));
      }

      if (type == "locks") {
        return Right(await datasource.updateLocks(
            clientId: clientId, updateInfo: updateInfo));
      }

      if (type == "web_users") {
        return Right(await datasource.updateWebUsers(
            clientId: clientId, updateInfo: updateInfo));
      }

      if (type == "legal_info") {
        return Right(await datasource.updateLegalInfo(
            clientId: clientId, updateInfo: updateInfo));
      }

      if (type == "dynamic_fare") {
        return Right(await datasource.updateDynamicFareAvailability(
            clientId: clientId, updateInfo: updateInfo));
      }

      if (type == "jobs") {
        return Right(await datasource.updateJobs(
            clientId: clientId, updateInfo: updateInfo));
      }

      if (type == "location") {
        return Right(
          await datasource.updateLocation(
            clientId: clientId,
            updateInfo: updateInfo,
          ),
        );
      }

      return Right(await datasource.updateGeneralInfo(
          clientId: clientId, updateInfo: updateInfo));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }
}
