abstract class HolidaysRepository {
  Future<bool> updateHoliday(
    Map<String, dynamic> updateHoliday,
  );
  Future<bool> createHoliday(
    Map<String, dynamic> newHoliday,
  );
  Future<String> deleteHoliday(
    Map<String, dynamic> holiday,
  );
}
