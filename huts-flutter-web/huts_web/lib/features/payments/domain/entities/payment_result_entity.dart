import 'package:huts_web/features/payments/domain/entities/payment_entity.dart';

import 'month_jobs_entity.dart';

class PaymentResult {
  String week;
  String month;
  double totalHours;
  double totalHoursNormal;
  double totalHoursHoliday;
  double totalHoursDynamic;
  double totalClientPays;
  double totalToPayEmployee;
  // double totalHoursMonth;
  // double totalHoursMonthNormal;
  // double totalHoursMonthHoliday;
  // double totalHoursMonthDynamic;
  // double totalClientPaysMonth;
  // double totalToPayEmployeeMonth;
  List<Payment> individualPayments;
  List<Payment> groupPayments;
  //List<Payment> monthPayments;
  List<DateJob> jobs;

  PaymentResult({
    required this.week,
    required this.month,
    required this.totalHours,
    required this.totalHoursNormal,
    required this.totalHoursHoliday,
    required this.totalHoursDynamic,
    required this.totalClientPays,
    required this.totalToPayEmployee,
    required this.individualPayments,
    required this.groupPayments,
    required this.jobs,
    // required this.totalHoursMonth,
    // required this.totalHoursMonthNormal,
    // required this.totalHoursMonthHoliday,
    // required this.totalHoursMonthDynamic,
    // required this.totalClientPaysMonth,
    // required this.totalToPayEmployeeMonth,
    //required this.monthPayments,
  });

  PaymentResult.empty()
      : week = "",
        month = '',
        totalHours = 0,
        totalHoursNormal = 0,
        totalHoursHoliday = 0,
        totalHoursDynamic = 0,
        totalClientPays = 0,
        totalToPayEmployee = 0,
        individualPayments = [],
        groupPayments = [],
        jobs = [];
}
