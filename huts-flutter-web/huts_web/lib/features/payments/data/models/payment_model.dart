import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/payments/domain/entities/payment_entity.dart';
import 'package:huts_web/features/requests/data/models/request_model.dart';

class PaymentModel extends Payment {
  PaymentModel(
      {required super.totalHours,
      required super.totalHoursNormal,
      required super.totalHoursHoliday,
      required super.totalHoursDynamic,
      required super.totalClientPays,
      required super.totalToPayEmployee,
      required super.requestInfo,
      required super.employeeRequests});

  factory PaymentModel.fromMap(Map<dynamic, dynamic> map) {
    return PaymentModel(
      totalHours: map["details"]["total_hours"],
      totalHoursNormal:
          map["details"]["fare"]["client_fare"]["normal"]["hours"] ?? 0,
      totalHoursHoliday:
          map["details"]["fare"]["client_fare"]["holiday"]["hours"] ?? 0,
      totalHoursDynamic:
          map["details"]["fare"]["client_fare"]["dynamic"]["hours"] ?? 0,
      totalClientPays: map["details"]["fare"]["total_client_pays"],
      totalToPayEmployee: map["details"]["fare"]["total_to_pay_employee"],
      requestInfo: RequestModel.fromMap(map),
      employeeRequests: [RequestModel.fromMap(map)],
    );
  }

  factory PaymentModel.fromPayment(Payment payment) {
    return PaymentModel(
      totalHours: payment.requestInfo.details.totalHours,
      totalHoursNormal:
          payment.requestInfo.details.fare.clientFare.normalFare.hours,
      totalHoursHoliday:
          payment.requestInfo.details.fare.clientFare.holidayFare.hours,
      totalHoursDynamic:
          payment.requestInfo.details.fare.clientFare.dynamicFare.hours,
      totalClientPays: payment.requestInfo.details.fare.totalClientPays,
      totalToPayEmployee: payment.requestInfo.details.fare.totalToPayEmployee,
      requestInfo: RequestModel.fromRequest(payment.requestInfo),
      employeeRequests: payment.employeeRequests,
    );
  }

  toMap() {
    return <String, Object>{
      "employee":
          "${requestInfo.employeeInfo.names}-${requestInfo.employeeInfo.lastNames}",
      "job": requestInfo.details.job["name"],
      "start_date": CodeUtils.formatDate(requestInfo.details.startDate),
      "end_date": CodeUtils.formatDate(requestInfo.details.endDate),
      "total_hours": requestInfo.details.totalHours.toString(),
      "client_fare": "${requestInfo.details.fare.clientFare}",
      "total_client_pays": "${requestInfo.details.fare.totalClientPays}"
    };
  }
}
