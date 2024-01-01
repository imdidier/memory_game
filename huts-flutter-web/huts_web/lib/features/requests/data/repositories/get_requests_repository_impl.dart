import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/requests/data/datasources/get_requests_remote_datasource.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/domain/repositories/get_requests_repository.dart';

import '../../domain/entities/event_entity.dart';
import '../../domain/entities/request_entity.dart';

class GetRequestRepositoryImpl implements GetRequestsRepository {
  final GetRequestsRemoteDatasource datasource;

  GetRequestRepositoryImpl(this.datasource);
  @override
  void getAllRequests({
    required List<DateTime> dates,
    required GetRequestsProvider provider,
    required String nameTab,
    String idClient = '',
    bool listenEvent = false,
  }) async {
    try {
      datasource.listenAllRequests(
        dates: dates,
        requestsProvider: provider,
        nameTab: nameTab,
        idClient: idClient,
      );
    } catch (e) {
      if (kDebugMode) {
        print("GetRequestRepositoryImpl, getAllRequests error: $e");
      }
    }
  }

  @override
  void getEvents(
      {required String clientId,
      required List<DateTime> dates,
      required GetRequestsProvider provider}) async {
    try {
      datasource.listenEvents(clientId, dates, provider);
    } catch (e) {
      developer.log("GetRequestRepositoryImpl, getEvents error: $e");
    }
  }

  @override
  void getRequests(
      {required Event event, required GetRequestsProvider provider}) {
    try {
      datasource.listenEventRequests(event, provider);
    } catch (e) {
      if (kDebugMode) print("GetRequestRepositoryImpl, getRequests error: $e");
    }
  }

  @override
  Future<bool> runAction(
      {required Map<String, dynamic> actionInfo,
      AuthProvider? authProvider}) async {
    try {
      if (actionInfo["type"] == "time") {
        return await datasource.runTimeAction(actionInfo);
      }
      if (actionInfo["type"] == "clone") {
        return await (actionInfo["is_to_event"])
            ? datasource.runCloneToEventAction(actionInfo)
            : datasource.runCloneAction(actionInfo);
      }
      if (actionInfo["type"] == "edit") {
        return await datasource.runEditAction(actionInfo);
      }

      if (actionInfo["type"] == "favorite") {
        return await datasource.runFavoriteAction(actionInfo, authProvider!);
      }

      if (actionInfo["type"] == "block") {
        return await datasource.runBlockAction(actionInfo, authProvider!);
      }
      return await datasource.runRateAction(actionInfo);
    } catch (e) {
      if (kDebugMode) print("GetRequestRepositoryImpl, runAction error: $e");
      return false;
    }
  }

  @override
  Future<void> getActiveEvents(
      String clientId, GetRequestsProvider provider) async {
    try {
      await datasource.getActiveEvents(clientId, provider);
    } catch (e) {
      if (kDebugMode) {
        print("GetRequestRepositoryImpl, getActiveEvents error: $e");
      }
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getClientPrintEvents(
      String clientId, DateTime startDate, DateTime endDate) async {
    try {
      return Right(
        await datasource.getClientPrintEvents(clientId, startDate, endDate),
      );
    } on ServerException catch (e) {
      return Left(
        ServerFailure(errorMessage: e.message),
      );
    }
  }

  @override
  Future<bool> markArrival(String idRequest, Request request) async {
    try {
      return await datasource.markArrival(idRequest, request);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> moveRequests(
    List<Request> requestList,
    Map<String, dynamic> updateData,
    bool isEvenselected,
  ) async {
    try {
      return await datasource.moveRequests(
        requestList,
        updateData,
        isEvenselected,
      );
    } catch (e) {
      return false;
    }
  }
}
