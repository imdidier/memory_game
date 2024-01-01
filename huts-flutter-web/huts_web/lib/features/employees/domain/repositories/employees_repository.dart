import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../display/provider/employees_provider.dart';

abstract class EmployeesRepository {
  void getEmployees(EmployeesProvider provider);
  Future<bool> updateEmployees(String idEmployee, Map<String, dynamic> data);

  void getDetailsEmployee(String idEmployee, EmployeesProvider provider);
  Future<Either<Failure, List<Map<String, dynamic>>>> getEmployeesPayments(
      DateTime startDate, DateTime endDate, String type);
}
