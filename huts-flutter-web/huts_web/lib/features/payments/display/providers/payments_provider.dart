import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/payments/data/datasources/get_payments_remote_datasource.dart';
import 'package:huts_web/features/payments/data/repositories/get_payments_repository_impl.dart';
import 'package:huts_web/features/payments/domain/entities/payment_entity.dart';
import 'package:huts_web/features/payments/domain/entities/payment_result_entity.dart';
import 'package:huts_web/features/payments/domain/use_cases/get_payments.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/use_cases_params/export_payments_excel_params.dart';

class PaymentsProvider with ChangeNotifier {
  //PaymentResult paymentsResult = PaymentResult.empty();
  PaymentResult paymentRangeResult = PaymentResult.empty();
  //PaymentResult paymentRangeByClientResult = PaymentResult.empty();

  List<Payment> filteredPayments = [];
  late Payment selectedPayment;

  bool isShowingDetails = false;
  bool isEditingDate = false;
  bool isLoading = false;
  bool isRangeSelected = false;
  bool isClient = false;

  isRangeDatesSelected() {
    if (calendarProperties.rangeEnd != null) {
      return true;
    }
    return false;
  }

  updateIsRangeSelected(val) {
    isRangeSelected = val;
    notifyListeners();
  }

  updateIsEditingDate(val) {
    isEditingDate = val;
    notifyListeners();
  }

  List<Map<String, dynamic>> requiredJobsByRange = [];

  void updateRequiredJobsByRange(List<Map<String, dynamic>> newJobs) {
    requiredJobsByRange = [...newJobs];
    notifyListeners();
  }

  TableCalendarProperties calendarProperties = TableCalendarProperties(
    calendarFormat: CalendarFormat.month,
    rangeSelectionMode: RangeSelectionMode.toggledOn,
    focusedDay: DateTime.now(),
    firstDay: DateTime(2020, 10, 16),
    lastDay: DateTime.now().add(const Duration(days: 365)),
    selectedDay: null,
    rangeStart: null,
    rangeEnd: null,
  );

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    calendarProperties.selectedDay = selectedDay;
    calendarProperties.focusedDay = focusedDay;
    calendarProperties.rangeStart = null;
    calendarProperties.rangeEnd = null;
    calendarProperties.rangeSelectionMode = RangeSelectionMode.toggledOn;
    notifyListeners();
  }

  void onRangeSelected(DateTime? start, DateTime? end, BuildContext context) {
    if (start == null) {
      return;
    }
    start = DateTime(
      start.year,
      start.month,
      start.day,
      00,
      00,
    );

    end ??= DateTime(
      start.year,
      start.month,
      start.day,
      23,
      59,
    );

    //if (end.day != start.day) {
    // end = DateTime(
    //   end.year,
    //   end.month,
    //   end.day,
    //   23,
    //   59,
    // );
    AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    isEditingDate = false;
    if (authProvider.webUser.accountInfo.type == "client") {
      getClientPaymentsByRange(
        clientId: authProvider.webUser.accountInfo.companyId,
        startDate: start,
        endDate: end,
      );
    } else {
      getGeneralPayments(startDate: start, endDate: end);
    }
    // }
  }

  void onFormatChanged(CalendarFormat format) {
    calendarProperties.calendarFormat = format;
    notifyListeners();
  }

  void updateSelectedPayment(Payment payment) {
    selectedPayment = payment;
    notifyListeners();
  }

  void updateDetailsStatus(bool newValue, bool newValueIsClient) {
    isShowingDetails = newValue;
    isClient = newValueIsClient;
    notifyListeners();
  }

  void updateFilteredPayments(List<Payment> newPayments) {
    filteredPayments.addAll(newPayments);
    notifyListeners();
  }

  void dataExport(PaymentResult paymentRangeResult, bool isIndivual) {
    if (isIndivual) {
      for (var payment in filteredPayments) {
        int index = paymentRangeResult.individualPayments.indexWhere(
            (element) => element.requestInfo.id != payment.requestInfo.id);

        if (index != 1) {
          paymentRangeResult.individualPayments.removeAt(index);
        }
      }
    } else {
      for (var payment in paymentRangeResult.groupPayments) {
        int index = filteredPayments.indexWhere(
            (element) => element.requestInfo.id == payment.requestInfo.id);

        if (index != -1) {
          paymentRangeResult.groupPayments.removeAt(index);
        }
        notifyListeners();
      }
    }
    notifyListeners();
  }

  /// It gets the payments by client.
  ///
  /// Args:
  ///   clientId (String): The client's id.
  ///   startDate (DateTime): The date from which you want to get the payments.
  Future<void> getGeneralPayments(
      {required DateTime startDate, required DateTime endDate}) async {
    isLoading = true;
    GetPaymentsRepositoryImpl repository =
        GetPaymentsRepositoryImpl(GetPaymentsRemoteDatasourceImpl());
    final paymentsResp = await GetPaymentsByClient(repository)
        .callGeneralPayments(startDate: startDate, endDate: endDate);
    paymentsResp.fold((Failure failure) {
      LocalNotificationService.showSnackBar(
        type: "error",
        message: failure.errorMessage.toString(),
        icon: Icons.error_outline,
      );
      isLoading = false;
      notifyListeners();
    }, (PaymentResult? result) async {
      paymentRangeResult = result!;
      isLoading = false;
      notifyListeners();
    });
  }

  // Future<void> getPaymentsByClient(
  //     {required String clientId, required DateTime startDate}) async {
  //   isLoading = true;
  //   GetPaymentsRepositoryImpl repository =
  //       GetPaymentsRepositoryImpl(GetPaymentsRemoteDatasourceImpl());
  //   final paymentsResp = await GetPaymentsByClient(repository)
  //       .callPaymentsByClient(clientId: clientId, startDate: startDate);
  //   paymentsResp.fold((Failure failure) {
  //     LocalNotificationService.showSnackBar(
  //       type: "error",
  //       message: failure.errorMessage.toString(),
  //       icon: Icons.error_outline,
  //     );
  //     isLoading = false;
  //     notifyListeners();
  //   }, (PaymentResult? result) async {
  //     paymentRangeResult = result!;
  //     isLoading = false;
  //     notifyListeners();
  //   });
  // }

  /// It gets the payments of a client by a range of dates.
  ///
  /// Args:
  ///   clientId (String): The client's id.
  ///   startDate (DateTime): The start date of the range.
  ///   endDate (DateTime): The end date of the range.
  Future<void> getClientPaymentsByRange(
      {required String clientId,
      required DateTime startDate,
      required DateTime? endDate}) async {
    isLoading = true;
    GetPaymentsRepositoryImpl repository =
        GetPaymentsRepositoryImpl(GetPaymentsRemoteDatasourceImpl());
    final paymentsResp = await GetPaymentsByClient(repository)
        .callRangePaymentsByClient(
            clientId: clientId, startDate: startDate, endDate: endDate);
    paymentsResp.fold((Failure failure) {
      LocalNotificationService.showSnackBar(
        type: "error",
        message: failure.errorMessage.toString(),
        icon: Icons.error_outline,
      );
      isLoading = false;
      notifyListeners();
    }, (PaymentResult? result) async {
      paymentRangeResult = result!;
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> exportPaymentsToExcel(
      {required ExportPaymentsToExcelParams params,
      bool forClient = false,
      bool isSelectedClient = false}) async {
    isLoading = true;
    notifyListeners();
    GetPaymentsRepositoryImpl repository =
        GetPaymentsRepositoryImpl(GetPaymentsRemoteDatasourceImpl());
    final paymentsResp = await GetPaymentsByClient(repository)
        .exportToExcel(params: params, forClient: isSelectedClient);
    paymentsResp.fold((Failure failure) {
      LocalNotificationService.showSnackBar(
        type: "error",
        message: failure.errorMessage.toString(),
        icon: Icons.error_outline,
      );
      isLoading = false;
      notifyListeners();
    }, (bool? result) async {
      isLoading = false;
      notifyListeners();
    });
  }
}
