import 'package:flutter/foundation.dart';
import 'package:huts_web/features/settings/data/datatsources/settings_remote_datasourse.dart';
import 'package:huts_web/features/settings/domain/repositories/holidays_repository.dart';

class HolidaysRepositoryImpl implements HolidaysRepository {
  final SettingsRemoteDatasourse remoteDatasourse;

  HolidaysRepositoryImpl(this.remoteDatasourse);

  @override
  Future<bool> createHoliday(
    Map<String, dynamic> newHoliday,
  ) async {
    try {
      return await remoteDatasourse.createHoliday(newHoliday);
    } catch (e) {
      if (kDebugMode) {
        print("HolidaysRepositoryImpl, createHoliday error: $e");
      }
      return false;
    }
  }

  @override
  Future<bool> updateHoliday(
    Map<String, dynamic> updatedHoliday,
  ) async {
    try {
      return await remoteDatasourse.updateHoliday(
        updatedHoliday,
      );
    } catch (e) {
      if (kDebugMode) {
        print("HolidaysRepositoryImpl, updateHoliday error: $e");
      }
      return false;
    }
  }

  @override
  Future<String> deleteHoliday(
    Map<String, dynamic> holiday,
  ) async {
    try {
      return await remoteDatasourse.deleteHoliday(holiday);
    } catch (e) {
      if (kDebugMode) {
        print("HolidaysRepositoryImpl, deleteHoliday error: $e");
      }
      return "fail";
    }
  }
}
