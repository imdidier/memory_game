import 'package:huts_web/features/pre_registered/domain/repositories/pre_registered_repository.dart';

class PreRegisteredCrud {
  PreRegisteredRepository repository;

  PreRegisteredCrud(this.repository);

  void listenPreRegisteredEmployees(DateTime start, DateTime end) async =>
      repository.getPreRegistered(start, end);

  Future<bool> approveEmployee(String employeeId, String employeeName) async {
    return await repository.approveEmployee(employeeId, employeeName);
  }
}
