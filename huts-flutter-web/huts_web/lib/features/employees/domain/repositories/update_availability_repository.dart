import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';

import '../entities/available_day.dart';

abstract class UpdateAvailabilityRepository {
  Future<bool> updateDayAvailability(
      AvailableDay avaliableDayEntity, Employee employee);
}
