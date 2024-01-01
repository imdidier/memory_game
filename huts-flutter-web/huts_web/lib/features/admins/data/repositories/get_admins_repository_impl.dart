import 'package:flutter/foundation.dart';
import 'package:huts_web/features/admins/domain/repositories/get_admins_repository.dart';

import '../datasources/admins_remote_datasource.dart';

class GetAdminsRepositoryImpl implements GetAdminsRepository {
  final AdminsRemoteDataSource dataSource;

  GetAdminsRepositoryImpl(this.dataSource);

  @override
  void getAdmins(String uid) async {
    try {
      dataSource.listenAdmins(uid);
    } catch (e) {
      if (kDebugMode) {
        print("GetAdminRepositoryImpl, getAdmins error: $e");
      }
    }
  }

  @override
  void getCompanies(String uid) async {
    try {
      dataSource.listenCompanies(uid);
    } catch (e) {
      if (kDebugMode) {
        print("GetAdminRepositoryImpl, getCompanies error: $e");
      }
    }
  }
}
