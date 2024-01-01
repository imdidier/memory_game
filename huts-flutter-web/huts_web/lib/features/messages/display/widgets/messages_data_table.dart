import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/core/utils/ui/widgets/general/message_attached_widget.dart';
import 'package:huts_web/features/messages/display/provider/messages_provider.dart';
import 'package:huts_web/features/messages/display/widgets/message_details.dart';
import 'package:provider/provider.dart';

import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../domain/entities/message_entity.dart';

class MessagesDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  const MessagesDataTable({required this.screenSize, Key? key})
      : super(key: key);

  @override
  State<MessagesDataTable> createState() => _MessagesDataTableState();
}

class _MessagesDataTableState extends State<MessagesDataTable> {
  List<String> headers = [
    "Título",
    "Mensaje",
    "Tipo",
    "Destinatarios",
    "Adjuntos",
    "Fecha",
    "Acciones",
  ];

  @override
  Widget build(BuildContext context) {
    MessagesProvider provider = Provider.of<MessagesProvider>(context);
    return SizedBox(
      height: widget.screenSize.height * 0.6,
      width: widget.screenSize.blockWidth,
      child: SelectionArea(
        child: PaginatedDataTable2(
          lmRatio: 1.8,
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay mensajes "),
            ),
          ),
          horizontalMargin: 20,
          columnSpacing: 30,
      
          // rowsPerPage: (provider.filteredMessages.length >= 8)
          //     ? 8
          //     : provider.filteredMessages.length,
          columns: _getColums(),
          source: _MessagesTableSource(provider: provider),
        ),
      ),
    );
  }

  List<DataColumn2> _getColums() {
    return headers.map(
      (String header) {
        return DataColumn2(
          size: (header == "Mensaje") ? ColumnSize.L : ColumnSize.M,
          label:
              Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    ).toList();
  }
}

class _MessagesTableSource extends DataTableSource {
  final MessagesProvider provider;

  _MessagesTableSource({required this.provider});

  @override
  DataRow2? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => provider.filteredMessages.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    HistoricalMessage message = provider.filteredMessages[index];

    List<Widget> attachments = List<Widget>.from(
      message.attachments.map(
        (fileUrl) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: MessageAttachedWidget(fileUrl: fileUrl),
          );
        },
      ).toList(),
    );

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
        Text(message.recipients),
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
      ),
      DataCell(
        CustomTooltip(
          message: "Ver detalles",
          child: InkWell(
            onTap: () => MessageDetails.show(message),
            child: const Icon(
              Icons.info_outline,
              color: Colors.black54,
              size: 19,
            ),
          ),
        ),
      )
    ];
  }
}
