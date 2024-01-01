import 'package:huts_web/features/settings/domain/repositories/holidays_repository.dart';

class HolidaysCrud {
  final HolidaysRepository repository;
  HolidaysCrud(this.repository);

  Future<bool> updateHoliday(
    Map<String, dynamic> updateHoliday,
  ) async =>
      await repository.updateHoliday(
        updateHoliday,
      );

  Future<bool> createHoliday({
    required Map<String, dynamic> newHoliday,
  }) async =>
      await repository.createHoliday(
        newHoliday,
      );

  Future<String> deleteHoliday({
    required Map<String, dynamic> holiday,
  }) async =>
      await repository.deleteHoliday(
        holiday,
      );
}
