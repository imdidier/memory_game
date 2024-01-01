import 'package:huts_web/features/requests/domain/entities/request_entity.dart';

class Payment {
  double totalHours;
  double totalHoursNormal;
  double totalHoursHoliday;
  double totalHoursDynamic;
  double totalClientPays;
  double totalToPayEmployee;
  final Request requestInfo;
  List<Request> employeeRequests;

  Payment(
      {required this.totalHours,
      required this.totalHoursNormal,
      required this.totalHoursHoliday,
      required this.totalHoursDynamic,
      required this.totalClientPays,
      required this.totalToPayEmployee,
      required this.requestInfo,
      required this.employeeRequests});
}
