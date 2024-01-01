import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_search_bar.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';

import '../../../../features/auth/domain/entities/screen_size_entity.dart';
import '../../../../features/requests/domain/entities/request_entity.dart';
import '../../../use_cases_params/excel_params.dart';
import '../../../utils/code/code_utils.dart';
import '../../../utils/ui/widgets/general/export_to_excel_btn.dart';

class EmployeeRequests extends StatefulWidget {
  final ScreenSize screenSize;
  final List<Request> requests;
  final bool fromHistoricalDialog;
  const EmployeeRequests(
      {required this.requests,
      required this.screenSize,
      this.fromHistoricalDialog = false,
      Key? key})
      : super(key: key);

  @override
  State<EmployeeRequests> createState() => _EmployeeRequestsState();
}

class _EmployeeRequestsState extends State<EmployeeRequests> {
  List<String> headers = [
    "Cliente",
    "Cargo",
    "F.Inicio",
    "F.Fin",
    "T.Horas",
    "Estado",
    "Evento",
    "T.Cliente",
    "T.Colab",
  ];

  String currentQuery = "";

  List<Request> filteredRequests = [];

  // bool _sortAscending = true;
  // int? _sortColumnIndex;

  @override
  Widget build(BuildContext context) {
    if (currentQuery.isEmpty) {
      filteredRequests = [...widget.requests];
    }

    return SizedBox(
      width: widget.screenSize.blockWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                (filteredRequests.isNotEmpty && !widget.fromHistoricalDialog)
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
            children: [
              if (filteredRequests.isNotEmpty)
                ExportToExcelBtn(
                  params: _getExcelParams(filteredRequests),
                ),
              if (widget.fromHistoricalDialog) const SizedBox(width: 25),
              CustomSearchBar(
                onChange: (String query) {
                  currentQuery = query;
                  if (query.isEmpty) {
                    //filteredRequests = [...widget.requests];
                    setState(() {});
                    return;
                  }
                  filteredRequests.clear();

                  for (Request request in widget.requests) {
                    RequestEmployeeInfo employeeInfo = request.employeeInfo;
                    String name = CodeUtils.getFormatedName(
                            employeeInfo.names, employeeInfo.lastNames)
                        .toLowerCase();
                    String job = request.details.job["name"].toLowerCase();
                    String startDate =
                        CodeUtils.formatDate(request.details.startDate);
                    String endDate =
                        CodeUtils.formatDate(request.details.endDate);

                    String eventName = request.eventName.trim().toLowerCase();
                    String status =
                        CodeUtils.getStatusName(request.details.status)
                            .toLowerCase();

                    if (name.contains(query)) {
                      filteredRequests.add(request);
                      continue;
                    }
                    if (job.contains(query)) {
                      filteredRequests.add(request);
                      continue;
                    }
                    if (startDate.contains(query)) {
                      filteredRequests.add(request);
                      continue;
                    }
                    if (endDate.contains(query)) {
                      filteredRequests.add(request);
                      continue;
                    }
                    if (eventName.contains(query)) {
                      filteredRequests.add(request);
                      continue;
                    }

                    if (status.contains(query)) {
                      filteredRequests.add(request);
                      continue;
                    }
                  }
                  setState(() {});
                },
                hint: "Buscar solicitud",
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: widget.screenSize.height * 0.6,
            child: SelectionArea(
              child: PaginatedDataTable2(
                empty: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text("No hay información"),
                  ),
                ),
                horizontalMargin: 20,
                columnSpacing: 30,
                columns: _getColums(),
                source: _RequestsTableSource(requests: filteredRequests),
                rowsPerPage: 10,
                onRowsPerPageChanged: (value) {},
                availableRowsPerPage: const [10, 20, 50],
                // sortAscending: _sortAscending,
                // sortColumnIndex: _sortColumnIndex,
                // sortArrowIcon: Icons.keyboard_arrow_up,
                // sortArrowAnimationDuration: const Duration(milliseconds: 300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // void _sort(int columnIndex, bool ascending) {
  //   setState(() {
  //     _sortColumnIndex = columnIndex;
  //     _sortAscending = ascending;

  //     if (columnIndex == 0) {
  //       filteredRequests.sort((a, b) {
  //         String aName = a.clientInfo.name.toLowerCase().trim();
  //         String bName = b.clientInfo.name.toLowerCase().trim();

  //         if (ascending) return aName.compareTo(bName);

  //         return bName.compareTo(aName);
  //       });

  //       return;
  //     }
  //     if (columnIndex == 1) {
  //       filteredRequests.sort((a, b) {
  //         String aJob = a.details.job["name"].toLowerCase().trim();
  //         String bJob = b.details.job["name"].toLowerCase().trim();

  //         if (ascending) return aJob.compareTo(bJob);

  //         return bJob.compareTo(aJob);
  //       });

  //       return;
  //     }

  //     if (columnIndex == 2) {
  //       filteredRequests.sort((a, b) {
  //         DateTime aStartDate = a.details.startDate;
  //         DateTime bStartDate = b.details.startDate;

  //         if (ascending) return aStartDate.compareTo(bStartDate);

  //         return bStartDate.compareTo(aStartDate);
  //       });

  //       return;
  //     }

  //     if (columnIndex == 3) {
  //       filteredRequests.sort((a, b) {
  //         DateTime aEndDate = a.details.endDate;
  //         DateTime bEndDate = b.details.endDate;

  //         if (ascending) return aEndDate.compareTo(bEndDate);

  //         return bEndDate.compareTo(aEndDate);
  //       });

  //       return;
  //     }

  //     if (columnIndex == 4) {
  //       filteredRequests.sort((a, b) {
  //         double aHours = a.details.totalHours;
  //         double bHours = b.details.totalHours;

  //         if (ascending) return aHours.compareTo(bHours);

  //         return bHours.compareTo(aHours);
  //       });

  //       return;
  //     }

  //     if (columnIndex == 5) {
  //       filteredRequests.sort((a, b) {
  //         int aStatus = a.details.status;
  //         int bStatus = b.details.status;

  //         if (ascending) return aStatus.compareTo(bStatus);

  //         return bStatus.compareTo(aStatus);
  //       });

  //       return;
  //     }

  //     if (columnIndex == 6) {
  //       filteredRequests.sort((a, b) {
  //         String aName = a.eventName.toLowerCase().trim();
  //         String bName = b.eventName.toLowerCase().trim();

  //         if (ascending) return aName.compareTo(bName);

  //         return bName.compareTo(aName);
  //       });

  //       return;
  //     }
  //     if (columnIndex == 7) {
  //       filteredRequests.sort((a, b) {
  //         double aClientTotal = a.details.fare.totalClientPays;
  //         double bClientTotal = b.details.fare.totalClientPays;

  //         if (ascending) return aClientTotal.compareTo(bClientTotal);

  //         return bClientTotal.compareTo(aClientTotal);
  //       });

  //       return;
  //     }
  //     if (columnIndex == 8) {
  //       filteredRequests.sort((a, b) {
  //         double aEmployeeTotal = a.details.fare.totalClientPays;
  //         double bEmployeeTotal = b.details.fare.totalClientPays;

  //         if (ascending) return aEmployeeTotal.compareTo(bEmployeeTotal);

  //         return bEmployeeTotal.compareTo(aEmployeeTotal);
  //       });

  //       return;
  //     }
  //   });
  // }

  List<DataColumn2> _getColums() {
    return headers.map(
      (String header) {
        return DataColumn2(
          // onSort: _sort,
          size:
              (header == "Cliente" || header == "Estado" || header == "Evento")
                  ? ColumnSize.L
                  : ColumnSize.M,
          label: Text(
            header,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    ).toList();
  }

  ExcelParams _getExcelParams(List<Request> requests) {
    return ExcelParams(
      headers: [
        {
          "key": "client_name",
          "display_name": "Cliente",
          "width": 300,
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
          "key": "total_hours",
          "display_name": "Total horas",
          "width": 90,
        },
        {
          "key": "status",
          "display_name": "Estado",
          "width": 90,
        },
        {
          "key": "event_name",
          "display_name": "Evento",
          "width": 380,
        },
        {
          "key": "client_total",
          "display_name": "Total cliente",
          "width": 110,
        },
        if (requests.any(
            (element) => element.details.fare.totalClientNightSurcharge != 0))
          {
            "key": "total_client_surcharge",
            "display_name": "Total recargo cliente",
            "width": 150,
          },
        if (requests.any(
            (element) => element.details.fare.totalClientNightSurcharge != 0))
          {
            "key": "total_to_pay_client",
            "display_name": "Total a pagar cliente",
            "width": 150,
          },
        {
          "key": "employee_total",
          "display_name": "Total colaborador",
          "width": 130,
        },
        if (requests.any(
            (element) => element.details.fare.totalEmployeeNightSurcharge != 0))
          {
            "key": "employee_surcharge",
            "display_name": "Recargo colaborador",
            "width": 150,
          },
        if (requests.any(
            (element) => element.details.fare.totalEmployeeNightSurcharge != 0))
          {
            "key": "total_to_pay_employee",
            "display_name": "Total a pagar colaborador",
            "width": 170,
          },
      ],
      data: List.generate(requests.length, (index) {
        Request request = requests[index];

        return {
          "client_name": request.clientInfo.name,
          "job": request.details.job["name"],
          "start_date": CodeUtils.formatDate(request.details.startDate),
          "end_date": CodeUtils.formatDate(request.details.endDate),
          "total_hours": request.details.totalHours,
          "status": CodeUtils.getStatusName(request.details.status),
          "event_name": request.eventName,
          'client_total': request.details.fare.totalClientPays -
              request.details.fare.totalClientNightSurcharge,
          'total_client_surcharge':
              request.details.fare.totalClientNightSurcharge,
          'total_to_pay_client': request.details.fare.totalClientPays,
          "employee_total": request.details.fare.totalToPayEmployee -
              request.details.fare.totalEmployeeNightSurcharge,
          'employee_surcharge':
              request.details.fare.totalEmployeeNightSurcharge,
          'total_to_pay_employee': request.details.fare.totalToPayEmployee,
        };
      }),
      otherInfo: {},
      fileName:
          "solicitudes_${requests[0].employeeInfo.names}_${requests[0].employeeInfo.lastNames}",
    );
  }
}

class _RequestsTableSource extends DataTableSource {
  final List<Request> requests;

  _RequestsTableSource({required this.requests});

  @override
  DataRow2? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

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
        CustomTooltip(
          message: request.clientInfo.name,
          child: Text(
            request.clientInfo.name,
          ),
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
        Center(
          child: Text(
            "${request.details.totalHours}",
          ),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CodeUtils.getStatusColor(request.details.status, true),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            CodeUtils.getStatusName(request.details.status),
            style: TextStyle(
              color:
                  (request.details.status == 1) ? Colors.black87 : Colors.white,
            ),
          ),
        ),
      ),
      DataCell(
        CustomTooltip(
          message: request.eventName,
          child: Text(
            request.eventName,
          ),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.formatMoney(request.details.fare.totalClientPays),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.formatMoney(request.details.fare.totalToPayEmployee),
        ),
      ),
    ];
  }
}
