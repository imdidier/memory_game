import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/domain/entities/payment_entity.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:provider/provider.dart';

import '../../../../../../../core/utils/code/code_utils.dart';
import '../../../../../../core/use_cases_params/excel_params.dart';
import '../../../../../../core/utils/ui/widgets/general/export_to_excel_btn.dart';

class RequestsDetailsDataTable extends StatefulWidget {
  final Payment payment;
  final ScreenSize screenSize;
  final bool isClient;

  const RequestsDetailsDataTable(
      {required this.payment,
      required this.screenSize,
      required this.isClient,
      Key? key})
      : super(key: key);

  @override
  State<RequestsDetailsDataTable> createState() =>
      _RequestsDetailsDataTableState();
}

class _RequestsDetailsDataTableState extends State<RequestsDetailsDataTable> {
  bool isLoaded = false;
  List<Request> filteredRequests = [];
  TextEditingController searchController = TextEditingController();
  late PaymentsProvider paymentsProvider;
  List<String> headers = const [
    "Imagen",
    "Cliente",
    "Cargo",
    "Inicio",
    "Fin",
    "Evento",
    "TH - N",
    "VH - N",
    "TH - F",
    "VH - F",
    "TH - DIN",
    "VH - DIN",
    "T.Horas",
    "T.Pagar",
  ];
  List<List<String>> dataTableFromResponsive = [];

  @override
  Widget build(BuildContext context) {
    dataTableFromResponsive.clear();
    if (filteredRequests.isNotEmpty) {
      for (var requestDetailsEmployee in filteredRequests) {
        dataTableFromResponsive.add([
          "Imagen-${requestDetailsEmployee.clientInfo.imageUrl}",
          "Cliente-${requestDetailsEmployee.clientInfo.name}",
          "Cargo-${requestDetailsEmployee.details.job["name"]}",
          "Fecha inicio-${CodeUtils.formatDate(requestDetailsEmployee.details.startDate)}",
          "Fecha fin-${CodeUtils.formatDate(requestDetailsEmployee.details.endDate)}",
          "Evento-${requestDetailsEmployee.eventName.toString()}}",
          "Total horas normales-${widget.isClient ? requestDetailsEmployee.details.fare.clientFare.normalFare.hours.toString() : requestDetailsEmployee.details.fare.employeeFare.normalFare.hours.toString()}",
          "Valor horas normales-${widget.isClient ? requestDetailsEmployee.details.fare.clientFare.normalFare.totalToPay : requestDetailsEmployee.details.fare.employeeFare.normalFare.totalToPay}",
          "Total horas festivas-${widget.isClient ? requestDetailsEmployee.details.fare.clientFare.holidayFare.hours.toString() : requestDetailsEmployee.details.fare.employeeFare.holidayFare.hours.toString()}",
          "Valor horas festivas-${widget.isClient ? requestDetailsEmployee.details.fare.clientFare.holidayFare.hours.toString() : requestDetailsEmployee.details.fare.employeeFare.holidayFare.hours.toString()}",
          "Total horas dinámicas-${widget.isClient ? requestDetailsEmployee.details.fare.clientFare.holidayFare.hours.toString() : requestDetailsEmployee.details.fare.employeeFare.holidayFare.hours.toString()}",
          "Valor horas dinámicas-${widget.isClient ? requestDetailsEmployee.details.fare.clientFare.dynamicFare.totalToPay : requestDetailsEmployee.details.fare.employeeFare.dynamicFare.totalToPay}",
          "Total horas-${requestDetailsEmployee.details.totalHours.toString()}",
          "Total a pagar-${widget.isClient ? requestDetailsEmployee.details.fare.totalClientPays : requestDetailsEmployee.details.fare.totalToPayEmployee}",
        ]);
      }
    }
    return Container(
      width: widget.screenSize.blockWidth - 40,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          getTableHeader(""),
          SizedBox(
            height: widget.screenSize.blockWidth <= 920
                ? widget.screenSize.height * 0.9
                : widget.payment.employeeRequests.length < 6
                    ? widget.screenSize.height * 0.7
                    : widget.screenSize.height * 0.9,
            width: widget.screenSize.blockWidth - 40,
            child: widget.screenSize.blockWidth >= 920
                ? SelectionArea(
                    child: PaginatedDataTable2(
                      horizontalMargin: 10,
                      empty: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text("No hay información"),
                        ),
                      ),
                      columnSpacing: 5,
                      columns: getColumns(),
                      source: RequestsTableSource(filteredRequests, headers,
                          paymentsProvider, widget.isClient),
                      wrapInCard: false,
                      minWidth: 1000,
                      // fit: FlexFit.tight,
                    ),
                  )
                : SingleChildScrollView(
                    child: DataTableFromResponsive(
                        listData: dataTableFromResponsive,
                        screenSize: widget.screenSize,
                        type: 'request-details-employee'),
                  ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> getColumns() {
    List<DataColumn> columns = [];
    for (var i = 0; i < headers.length; i++) {
      columns.add(
        DataColumn(
          label: Text(
            headers[i],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return columns;
  }

  void filterPayments(String query) {
    String finalQuery = query.toLowerCase();
    if (query.isEmpty) {
      filteredRequests = [...widget.payment.employeeRequests];
      setState(() {
        if (kDebugMode) print("modified");
      });
      return;
    }

    filteredRequests.clear();
    for (Request request in widget.payment.employeeRequests) {
      RequestEmployeeInfo employeeInfo = request.employeeInfo;
      String name =
          CodeUtils.getFormatedName(employeeInfo.names, employeeInfo.lastNames)
              .toLowerCase();
      String job = request.details.job["name"].toLowerCase();
      String startDate = CodeUtils.formatDate(request.details.startDate);
      String endDate = CodeUtils.formatDate(request.details.endDate);
      String status =
          CodeUtils.getStatusName(request.details.status).toLowerCase();

      if (kDebugMode) print(finalQuery);

      if (name.contains(finalQuery)) {
        filteredRequests.add(request);
        continue;
      }
      if (job.contains(finalQuery)) {
        filteredRequests.add(request);
        continue;
      }
      if (startDate.contains(finalQuery)) {
        filteredRequests.add(request);
        continue;
      }
      if (endDate.contains(finalQuery)) {
        filteredRequests.add(request);
        continue;
      }
      if (status.contains(finalQuery)) {
        filteredRequests.add(request);
        continue;
      }
    }
    setState(() {
      if (kDebugMode) {
        print("modified");
        print(filteredRequests.toString());
      }
    });
  }

  getTableHeader(String title) {
    return OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      overflowSpacing: 10,
      overflowAlignment: OverflowBarAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: widget.screenSize.width * 0.012,
                      fontWeight: FontWeight.bold),
                ),
              ),
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CodeUtils.getFormatedName(
                      widget.payment.requestInfo.employeeInfo.names,
                      widget.payment.requestInfo.employeeInfo.lastNames,
                    ),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: widget.screenSize.width * 0.014,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: () => context
                        .read<PaymentsProvider>()
                        .updateDetailsStatus(false, widget.isClient),
                    child: Icon(
                      Icons.close,
                      color: UiVariables.primaryColor,
                      size: widget.screenSize.width * 0.018,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                "Total Solicitudes: ${widget.payment.employeeRequests.length}",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: widget.screenSize.width * 0.011,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                "Total horas: ${widget.payment.totalHours}",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: widget.screenSize.width * 0.011,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                "Total a pagar: ${CodeUtils.formatMoney(widget.isClient ? widget.payment.totalClientPays : widget.payment.totalToPayEmployee)}",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: widget.screenSize.width * 0.011,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: widget.screenSize.blockWidth >= 920
                  ? widget.screenSize.width * 0.3
                  : widget.screenSize.blockWidth,
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
                decoration: InputDecoration(
                  helperStyle: TextStyle(
                      fontSize: widget.screenSize.blockWidth >= 920 ? 16 : 12),
                  suffixIcon: const Icon(Icons.search),
                  hintText: "Buscar",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onChanged: filterPayments,
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            ExportToExcelBtn(
              title: 'Exportar listado a excel',
              params: _getExcelParams(filteredRequests),
            ),
          ],
        )
      ],
    );
  }

  ExcelParams _getExcelParams(List<Request> requests) {
    bool isAdmin =
        context.read<AuthProvider>().webUser.accountInfo.type == 'admin';
    return ExcelParams(
      headers: [
        if (isAdmin)
          {
            "key": "client_name",
            "display_name": "Nombre cliente",
            "width": 150,
          },
        {
          "key": "employee",
          "display_name": "Colaborador",
          "width": 200,
        },
        {
          "key": "job",
          "display_name": "Cargo",
          "width": 250,
        },
        {
          "key": "start_date",
          "display_name": "Fecha inicio",
          "width": 130,
        },
        {
          "key": "end_date",
          "display_name": "Fecha fin",
          "width": 130,
        },
        {
          "key": "event_name",
          "display_name": "Evento",
          "width": 380,
        },
        if (requests.any(
            (element) => element.details.fare.clientFare.normalFare.hours != 0))
          {
            "key": "total_hours_normal",
            "display_name": "Total horas normales",
            "width": 150,
          },
        if (requests.any((element) =>
            element.details.fare.clientFare.holidayFare.hours != 0))
          {
            "key": "total_hours_holiday",
            "display_name": "Total horas festivas",
            "width": 150,
          },
        if (requests.any((element) =>
            element.details.fare.clientFare.dynamicFare.hours != 0))
          {
            "key": "total_hours_dynamic",
            "display_name": "Total horas dinámicas",
            "width": 150,
          },
        if (requests.any(
            (element) => element.details.fare.totalClientNightSurcharge != 0))
          {
            "key": "night_surcharge",
            "display_name": "Recargo nocturno",
            "width": 140,
          },
        {
          "key": "total_hours",
          "display_name": "Total horas",
          "width": 90,
        },
        {
          "key": "total_to_pay",
          "display_name": "Total a pagar",
          "width": 110,
        },
      ],
      data: List.generate(
        requests.length,
        (index) {
          Request request = requests[index];
          return {
            if (isAdmin) "client_name": request.clientInfo.name,
            "employee": CodeUtils.getFormatedName(
                request.employeeInfo.names, request.employeeInfo.lastNames),
            "job": request.details.job["name"],
            "start_date": CodeUtils.formatDate(request.details.startDate),
            "end_date": CodeUtils.formatDate(request.details.endDate),
            "event_name": request.eventName,
            "total_hours_normal": widget.isClient
                ? request.details.fare.clientFare.normalFare.hours
                : request.details.fare.employeeFare.normalFare.hours,
            "total_hours_holiday": widget.isClient
                ? request.details.fare.clientFare.holidayFare.hours
                : request.details.fare.employeeFare.holidayFare.hours,
            "total_hours_dynamic": widget.isClient
                ? request.details.fare.clientFare.dynamicFare.hours
                : request.details.fare.employeeFare.dynamicFare.hours,
            'night_surcharge': widget.isClient
                ? request.details.fare.totalClientNightSurcharge
                : request.details.fare.totalEmployeeNightSurcharge,
            "total_hours": request.details.totalHours,
            "total_to_pay": widget.isClient
                ? request.details.fare.totalClientPays
                : request.details.fare.totalToPayEmployee,
          };
        },
      ),
      otherInfo: {},
      fileName:
          "solicitudes_${requests[0].employeeInfo.names}_${requests[0].employeeInfo.lastNames}",
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isLoaded) {
      isLoaded = true;
      filteredRequests = [...widget.payment.employeeRequests];
      paymentsProvider = Provider.of<PaymentsProvider>(context);
    }
  }
}

class RequestsTableSource extends DataTableSource {
  final List<Request> requests;
  final List<dynamic> headers;
  final PaymentsProvider provider;
  final bool isClient;

  RequestsTableSource(
      this.requests, this.headers, this.provider, this.isClient);

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
  int get rowCount => requests.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    Request request = requests[index];
    return <DataCell>[
      DataCell(
        CircleAvatar(
          backgroundImage: NetworkImage(
            request.clientInfo.imageUrl,
          ),
        ),
      ),
      DataCell(
        Text(
          request.clientInfo.name,
        ),
      ),
      DataCell(
        Text(
          request.details.job["name"],
        ),
      ),
      DataCell(
        Text(
          CodeUtils.formatDate(request.details.startDate),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.formatDate(request.details.endDate),
        ),
      ),
      DataCell(
        Text(
          request.eventName.toString(),
        ),
      ),
      /*normal fare*/
      DataCell(
        Text(
          isClient
              ? request.details.fare.clientFare.normalFare.hours.toString()
              : request.details.fare.employeeFare.normalFare.hours.toString(),
        ),
      ),
      DataCell(
        Text(
          isClient
              ? "${request.details.fare.clientFare.normalFare.totalToPay}"
              : "${request.details.fare.employeeFare.normalFare.totalToPay}",
        ),
      ),
      /*holiday fare*/
      DataCell(
        Text(
          isClient
              ? request.details.fare.clientFare.holidayFare.hours.toString()
              : request.details.fare.employeeFare.holidayFare.hours.toString(),
        ),
      ),
      DataCell(
        Text(
          isClient
              ? "${request.details.fare.clientFare.holidayFare.totalToPay}"
              : "${request.details.fare.employeeFare.holidayFare.totalToPay}",
        ),
      ),
      /*dynamic fare*/
      DataCell(
        Text(
          isClient
              ? request.details.fare.clientFare.dynamicFare.hours.toString()
              : request.details.fare.employeeFare.dynamicFare.hours.toString(),
        ),
      ),
      DataCell(
        Text(
          isClient
              ? "${request.details.fare.clientFare.dynamicFare.totalToPay}"
              : "${request.details.fare.employeeFare.dynamicFare.totalToPay}",
        ),
      ),
      /*Resume*/
      DataCell(
        Text(
          request.details.totalHours.toString(),
        ),
      ),
      DataCell(
        Text(
          isClient
              ? "${request.details.fare.totalClientPays}"
              : "${request.details.fare.totalToPayEmployee}",
        ),
      ),
    ];
  }
}
