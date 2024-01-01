import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/messages/domain/entities/message_entity.dart';

import '../../../../features/auth/domain/entities/screen_size_entity.dart';
import '../../../utils/code/code_utils.dart';
import '../../../utils/ui/widgets/general/message_attached_widget.dart';

class EmployeeMessages extends StatefulWidget {
  final ScreenSize screenSize;
  final List<HistoricalMessage> messages;
  const EmployeeMessages(
      {required this.messages, required this.screenSize, Key? key})
      : super(key: key);

  @override
  State<EmployeeMessages> createState() => _EmployeeMessagesState();
}

class _EmployeeMessagesState extends State<EmployeeMessages> {
  List<String> headers = [
    "Título",
    "Mensaje",
    "Tipo",
    "Adjuntos",
    "Fecha",
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.screenSize.height * 0.6,
      width: widget.screenSize.blockWidth,
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
          //  rowsPerPage: (widget.messages.length >= 8) ? 8 : widget.messages.length,
          columns: _getColums(),
          source: _MessagesTableSource(messages: widget.messages),
        ),
      ),
    );
  }

  List<DataColumn2> _getColums() {
    return headers.map(
      (String header) {
        return DataColumn2(
          label:
              Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    ).toList();
  }
}

class _MessagesTableSource extends DataTableSource {
  final List<HistoricalMessage> messages;

  _MessagesTableSource({required this.messages});

  @override
  DataRow2? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => messages.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    HistoricalMessage message = messages[index];

    List<Widget> attachments =
        List<Widget>.from(message.attachments.map((fileUrl) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: MessageAttachedWidget(fileUrl: fileUrl),
      );
    }).toList());

    return <DataCell>[
      DataCell(
        Text(message.title),
      ),
      DataCell(
        Text(message.message),
      ),
      DataCell(
        Text(CodeUtils.getMessageTypeName(message.type)),
      ),
      DataCell(
        message.attachments.isEmpty
            ? const Text("Sin adjuntos")
            : Wrap(
                alignment: WrapAlignment.spaceEvenly,
                direction: Axis.horizontal,
                children: attachments,
              ),
      ),
      DataCell(
        Text(
          CodeUtils.formatDate(message.date),
        ),
      )
    ];
  }
}
