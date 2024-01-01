import 'package:flutter/foundation.dart';
import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';

import '../datasources/employees_remote_datasource.dart';
import '../../domain/entities/available_day.dart';
import '../../domain/repositories/update_availability_repository.dart';

class UpdateAvailabilityRepositoryImpl implements UpdateAvailabilityRepository {
  final EmoployeesRemoteDataSourse updateAvailabilityRemoteDatasource;

  UpdateAvailabilityRepositoryImpl(this.updateAvailabilityRemoteDatasource);
  @override
  Future<bool> updateDayAvailability(
      AvailableDay availableDayEntity, Employee employee) async {
    try {
      return updateAvailabilityRemoteDatasource.updateDayAvailibity(
          availableDayEntity, employee);
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return false;
    }
  }
}
