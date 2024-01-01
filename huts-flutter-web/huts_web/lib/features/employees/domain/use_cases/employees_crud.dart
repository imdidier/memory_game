import 'package:dartz/dartz.dart';
import 'package:huts_web/features/employees/domain/repositories/employees_repository.dart';

import '../../../../core/errors/failures.dart';
import '../../display/provider/employees_provider.dart';

class EmployeesCrud {
  final EmployeesRepository repository;

  EmployeesCrud(this.repository);

  void getEmployees(EmployeesProvider provider) async =>
      repository.getEmployees(provider);

  Future<bool> updateEmployees(
          String idEmployee, Map<String, dynamic> data) async =>
      repository.updateEmployees(idEmployee, data);
  void getDetailsEmployee(
          String idEmployee, EmployeesProvider provider) async =>
      repository.getDetailsEmployee(idEmployee, provider);

  Future<Either<Failure, List<Map<String, dynamic>>>> getEmployeesPayments(
          DateTime startDate, DateTime endDate, String type) async =>
      await repository.getEmployeesPayments(startDate, endDate, type);
}
