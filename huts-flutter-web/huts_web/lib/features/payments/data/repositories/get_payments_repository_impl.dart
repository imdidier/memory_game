import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:huts_web/features/payments/data/datasources/get_payments_remote_datasource.dart';
import 'package:huts_web/features/payments/domain/entities/payment_result_entity.dart';
import 'package:huts_web/features/payments/domain/repositories/payments_repository.dart';

import '../../../../core/use_cases_params/export_payments_excel_params.dart';

class GetPaymentsRepositoryImpl implements GetPaymentsRepository {
  final GetPaymentsRemoteDatasource remoteDatasource;

  GetPaymentsRepositoryImpl(this.remoteDatasource);

  @override
  Future<Either<Failure, PaymentResult?>> getGeneralPayments(
      {required DateTime startDate, required DateTime endDate}) async {
    try {
      return Right(await remoteDatasource.getGeneralPayments(
          startDate: startDate, endDate: endDate));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  Future<Either<Failure, PaymentResult?>> getPaymentsByClient(
      {required String clientId, required DateTime startDate}) async {
    try {
      return Right(await remoteDatasource.getPaymentsByClient(
          clientId: clientId, startDate: startDate));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  Future<Either<Failure, PaymentResult?>> getRangePaymentsByClient(
      {required String clientId,
      required DateTime startDate,
      required DateTime? endDate}) async {
    try {
      return Right(await remoteDatasource.getRangePaymentsByClient(
          clientId: clientId, startDate: startDate, endDate: endDate));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> exportPaymentsToExcel(
      {required ExportPaymentsToExcelParams params,
      required bool forClient}) async {
    try {
      return Right(await remoteDatasource.exportPaymentsToExcel(
          params: params, forClient: forClient));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }
}
