import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/use_cases_params/export_payments_excel_params.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/domain/entities/payment_entity.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:provider/provider.dart';

import '../../../../../../../core/utils/code/code_utils.dart';
import '../../../../../../core/utils/ui/widgets/general/data_table_from_responsive.dart';
import '../../export_to_excel_button.dart';

class GroupPaymentsDataTable extends StatefulWidget {
  final List<Payment> payments;
  final ScreenSize screenSize;
  final bool isClient;

  const GroupPaymentsDataTable(
      {required this.payments,
      required this.screenSize,
      required this.isClient,
      Key? key})
      : super(key: key);

  @override
  State<GroupPaymentsDataTable> createState() => _GroupPaymentsDataTableState();
}

class _GroupPaymentsDataTableState extends State<GroupPaymentsDataTable> {
  bool isLoaded = false;
  List<Payment> filteredPayments = [];
  List<Payment> filteredPaymentsExcel = [];

  TextEditingController searchController = TextEditingController();
  late PaymentsProvider paymentsProvider;
  List<String> headers = const [
    "Nombre",
    "Total horas - normal",
    "Total horas - festivo",
    "Total horas - dinámica",
    "Total horas",
    "Total a pagar",
    "Turnos",
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
      for (var groupPayment in filteredPayments) {
        dataTableFromResponsive.add([
          "Nombre-${CodeUtils.getFormatedName(
            groupPayment.requestInfo.employeeInfo.names,
            groupPayment.requestInfo.employeeInfo.lastNames,
          )}",
          "Total horas normal-${groupPayment.totalHoursNormal.toString()}",
          "Total horas festivo-${groupPayment.totalHoursHoliday.toString()}",
          "Total horas dinámica-${groupPayment.totalHoursDynamic.toString()}",
          "Total horas-${groupPayment.totalHours.toString()}",
          "Total a pagar-${widget.isClient ? CodeUtils.formatMoney(groupPayment.totalClientPays) : CodeUtils.formatMoney(groupPayment.totalToPayEmployee)}",
          "Turnos-",
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
          getTableHeader(isDesktop, "Listado de pagos - resumen"),
          SizedBox(
            height: filteredPayments.isEmpty
                ? widget.screenSize.height * 0.3
                : widget.screenSize.height * 0.7,
            width: widget.screenSize.blockWidth >= 920
                ? widget.screenSize.blockWidth * 0.9
                : widget.screenSize.blockWidth,
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
                        headers,
                        paymentsProvider,
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
                      type: 'group-payment',
                      isClient: widget.isClient,
                      listPayment: filteredPayments,
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
          double aTHN = a.totalHoursNormal;

          double bTHN = b.totalHoursNormal;

          if (ascending) {
            return aTHN.compareTo(bTHN);
          }
          return bTHN.compareTo(aTHN);
        });

        return;
      }

      if (columnIndex == 2) {
        filteredPayments.sort((a, b) {
          double aTHF = a.totalHoursHoliday;

          double bTHF = b.totalHoursHoliday;

          if (ascending) {
            return aTHF.compareTo(bTHF);
          }
          return bTHF.compareTo(aTHF);
        });

        return;
      }

      if (columnIndex == 3) {
        filteredPayments.sort((a, b) {
          double aTHDI = a.totalHoursDynamic;

          double bTHDI = b.totalHoursDynamic;

          if (ascending) {
            return aTHDI.compareTo(bTHDI);
          }
          return bTHDI.compareTo(aTHDI);
        });

        return;
      }

      if (columnIndex == 4) {
        filteredPayments.sort((a, b) {
          double aTotalHours = a.totalHours;
          double bTotalHours = b.totalHours;

          if (ascending) {
            return aTotalHours.compareTo(bTotalHours);
          }
          return bTotalHours.compareTo(aTotalHours);
        });

        return;
      }

      if (columnIndex == 5) {
        filteredPayments.sort((a, b) {
          double aTotalToPay =
              widget.isClient ? a.totalClientPays : a.totalToPayEmployee;

          double bTotalToPay =
              widget.isClient ? b.totalClientPays : b.totalToPayEmployee;

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
          label: Text(
            headers[i],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          size: ColumnSize.L,
        ),
      );
    }
    return columns;
  }

  void filterPayments(String query) {
    String finalQuery = query.toLowerCase();
    if (query.isNotEmpty) {
      filteredPayments.clear();
      filteredPaymentsExcel.clear();
      // for (Payment payment in widget.payments) {
      //   int statusRequest = payment.requestInfo.details.status;
      //   if (statusRequest == 4) {
      //     filteredPaymentsExcel.add(payment);
      //     setState(() {
      //       if (kDebugMode) print("modified");
      //     });
      //     return;
      //   }
      // }

      // for (Payment payment in widget.payments.toSet()) {
      //   int statusRequest = payment.requestInfo.details.status;
      //   if (statusRequest == 4) {
      //     filteredPayments.add(payment);
      //     setState(() {
      //       if (kDebugMode) print("modified");
      //     });
      //     return;
      //   }
      // }
    }

    filteredPayments.clear();
    filteredPaymentsExcel.clear();

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
          filteredPaymentsExcel.add(payment);

          continue;
        }
        if (job.contains(finalQuery)) {
          filteredPayments.add(payment);
          filteredPaymentsExcel.add(payment);

          continue;
        }
        if (startDate.contains(finalQuery)) {
          filteredPayments.add(payment);
          filteredPaymentsExcel.add(payment);

          continue;
        }
        if (endDate.contains(finalQuery)) {
          filteredPayments.add(payment);
          filteredPaymentsExcel.add(payment);

          continue;
        }
        if (status.contains(finalQuery)) {
          filteredPayments.add(payment);
          filteredPaymentsExcel.add(payment);

          continue;
        }
      }
    }
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
      overflowAlignment: OverflowBarAlignment.end,
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
              child: Text(
                title,
                style: TextStyle(
                    fontSize: (isDesktop || widget.screenSize.blockWidth >= 580)
                        ? 19
                        : 15,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: (isDesktop || widget.screenSize.blockWidth >= 580)
                      ? widget.screenSize.width * 0.3
                      : widget.screenSize.blockWidth,
                  margin: EdgeInsets.only(
                      bottom: 20, top: (filteredPayments.isNotEmpty) ? 20 : 0),
                  height: widget.screenSize.height * 0.055,
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
                      isIndividual: false,
                      fileName: "listado_de_pagos_resumen",
                      isClient: widget.isClient,
                      totalToPay: widget.isClient
                          ? paymentsProvider.paymentRangeResult.totalClientPays
                          : paymentsProvider
                              .paymentRangeResult.totalToPayEmployee,
                      payments:
                          paymentsProvider.paymentRangeResult.groupPayments,
                      totalHours:
                          paymentsProvider.paymentRangeResult.totalHours,
                      totalHoursNormal:
                          paymentsProvider.paymentRangeResult.totalHoursNormal,
                      totalHoursHoliday:
                          paymentsProvider.paymentRangeResult.totalHoursHoliday,
                      totalHoursDynamic:
                          paymentsProvider.paymentRangeResult.totalHoursDynamic,
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            )
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant GroupPaymentsDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    filteredPaymentsExcel.clear();
    filteredPayments.clear();
    for (var element in widget.payments) {
      int statusRequest = element.requestInfo.details.status;
      if (statusRequest == 1 ||
          statusRequest == 2 ||
          statusRequest == 3 ||
          statusRequest == 4) {
        filteredPaymentsExcel.add(element);
      }
      filteredPayments;
    }
    for (var element in widget.payments) {
      int statusRequest = element.requestInfo.details.status;
      if (statusRequest == 1 ||
          statusRequest == 2 ||
          statusRequest == 3 ||
          statusRequest == 4) {
        filteredPayments.add(element);
        filteredPaymentsExcel.add(element);
      }
      filteredPayments;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isLoaded) {
      isLoaded = true;
      paymentsProvider = Provider.of<PaymentsProvider>(context);
      filteredPayments.clear();
      filteredPaymentsExcel.clear();
      for (var element in widget.payments) {
        int statusRequest = element.requestInfo.details.status;
        if (statusRequest == 1 ||
            statusRequest == 2 ||
            statusRequest == 3 ||
            statusRequest == 4) {
          filteredPayments.add(element);
        }
      }

      //   for (var element in widget.payments) {
      //     int statusRequest = element.requestInfo.details.status;
      //     if (statusRequest == 1 ||
      //         statusRequest == 2 ||
      //         statusRequest == 3 ||
      //         statusRequest == 4) {
      //       filteredPayments.add(element);
      //     }
      //   }
    }
  }
}

class PaymentsTableSource extends DataTableSource {
  final List<Payment> payments;
  final List<dynamic> headers;
  final PaymentsProvider provider;
  final bool isClient;

  PaymentsTableSource(
    this.payments,
    this.headers,
    this.provider,
    this.isClient,
  );

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
    Payment paymentDetails = payments[index];
    payments[index].requestInfo.clientInfo.name;
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
      /*Normal Fare*/
      DataCell(
        Text(
          payment.totalHoursNormal.toString(),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      /*Holiday Fare*/
      DataCell(
        Text(
          payment.totalHoursHoliday.toString(),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      /*Dynamic Fare*/
      DataCell(
        Text(
          payment.totalHoursDynamic.toString(),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      /*Resume*/
      DataCell(
        Text(
          payment.totalHours.toString(),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          isClient
              ? CodeUtils.formatMoney(payment.totalClientPays)
              : CodeUtils.formatMoney(payment.totalToPayEmployee),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataCell(InkWell(
        onTap: () {
          provider.updateSelectedPayment(paymentDetails);
          provider.updateDetailsStatus(true, isClient);
        },
        child: Container(
          padding: const EdgeInsets.all(5),
          child: const Icon(Icons.work),
        ),
      )),
    ];
  }
}
