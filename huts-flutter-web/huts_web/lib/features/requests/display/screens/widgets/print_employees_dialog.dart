// ignore_for_file: depend_on_referenced_packages

import 'dart:typed_data';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/navigation_service.dart';
import '../../../../../core/use_cases_params/excel_params.dart';
import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../core/utils/ui/widgets/general/export_to_excel_btn.dart';
import '../../../../auth/domain/entities/screen_size_entity.dart';
import '../../../../general_info/display/providers/general_info_provider.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../domain/entities/request_entity.dart';

class PrintEmployeesDialog {
  static void show() {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return;

    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: EdgeInsets.zero,
            title: _DialogContent(),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatefulWidget {
  const _DialogContent({Key? key}) : super(key: key);

  @override
  State<_DialogContent> createState() => __DialogContentState();
}

class __DialogContentState extends State<_DialogContent> {
  bool isDialogLoaded = false;
  late ScreenSize screenSize;
  DateTime? selectedDate;
  Map<String, dynamic> dateEvents = {};
  late GetRequestsProvider requestsProvider;
  List<String> eventsIds = [];
  bool allEventsPrint = false;
  List<Request> excelRequests = [];
  List<GlobalKey<State<StatefulWidget>>> toPrintKeys = <GlobalKey>[];
  List<GlobalKey<State<StatefulWidget>>> allKeys = <GlobalKey>[];
  bool canPrint = false;
  String type = '';
  List<Request> listRequest = [];
  @override
  void didChangeDependencies() {
    if (isDialogLoaded) return;
    isDialogLoaded = true;
    requestsProvider = Provider.of<GetRequestsProvider>(context);
    type = requestsProvider.clientRequestsType;
    listRequest = requestsProvider.clientFilteredRequests;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    // dateEvents = requestsProvider.dateEvents;
    return Container(
      width: 1400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          _buildBody(),
          _buildHeader(),
          _buildFooter(),
        ],
      ),
    );
  }

  Future<void> _printDataTables() async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
      final doc = pw.Document();
      final List<WidgetWrapper> images = [];
      await Future.forEach(
        toPrintKeys,
        (element) async {
          final image = await WidgetWrapper.fromKey(
            key: element,
            pixelRatio: 2.0,
          );
          images.add(image);
        },
      );

      doc.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                ...images.map((e) => pw.Image(e)),
              ],
            );
          },
        ),
      );

      Uint8List pdfBytes = await doc.save();

      return pdfBytes;
    });
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
              onTap: () {
                requestsProvider.dateEvents.clear();
                excelRequests.clear();
                allKeys.clear();
                toPrintKeys.clear();
                type = type != 'generales' ? 'generales' : 'by-request';
                Navigator.of(context).pop();
              },
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Imprimir colaboradores",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildBody() {
    return Container(
      height: screenSize.height * 0.5,
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      margin: EdgeInsets.symmetric(
        vertical: screenSize.height * 0.09,
      ),
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: type == 'generales'
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 15),
                  _buildDateField(),
                  if (selectedDate != null ||
                      requestsProvider.dateEvents.isNotEmpty)
                    Row(
                      children: [
                        const Text(
                          'Seleccionar todo',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Checkbox(
                          value: allEventsPrint,
                          onChanged: (bool? value) {
                            if (value == null) return;

                            if (value) {
                              toPrintKeys = [...allKeys];
                              excelRequests.clear();
                              for (Map<String, dynamic> event
                                  in requestsProvider.dateEvents.values) {
                                excelRequests.addAll(event["requests"]);
                              }
                            } else {
                              toPrintKeys.clear();
                              excelRequests.clear();
                            }
                            allEventsPrint = value;

                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 15),
                  (selectedDate == null || requestsProvider.dateEvents.isEmpty)
                      ? buildEmptyWidget()
                      : Column(
                          children: List.generate(
                            allKeys.length,
                            (keyIndex) {
                              if (keyIndex >=
                                  requestsProvider.dateEvents.values.length) {
                                return const SizedBox();
                              }

                              Map<String, dynamic> event = requestsProvider
                                  .dateEvents.values
                                  .toList()[keyIndex];

                              return buildTable(event, allKeys[keyIndex]);
                            },
                          ),
                        ),
                ],
              )
            : requestsProvider.clientFilteredRequests.isEmpty
                ? buildEmptyWidget()
                : _buildTableRequest(
                    requestsProvider.clientFilteredRequests,
                  ),
      ),
    );
  }

  Column _buildTableRequest(List<Request> requests) {
    allKeys.clear();
    toPrintKeys.clear();
    allKeys.add(GlobalKey<State<StatefulWidget>>());
    toPrintKeys.add(allKeys.first);
    return Column(
      children: [
        const Text('Colaboradores para hoy'),
        const SizedBox(height: 20),
        SizedBox(
          height: screenSize.height + requests.length * 25,
          child: RepaintBoundary(
            key: allKeys.first,
            child: DataTable2(
              columns: buildColumns(),
              rows: buildRowsRequest(requests),
            ),
          ),
        ),
      ],
    );
  }

  Container buildTable(Map<String, dynamic> event, GlobalKey key) {
    bool isSelected =
        toPrintKeys.any((element) => element.toString() == key.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isSelected ? 'Seleccionado' : 'No seleccionado',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (bool? newValue) {
                  if (newValue == null) return;

                  if (newValue) {
                    toPrintKeys.add(key);
                    excelRequests.addAll(event["requests"]);
                  } else {
                    toPrintKeys.removeWhere(
                        (element) => element.toString() == key.toString());

                    excelRequests.removeWhere(
                        (element) => element.eventId == event["id"]);
                  }

                  if (toPrintKeys.length == allKeys.length) {
                    allEventsPrint = true;

                    excelRequests.clear();
                    for (Map<String, dynamic> event
                        in requestsProvider.dateEvents.values) {
                      excelRequests.addAll(event["requests"]);
                    }
                  }

                  setState(() {});
                },
              ),
            ],
          ),
          RepaintBoundary(
            key: key,
            child: _buildDetailsEvent(event),
          ),
        ],
      ),
    );
  }

  Column _buildDetailsEvent(Map<String, dynamic> event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Evento: ${event["name"]}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          "Total colaboradores: ${event["requests"].length}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: ((45 * event["requests"].length).toDouble()) + 100,
          child: DataTable2(
            dataRowHeight: 45,
            border: TableBorder.all(
              width: 0.5,
              color: Colors.grey,
            ),
            columns: buildColumns(),
            rows: buildRows(event),
          ),
        ),
      ],
    );
  }

  List<DataColumn2> buildColumns() {
    return List<DataColumn2>.from(const [
      DataColumn2(
        label: Text(
          "Nombres",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
          label: Text(
        "Apellidos",
        style: TextStyle(fontWeight: FontWeight.bold),
      )),
      DataColumn2(
          label: Text(
        "Cargo",
        style: TextStyle(fontWeight: FontWeight.bold),
      )),
      DataColumn2(
          label: Text(
        "Fecha inicio",
        style: TextStyle(fontWeight: FontWeight.bold),
      )),
      DataColumn2(
          label: Text(
        "Fecha fin",
        style: TextStyle(fontWeight: FontWeight.bold),
      )),
      DataColumn2(
          label: Text(
        "Documento",
        style: TextStyle(fontWeight: FontWeight.bold),
      )),
      DataColumn2(
          label: Text(
        "Manip. Alim",
        style: TextStyle(fontWeight: FontWeight.bold),
      )),
    ]);
  }

  List<DataRow> buildRows(Map<String, dynamic> event) {
    List<DataRow> rows = [];
    for (Request request in event["requests"]) {
      rows.add(
        DataRow2(
          cells: <DataCell>[
            DataCell(Text((request.employeeInfo.id == "")
                ? "Sin asignar"
                : request.employeeInfo.names)),
            DataCell(Text((request.employeeInfo.id == "")
                ? "Sin asignar"
                : request.employeeInfo.lastNames)),
            DataCell(Text((request.employeeInfo.id == "")
                ? "Sin asignar"
                : request.details.job["name"])),
            DataCell(Text(CodeUtils.formatDate(request.details.startDate))),
            DataCell(Text(CodeUtils.formatDate(request.details.endDate))),
            DataCell(Text((request.employeeInfo.id == "")
                ? "Sin asignar"
                : request.employeeInfo.docNumber)),
            DataCell(
              (request.employeeInfo.id == "" ||
                      request.details.job["food_doc"] == "")
                  ? const Text("Sin documento")
                  : InkWell(
                      onTap: () =>
                          CodeUtils.launchURL(request.details.job["food_doc"]),
                      child: const Text(
                        "Ver documento",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.blue,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return rows;
  }

  SizedBox buildEmptyWidget() {
    return SizedBox(
      height: screenSize.height * 0.3,
      width: double.infinity,
      child: const Center(
        child: Text(
          "No hay información",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Column _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Día a consultar",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        InkWell(
          onTap: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(
                const Duration(days: 360),
              ),
              lastDate: DateTime.now().add(
                const Duration(days: 360),
              ),
            );

            if (pickedDate == null) return;
            selectedDate = pickedDate;
            DateTime startDate = DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
            );

            DateTime endDate = DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
              23,
              59,
              59,
            );

            allKeys.clear();
            toPrintKeys.clear();

            if (mounted) {
              requestsProvider.dateEvents = {
                ...await requestsProvider.getClientPrintEvents(
                  Provider.of<AuthProvider>(context, listen: false)
                      .webUser
                      .company
                      .accountInfo["id"],
                  startDate,
                  endDate,
                  context,
                )
              };

              if (requestsProvider.dateEvents.isEmpty) return;

              requestsProvider.dateEvents.forEach(
                (key, value) {
                  allKeys.add(GlobalKey<State<StatefulWidget>>());
                },
              );

              setState(() {});
            }
          },
          child: Container(
            height: 50,
            width: double.infinity,
            margin: EdgeInsets.only(
              top: screenSize.height * 0.01,
              bottom: screenSize.height * 0.02,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: UiVariables.lightBlueColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                (selectedDate != null)
                    ? CodeUtils.formatDateWithoutHour(selectedDate!)
                    : "Elegir fecha",
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Positioned _buildFooter() {
    canPrint = (selectedDate != null && toPrintKeys.isNotEmpty) ||
        (requestsProvider.clientFilteredRequests.isNotEmpty &&
            type != 'generales');
    if (type != 'generales' &&
        requestsProvider.clientFilteredRequests.isNotEmpty &&
        excelRequests.isEmpty) {
      excelRequests.addAll(requestsProvider.clientFilteredRequests);
    }

    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 200,
            padding: const EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
              left: 8.0,
              right: 14.0,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: (canPrint)
                  ? ExportToExcelBtn(
                      params: _getExcelParams(excelRequests),
                      title: 'Exportar Excel',
                      isPrintingEmployees: true,
                    )
                  : const SizedBox(),
            ),
          ),
          Container(
            width: 200,
            padding: const EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
              left: 8.0,
              right: 14.0,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () async {
                  if (!canPrint) return;
                  await _printDataTables();
                },
                child: Container(
                  width: 150,
                  height: 35,
                  decoration: BoxDecoration(
                    color: canPrint
                        ? UiVariables.primaryColor.withOpacity(0.8)
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Imprimir",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ExcelParams _getExcelParams(List<Request> requests) {
    return ExcelParams(
      headers: [
        {
          "key": "employee_name",
          "display_name": "Nombre colaborador",
          "width": 170,
        },
        {
          "key": "employee_lastName",
          "display_name": "Apellido colaborador",
          "width": 170,
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
        {
          "key": "document",
          "display_name": "Documento",
          "width": 150,
        },
      ],
      data: List.generate(
        requests.length,
        (index) {
          Request request = requests[index];

          return {
            "employee_name": request.employeeInfo.names != ''
                ? request.employeeInfo.names
                : 'Sin colaborador asignado',
            "employee_lastName": request.employeeInfo.lastNames != ''
                ? request.employeeInfo.lastNames
                : 'Sin colaborador asignado',
            "job": request.details.job['name'],
            "start_date": CodeUtils.formatDate(request.details.startDate),
            "end_date": CodeUtils.formatDate(request.details.endDate),
            "event_name": request.eventName,
            "document": request.employeeInfo.id == "" ||
                    request.details.job["food_doc"] == ""
                ? "Sin documento"
                : 'Si tiene el documento',
          };
        },
      ),
      otherInfo: {},
      fileName:
          "listado_de_colaboradores${CodeUtils.formatDateWithoutHour(requests[0].details.startDate)}",
    );
  }

  List<DataRow> buildRowsRequest(List<Request> requests) {
    List<DataRow> row = [];
    for (Request request in requests) {
      row.add(
        DataRow2(
          cells: <DataCell>[
            DataCell(Text((request.employeeInfo.id == "")
                ? "Sin asignar"
                : request.employeeInfo.names)),
            DataCell(Text((request.employeeInfo.id == "")
                ? "Sin asignar"
                : request.employeeInfo.lastNames)),
            DataCell(Text((request.employeeInfo.id == "")
                ? "Sin asignar"
                : request.details.job["name"])),
            DataCell(Text(CodeUtils.formatDate(request.details.startDate))),
            DataCell(Text(CodeUtils.formatDate(request.details.endDate))),
            DataCell(Text((request.employeeInfo.id == "")
                ? "Sin asignar"
                : request.employeeInfo.docNumber)),
            DataCell(
              (request.employeeInfo.id == "" ||
                      request.details.job["food_doc"] == "")
                  ? const Text("Sin documento")
                  : InkWell(
                      onTap: () =>
                          CodeUtils.launchURL(request.details.job["food_doc"]),
                      child: const Text(
                        "Ver documento",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.blue,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
    }
    return row;
  }
}
