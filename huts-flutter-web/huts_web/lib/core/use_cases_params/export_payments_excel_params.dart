import '../../features/payments/domain/entities/payment_entity.dart';

class ExportPaymentsToExcelParams {
  final double totalHours;
  final double totalHoursNormal;
  final double totalHoursHoliday;
  final double totalHoursDynamic;
  final double totalToPay;
  final List<Payment> payments;
  final String fileName;
  final bool isClient;
  final bool isIndividual;

  ExportPaymentsToExcelParams({
    required this.totalHours,
    required this.totalHoursNormal,
    required this.totalHoursHoliday,
    required this.totalHoursDynamic,
    required this.totalToPay,
    required this.payments,
    required this.fileName,
    required this.isClient,
    required this.isIndividual,
  });
}
