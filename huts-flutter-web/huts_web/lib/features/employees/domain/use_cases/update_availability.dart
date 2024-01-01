import '../entities/available_day.dart';
import '../entities/employee_entity.dart';
import '../repositories/update_availability_repository.dart';

class UpdateDayAvailabilty {
  final UpdateAvailabilityRepository repository;

  UpdateDayAvailabilty(this.repository);
  Future<bool> call(AvailableDay availableDayEntity, Employee employee) async {
    return await repository.updateDayAvailability(availableDayEntity, employee);
  }
}
