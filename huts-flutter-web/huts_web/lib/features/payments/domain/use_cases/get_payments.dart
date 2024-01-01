import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/payments/domain/entities/payment_result_entity.dart';
import 'package:huts_web/features/payments/domain/repositories/payments_repository.dart';

import '../../../../core/use_cases_params/export_payments_excel_params.dart';

class GetPaymentsByClient {
  final GetPaymentsRepository getPaymentsRepository;
  GetPaymentsByClient(this.getPaymentsRepository);

  Future<Either<Failure, PaymentResult?>> callGeneralPayments(
          {required DateTime startDate, required DateTime endDate}) =>
      getPaymentsRepository.getGeneralPayments(
          startDate: startDate, endDate: endDate);

  Future<Either<Failure, PaymentResult?>> callPaymentsByClient(
          {required String clientId, required DateTime startDate}) =>
      getPaymentsRepository.getPaymentsByClient(
          clientId: clientId, startDate: startDate);

  Future<Either<Failure, PaymentResult?>> callRangePaymentsByClient(
          {required String clientId,
          required DateTime startDate,
          required DateTime? endDate}) =>
      getPaymentsRepository.getRangePaymentsByClient(
          clientId: clientId, startDate: startDate, endDate: endDate);

  Future<Either<Failure, bool>> exportToExcel(
      {required ExportPaymentsToExcelParams params, required bool forClient}) {
    return getPaymentsRepository.exportPaymentsToExcel(
        params: params, forClient: forClient);
  }
}
