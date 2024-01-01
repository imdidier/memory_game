import 'package:flutter/foundation.dart';
import 'package:huts_web/features/admins/data/datasources/admins_remote_datasource.dart';
import 'package:huts_web/features/admins/domain/repositories/admins_actions_repository.dart';

class AdminsActionsRepositoryImpl implements AdminsActionsRepository {
  final AdminsRemoteDataSource dataSource;
  AdminsActionsRepositoryImpl(this.dataSource);
  @override
  Future<bool> enableDisable(
      {required String id, required bool toEnable}) async {
    try {
      await dataSource.enableDisabled(id, toEnable);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("AdminsActionsRepositoryImpl, enableDisable error: $e");
      }
      return false;
    }
  }

  @override
  Future<String> create(Map<String, dynamic> data) async {
    try {
      return await dataSource.create(data);
    } catch (e) {
      if (kDebugMode) {
        print("AdminsActionsRepositoryImpl, create error: $e");
      }
      return "error";
    }
  }

  @override
  Future<String> delete(String uid) async {
    try {
      return await dataSource.delete(uid);
    } catch (e) {
      if (kDebugMode) {
        print("AdminsActionsRepositoryImpl, delete error: $e");
      }
      return "error";
    }
  }

  @override
  Future<String> edit(Map<String, dynamic> data, bool isFromAdmin) async {
    try {
      return await dataSource.edit(data, isFromAdmin);
    } catch (e) {
      if (kDebugMode) {
        print("AdminsActionsRepositoryImpl, edit error: $e");
      }
      return "error";
    }
  }
}
