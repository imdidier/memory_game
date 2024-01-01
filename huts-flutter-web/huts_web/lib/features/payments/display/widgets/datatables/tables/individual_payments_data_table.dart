import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/domain/entities/payment_entity.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:provider/provider.dart';

import '../../../../../../../core/utils/code/code_utils.dart';
import '../../../../../../core/use_cases_params/export_payments_excel_params.dart';
import '../../export_to_excel_button.dart';

class IndividualPaymentsDataTable extends StatefulWidget {
  final List<Payment> payments;
  final ScreenSize screenSize;
  final bool isClient;
  final bool isSelectedClient;

  const IndividualPaymentsDataTable(
      {required this.payments,
      required this.screenSize,
      required this.isClient,
      this.isSelectedClient = false,
      Key? key})
      : super(key: key);

  @override
  State<IndividualPaymentsDataTable> createState() =>
      _IndividualPaymentsDataTableState();
}

class _IndividualPaymentsDataTableState
    extends State<IndividualPaymentsDataTable> {
  bool isLoaded = false;
  List<Payment> filteredPayments = [];
  TextEditingController searchController = TextEditingController();
  late PaymentsProvider paymentsProvider;
  List<String> headers = const [
    "Nombre/Nombre",
    "Cargo/Cargo",
    "Fecha inicio/Fecha inicio",
    "Fecha fin/Fecha fin",
    "TH - N/Total horas normales",
    "VH - N/Valor horas normales",
    "TH - F/Total horas festivas",
    "VH - F/Valor horas festivas",
    "TH - DIN/Total horas dinámicas",
    "VH - DIN/Valor horas dinámicas",
    "Total horas/Total horas",
    "Total a pagar/Total a pagar",
    //"ID/Identificador",
  ];
  List<List<String>> dataTableFromResponsive = [];
  bool _sortAscending = true;
  int? _sortColumnIndex;

  @override
  Widget build(BuildContext context) {
    bool isDesktop = widget.screenSize.blockWidth >= 1300;
    dataTableFromResponsive.clear();

    if (filteredPayments.isNotEmpty) {
      dataTableFromResponsive.clear();

      for (var individualPayment in filteredPayments) {
        dataTableFromResponsive.add([
          "Nombre-${CodeUtils.getFormatedName(
            individualPayment.requestInfo.employeeInfo.names,
            individualPayment.requestInfo.employeeInfo.lastNames,
          )} ",
          "Cargo-${individualPayment.requestInfo.details.job["name"]}",
          "Fecha inicio-${CodeUtils.formatDate(individualPayment.requestInfo.details.startDate)}",
          "Fecha fin-${CodeUtils.formatDate(individualPayment.requestInfo.details.endDate)}",
          "Total horas normales-${widget.isClient ? individualPayment.requestInfo.details.fare.clientFare.normalFare.hours.toString() : individualPayment.requestInfo.details.fare.employeeFare.normalFare.hours.toString()}",
          "Valor horas normales-${widget.isClient ? CodeUtils.formatMoney(individualPayment.requestInfo.details.fare.clientFare.normalFare.totalToPay) : CodeUtils.formatMoney(individualPayment.requestInfo.details.fare.employeeFare.normalFare.totalToPay)}",
          "Total horas festivas-${widget.isClient ? individualPayment.requestInfo.details.fare.clientFare.holidayFare.hours.toString() : individualPayment.requestInfo.details.fare.employeeFare.holidayFare.hours.toString()}",
          "Valor horas festivas-${widget.isClient ? CodeUtils.formatMoney(individualPayment.requestInfo.details.fare.clientFare.holidayFare.totalToPay) : CodeUtils.formatMoney(individualPayment.requestInfo.details.fare.employeeFare.holidayFare.totalToPay)}",
          "Total horas dinámicas-${widget.isClient ? individualPayment.requestInfo.details.fare.clientFare.dynamicFare.hours.toString() : individualPayment.requestInfo.details.fare.employeeFare.dynamicFare.hours.toString()}",
          "Valor horas dinámicas-${widget.isClient ? CodeUtils.formatMoney(individualPayment.requestInfo.details.fare.clientFare.dynamicFare.totalToPay) : CodeUtils.formatMoney(individualPayment.requestInfo.details.fare.employeeFare.dynamicFare.totalToPay)}",
          "Total horas-${individualPayment.requestInfo.details.totalHours.toString()}",
          "Total a pagar- ${widget.isClient ? CodeUtils.formatMoney(individualPayment.requestInfo.details.fare.totalClientPays) : CodeUtils.formatMoney(individualPayment.requestInfo.details.fare.totalToPayEmployee)}",
          "Identificador- ${individualPayment.requestInfo.id}",
        ]);
      }
    }
    return Container(
      decoration: UiVariables.boxDecoration,
      width: (isDesktop || widget.screenSize.blockWidth >= 580)
          ? widget.screenSize.blockWidth * 0.9
          : widget.screenSize.blockWidth,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          getTableHeader(isDesktop, "Listado de pagos - individual"),
          SizedBox(
            height: filteredPayments.isEmpty
                ? widget.screenSize.height * 0.3
                : widget.screenSize.height * 0.7,
            width: widget.screenSize.blockWidth >= 920
                ? widget.screenSize.blockWidth * 0.9
                : widget.screenSize.blockWidth - 125,
            child: widget.screenSize.blockWidth >= 920
                ? SelectionArea(
                    child: PaginatedDataTable2(
                      horizontalMargin: 10,
                      columnSpacing: 10,
                      empty: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text("No hay información"),
                        ),
                      ),
                      columns: getColumns(),
                      source: PaymentsTableSource(
                        filteredPayments,
                        widget.isClient,
                      ),
                      wrapInCard: false,
                      minWidth: widget.screenSize.blockWidth,
                      fit: FlexFit.tight,
                      dataRowHeight: kMinInteractiveDimension + 15,
                      rowsPerPage: 10,
                      onRowsPerPageChanged: (value) {},
                      availableRowsPerPage: const [10, 20, 50],
                      sortAscending: _sortAscending,
                      sortColumnIndex: _sortColumnIndex,
                      sortArrowIcon: Icons.keyboard_arrow_up,
                      sortArrowAnimationDuration:
                          const Duration(milliseconds: 300),
                    ),
                  )
                : SingleChildScrollView(
                    child: DataTableFromResponsive(
                      listData: dataTableFromResponsive,
                      screenSize: widget.screenSize,
                      type: 'individual-payment',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      if (columnIndex == 0) {
        filteredPayments.sort((a, b) {
          String aEmployeeName = CodeUtils.getFormatedName(
                  a.requestInfo.employeeInfo.names,
                  a.requestInfo.employeeInfo.lastNames)
              .toLowerCase()
              .trim();
          String bEmployeeName = CodeUtils.getFormatedName(
                  b.requestInfo.employeeInfo.names,
                  b.requestInfo.employeeInfo.lastNames)
              .toLowerCase()
              .trim();

          if (ascending) {
            return aEmployeeName.compareTo(bEmployeeName);
          }
          return bEmployeeName.compareTo(aEmployeeName);
        });

        return;
      }

      if (columnIndex == 1) {
        filteredPayments.sort((a, b) {
          String aJob = a.requestInfo.details.job["name"].toLowerCase().trim();

          String bJob = b.requestInfo.details.job["name"].toLowerCase().trim();

          if (ascending) {
            return aJob.compareTo(bJob);
          }
          return bJob.compareTo(aJob);
        });

        return;
      }

      if (columnIndex == 2) {
        filteredPayments.sort((a, b) {
          DateTime aStartDate = a.requestInfo.details.startDate;

          DateTime bStartDate = b.requestInfo.details.startDate;

          if (ascending) {
            return aStartDate.compareTo(bStartDate);
          }
          return bStartDate.compareTo(aStartDate);
        });

        return;
      }

      if (columnIndex == 3) {
        filteredPayments.sort((a, b) {
          DateTime aEndDate = a.requestInfo.details.endDate;

          DateTime bEndDate = b.requestInfo.details.endDate;

          if (ascending) {
            return aEndDate.compareTo(bEndDate);
          }
          return bEndDate.compareTo(aEndDate);
        });

        return;
      }

      if (columnIndex == 4) {
        filteredPayments.sort((a, b) {
          double aTHN = widget.isClient
              ? a.requestInfo.details.fare.clientFare.normalFare.hours
              : a.requestInfo.details.fare.employeeFare.normalFare.hours;

          double bTHN = widget.isClient
              ? b.requestInfo.details.fare.clientFare.normalFare.hours
              : b.requestInfo.details.fare.employeeFare.normalFare.hours;

          if (ascending) {
            return aTHN.compareTo(bTHN);
          }
          return bTHN.compareTo(aTHN);
        });

        return;
      }
      if (columnIndex == 5) {
        filteredPayments.sort((a, b) {
          double aVHN = widget.isClient
              ? a.requestInfo.details.fare.clientFare.normalFare.totalToPay
              : a.requestInfo.details.fare.employeeFare.normalFare.totalToPay;

          double bVHN = widget.isClient
              ? b.requestInfo.details.fare.clientFare.normalFare.totalToPay
              : b.requestInfo.details.fare.employeeFare.normalFare.totalToPay;

          if (ascending) {
            return aVHN.compareTo(bVHN);
          }
          return bVHN.compareTo(aVHN);
        });

        return;
      }
      if (columnIndex == 6) {
        filteredPayments.sort((a, b) {
          double aTHF = widget.isClient
              ? a.requestInfo.details.fare.clientFare.holidayFare.hours
              : a.requestInfo.details.fare.employeeFare.holidayFare.hours;

          double bTHF = widget.isClient
              ? b.requestInfo.details.fare.clientFare.holidayFare.hours
              : b.requestInfo.details.fare.employeeFare.holidayFare.hours;

          if (ascending) {
            return aTHF.compareTo(bTHF);
          }
          return bTHF.compareTo(aTHF);
        });

        return;
      }

      if (columnIndex == 7) {
        filteredPayments.sort((a, b) {
          double aVHF = widget.isClient
              ? a.requestInfo.details.fare.clientFare.holidayFare.totalToPay
              : a.requestInfo.details.fare.employeeFare.holidayFare.totalToPay;

          double bVHF = widget.isClient
              ? b.requestInfo.details.fare.clientFare.holidayFare.totalToPay
              : b.requestInfo.details.fare.employeeFare.holidayFare.totalToPay;

          if (ascending) {
            return aVHF.compareTo(bVHF);
          }
          return bVHF.compareTo(aVHF);
        });

        return;
      }

      if (columnIndex == 8) {
        filteredPayments.sort((a, b) {
          double aTHDI = widget.isClient
              ? a.requestInfo.details.fare.clientFare.dynamicFare.hours
              : a.requestInfo.details.fare.employeeFare.dynamicFare.hours;

          double bTHDI = widget.isClient
              ? b.requestInfo.details.fare.clientFare.dynamicFare.hours
              : b.requestInfo.details.fare.employeeFare.dynamicFare.hours;

          if (ascending) {
            return aTHDI.compareTo(bTHDI);
          }
          return bTHDI.compareTo(aTHDI);
        });

        return;
      }
      if (columnIndex == 9) {
        filteredPayments.sort((a, b) {
          double aVHDI = widget.isClient
              ? a.requestInfo.details.fare.clientFare.dynamicFare.totalToPay
              : a.requestInfo.details.fare.employeeFare.dynamicFare.totalToPay;

          double bVHDI = widget.isClient
              ? b.requestInfo.details.fare.clientFare.dynamicFare.totalToPay
              : b.requestInfo.details.fare.employeeFare.dynamicFare.totalToPay;

          if (ascending) {
            return aVHDI.compareTo(bVHDI);
          }
          return bVHDI.compareTo(aVHDI);
        });

        return;
      }

      if (columnIndex == 10) {
        filteredPayments.sort((a, b) {
          double aTotalHours = a.requestInfo.details.totalHours;

          double bTotalHours = b.requestInfo.details.totalHours;

          if (ascending) {
            return aTotalHours.compareTo(bTotalHours);
          }
          return bTotalHours.compareTo(aTotalHours);
        });

        return;
      }

      if (columnIndex == 11) {
        filteredPayments.sort((a, b) {
          double aTotalToPay = widget.isClient
              ? a.requestInfo.details.fare.totalClientPays
              : a.requestInfo.details.fare.totalToPayEmployee;

          double bTotalToPay = widget.isClient
              ? b.requestInfo.details.fare.totalClientPays
              : b.requestInfo.details.fare.totalToPayEmployee;

          if (ascending) {
            return aTotalToPay.compareTo(bTotalToPay);
          }
          return bTotalToPay.compareTo(aTotalToPay);
        });

        return;
      }
    });
  }

  List<DataColumn2> getColumns() {
    List<DataColumn2> columns = [];
    for (var i = 0; i < headers.length; i++) {
      columns.add(
        DataColumn2(
          onSort: _sort,
          label: CustomTooltip(
            message: headers[i].split("/")[1],
            child: Text(
              headers[i].split("/")[0],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          size: ColumnSize.M,
        ),
      );
    }
    return columns;
  }

  void filterPayments(String query) {
    String finalQuery = query.toLowerCase();
    filteredPayments.clear();
    // paymentsProvider.filteredPayments.clear();
    if (query.isNotEmpty) {
      filteredPayments.clear();
      // paymentsProvider.filteredPayments.clear();
    }

    for (Payment payment in widget.payments) {
      int statusRequest = payment.requestInfo.details.status;
      if (statusRequest == 1 ||
          statusRequest == 2 ||
          statusRequest == 3 ||
          statusRequest == 4) {
        RequestEmployeeInfo employeeInfo = payment.requestInfo.employeeInfo;

        String name = CodeUtils.getFormatedName(
                employeeInfo.names, employeeInfo.lastNames)
            .toLowerCase();
        String job = payment.requestInfo.details.job["name"].toLowerCase();
        String startDate =
            CodeUtils.formatDate(payment.requestInfo.details.startDate);
        String endDate =
            CodeUtils.formatDate(payment.requestInfo.details.endDate);
        String status =
            CodeUtils.getStatusName(payment.requestInfo.details.status)
                .toLowerCase();

        if (kDebugMode) print(finalQuery);

        if (name.contains(finalQuery)) {
          filteredPayments.add(payment);
          // paymentsProvider.filteredPayments.add(payment);
          continue;
        }
        if (job.contains(finalQuery)) {
          filteredPayments.add(payment);
          // paymentsProvider.filteredPayments.add(payment);
          continue;
        }
        if (startDate.contains(finalQuery)) {
          filteredPayments.add(payment);
          // paymentsProvider.filteredPayments.add(payment);
          continue;
        }
        if (endDate.contains(finalQuery)) {
          filteredPayments.add(payment);
          // paymentsProvider.filteredPayments.add(payment);
          continue;
        }
        if (status.contains(finalQuery)) {
          filteredPayments.add(payment);
          // paymentsProvider.filteredPayments.add(payment);
          continue;
        }
      }
    }
    // paymentsProvider.updateFilteredPayments(paymentsProvider.filteredPayments);
    // paymentsProvider.dataExport(paymentsProvider.paymentRangeResult, true);
    setState(() {
      if (kDebugMode) {
        print("modified");
        print(filteredPayments.toString());
      }
    });
  }

  getTableHeader(bool isDesktop, String title) {
    return OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      overflowAlignment: OverflowBarAlignment.start,
      overflowSpacing: 10,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: widget.screenSize.blockWidth >= 920
                  ? widget.screenSize.blockWidth * 0.3
                  : widget.screenSize.blockWidth,
              margin: const EdgeInsets.only(top: 0, bottom: 20, right: 10),
              child: Wrap(children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize:
                          (isDesktop || widget.screenSize.blockWidth >= 580)
                              ? 19
                              : 15,
                      fontWeight: FontWeight.bold),
                ),
              ]),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: (isDesktop || widget.screenSize.blockWidth >= 580)
                      ? widget.screenSize.width * 0.3
                      : widget.screenSize.blockWidth,
                  height: widget.screenSize.height * 0.055,
                  margin: EdgeInsets.only(
                      bottom: 20, top: (filteredPayments.isNotEmpty) ? 20 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(0, 2),
                        color: Colors.black26,
                        blurRadius: 2,
                      )
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.search),
                      hintText: "Buscar",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onChanged: filterPayments,
                  ),
                ),
                if (filteredPayments.isNotEmpty)
                  ExportToExcelBtn(
                    title: "Exportar listado a Excel",
                    paymentsProvider: paymentsProvider,
                    excelParams: ExportPaymentsToExcelParams(
                      isIndividual: true,
                      fileName: "listado_de_pagos_individual",
                      isClient: widget.isClient,
                      payments: paymentsProvider
                          .paymentRangeResult.individualPayments,
                      totalHours:
                          paymentsProvider.paymentRangeResult.totalHours,
                      totalHoursNormal:
                          paymentsProvider.paymentRangeResult.totalHoursNormal,
                      totalHoursDynamic:
                          paymentsProvider.paymentRangeResult.totalHoursDynamic,
                      totalHoursHoliday:
                          paymentsProvider.paymentRangeResult.totalHoursHoliday,
                      totalToPay: widget.isClient
                          ? paymentsProvider.paymentRangeResult.totalClientPays
                          : paymentsProvider
                              .paymentRangeResult.totalToPayEmployee,
                    ),
                    isSelectedClient: widget.isSelectedClient,
                  ),
                const SizedBox(height: 10)
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant IndividualPaymentsDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kDebugMode) print("Widget changes");
    filteredPayments.clear();

    for (var element in widget.payments) {
      int statusRequest = element.requestInfo.details.status;

      if (statusRequest == 0 ||
          statusRequest == 1 ||
          statusRequest == 2 ||
          statusRequest == 3 ||
          statusRequest == 4) {
        filteredPayments.add(element);
        // paymentsProvider.filteredPayments.add(element);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isLoaded) {
      isLoaded = true;
      paymentsProvider = Provider.of<PaymentsProvider>(context);
      filteredPayments.clear();

      for (var element in widget.payments) {
        int statusRequest = element.requestInfo.details.status;
        if (statusRequest == 0 ||
            statusRequest == 1 ||
            statusRequest == 2 ||
            statusRequest == 3 ||
            statusRequest == 4) {
          filteredPayments.add(element);
          paymentsProvider.filteredPayments.add(element);
        }
      }
    }
  }
}

class PaymentsTableSource extends DataTableSource {
  final List<Payment> payments;
  final bool isClient;
  PaymentsTableSource(this.payments, this.isClient);

  @override
  DataRow? getRow(int index) {
    return DataRow.byIndex(
      cells: getCells(index),
      index: index,
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => payments.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    Payment payment = payments[index];
    return <DataCell>[
      DataCell(
        Text(
          CodeUtils.getFormatedName(
            payment.requestInfo.employeeInfo.names,
            payment.requestInfo.employeeInfo.lastNames,
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          payment.requestInfo.details.job["name"],
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.formatDate(payment.requestInfo.details.startDate),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.formatDate(payment.requestInfo.details.endDate),
          style: const TextStyle(fontSize: 13),
        ),
      ),

      /*normal fare*/
      DataCell(
        Text(
          isClient
              ? payment.requestInfo.details.fare.clientFare.normalFare.hours
                  .toString()
              : payment.requestInfo.details.fare.employeeFare.normalFare.hours
                  .toString(),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          isClient
              ? CodeUtils.formatMoney(payment
                  .requestInfo.details.fare.clientFare.normalFare.totalToPay)
              : CodeUtils.formatMoney(payment
                  .requestInfo.details.fare.employeeFare.normalFare.totalToPay),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      /*holiday fare*/
      DataCell(
        Text(
          isClient
              ? payment.requestInfo.details.fare.clientFare.holidayFare.hours
                  .toString()
              : payment.requestInfo.details.fare.employeeFare.holidayFare.hours
                  .toString(),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          isClient
              ? CodeUtils.formatMoney(payment
                  .requestInfo.details.fare.clientFare.holidayFare.totalToPay)
              : CodeUtils.formatMoney(payment.requestInfo.details.fare
                  .employeeFare.holidayFare.totalToPay),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      /*dynamic fare*/
      DataCell(
        Text(
          isClient
              ? payment.requestInfo.details.fare.clientFare.dynamicFare.hours
                  .toString()
              : payment.requestInfo.details.fare.employeeFare.dynamicFare.hours
                  .toString(),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          isClient
              ? CodeUtils.formatMoney(payment
                  .requestInfo.details.fare.clientFare.dynamicFare.totalToPay)
              : CodeUtils.formatMoney(payment.requestInfo.details.fare
                  .employeeFare.dynamicFare.totalToPay),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      /*Resume*/
      DataCell(
        Text(
          payment.requestInfo.details.totalHours.toString(),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          isClient
              ? CodeUtils.formatMoney(
                  payment.requestInfo.details.fare.totalClientPays)
              : CodeUtils.formatMoney(
                  payment.requestInfo.details.fare.totalToPayEmployee),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      // DataCell(
      //   Text(
      //     payment.requestInfo.id,
      //     style: const TextStyle(fontSize: 13),
      //   ),
      // ),
    ];
  }
}
