import 'package:dartz/dartz.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/payments/domain/entities/payment_result_entity.dart';

import '../../../../core/use_cases_params/export_payments_excel_params.dart';

abstract class GetPaymentsRepository {
  Future<Either<Failure, PaymentResult?>> getGeneralPayments(
      {required DateTime startDate, required DateTime endDate});
  Future<Either<Failure, PaymentResult?>> getPaymentsByClient(
      {required String clientId, required DateTime startDate});
  Future<Either<Failure, PaymentResult?>> getRangePaymentsByClient(
      {required String clientId,
      required DateTime startDate,
      required DateTime? endDate});

  Future<Either<Failure, bool>> exportPaymentsToExcel(
      {required ExportPaymentsToExcelParams params, required bool forClient});
}
