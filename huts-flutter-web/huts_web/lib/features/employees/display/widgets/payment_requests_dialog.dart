import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_search_bar.dart';

import 'package:provider/provider.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';
import '../../../requests/domain/entities/request_entity.dart';

class PaymentRequestsDialog {
  static Future<void> show(Map<String, dynamic> payment) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: EdgeInsets.zero,
            title: _DialogContent(payment: payment),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatefulWidget {
  final Map<String, dynamic> payment;
  const _DialogContent({required this.payment, Key? key}) : super(key: key);

  @override
  State<_DialogContent> createState() => __DialogContentState();
}

class __DialogContentState extends State<_DialogContent> {
  late ScreenSize screenSize;
  List<Request> filteredRequests = [];

  @override
  void initState() {
    filteredRequests = [...widget.payment["requests"]];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    return Container(
      width: 1200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          _buildBody(),
          _buildHeader(),
        ],
      ),
    );
  }

  Container _buildHeader() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Lista solicitudes: ${widget.payment["employee_info"]["fullname"]}",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  SingleChildScrollView _buildBody() {
    return SingleChildScrollView(
      controller: ScrollController(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        margin: EdgeInsets.symmetric(
          vertical: screenSize.height * 0.09,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRequestsInfo(),
                CustomSearchBar(
                  onChange: (String query) {
                    if (query.isEmpty) {
                      filteredRequests = [...widget.payment["requests"]];
                      setState(() {});
                      return;
                    }
                    filteredRequests.clear();

                    for (Request request in widget.payment["requests"]) {
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
                    }
                    setState(() {});
                  },
                  hint: "Buscar solicitud",
                ),
              ],
            ),
            const SizedBox(height: 15),
            _EmployeeRequests(
              requests: filteredRequests,
              screenSize: screenSize,
            )
          ],
        ),
      ),
    );
  }

  Column _buildRequestsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Total horas: ${widget.payment["total_hours"]}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          "Total a pagar: ${CodeUtils.formatMoney(widget.payment["total_to_pay"])}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _EmployeeRequests extends StatelessWidget {
  final ScreenSize screenSize;
  final List<Request> requests;
  const _EmployeeRequests({
    required this.requests,
    required this.screenSize,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: screenSize.height * 0.58,
      width: screenSize.blockWidth,
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
          source: _RequestsTableSource(requests: requests),
        ),
      ),
    );
  }

  List<DataColumn2> _getColums() {
    return [
      "Cliente",
      "Cargo",
      "Fecha inicio",
      "Fecha fin",
      "T.Horas",
      "Evento",
      "Total cliente",
      "Total.Colab",
    ].map(
      (String header) {
        return DataColumn2(
          label:
              Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    ).toList();
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
        Center(
          child: Text(
            "${request.details.totalHours}",
          ),
        ),
      ),
      DataCell(
        Text(
          request.eventName,
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
