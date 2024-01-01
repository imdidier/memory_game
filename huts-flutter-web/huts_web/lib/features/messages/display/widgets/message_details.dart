import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/event_message_service/service.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/messages/domain/entities/message_entity.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../../core/utils/ui/widgets/general/message_attached_widget.dart';

class MessageDetails {
  static Future<void> show(HistoricalMessage message) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;

    UiMethods().showLoadingDialog(context: globalContext);
    Map<String, dynamic>? resp = await EventMessageService.getInfo(message);
    UiMethods().hideLoadingDialog(context: globalContext);

    if (resp == null) {
      LocalNotificationService.showSnackBar(
        type: "fails",
        message: "No se pudieron obtener los detalles del mensaje",
        icon: Icons.error_outline,
      );
      return;
    }

    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (_) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            scrollable: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: const EdgeInsets.all(0),
            title: _MessageDialogContent(
              messageInfo: resp,
            ),
          ),
        );
      },
    );
  }
}

class _MessageDialogContent extends StatefulWidget {
  final Map<String, dynamic> messageInfo;
  const _MessageDialogContent({
    required this.messageInfo,
    Key? key,
  }) : super(key: key);

  @override
  State<_MessageDialogContent> createState() => __MessageDialogContentState();
}

class __MessageDialogContentState extends State<_MessageDialogContent> {
  late ScreenSize screenSize;

  List<List<String>> dataTableFromResponsive = [];

  @override
  Widget build(BuildContext context) {
    screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    return Container(
      width: screenSize.blockWidth * 0.8,
      height: screenSize.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
            ),
            height: screenSize.height * 0.75,
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: Container(
                margin: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: screenSize.height * 0.09,
                ),
                child: _buildBody(),
              ),
            ),
          ),
          _buildHeader(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: screenSize.blockWidth * 0.8,
      height: 60,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor,
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
                Navigator.of(context).pop();
              },
              child: Icon(
                Icons.close,
                color: Colors.white,
                size:
                    screenSize.blockWidth >= 920 ? screenSize.width * 0.02 : 16,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: screenSize.blockWidth * 0.6,
              child: Text(
                // "Detalles mensaje: ${widget.messageInfo["data"]["id"]}",
                "Detalles mensaje: ${widget.messageInfo["data"]["title"]}",
                maxLines: 2,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
                    overflow: TextOverflow.ellipsis),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 10,
        ),
        _buildGeneralInfo(),
      ],
    );
  }

  Widget _buildGeneralInfo() {
    dataTableFromResponsive.clear();

    if (widget.messageInfo["employees"].isNotEmpty) {
      dataTableFromResponsive.clear();
      for (var recipients in widget.messageInfo["employees"]) {
        dataTableFromResponsive.add([
          "Id-${recipients["employee_id"]}",
          "Nombres-${recipients["employee_names"]}",
          "Apellidos-${recipients["employee_last_names"]}",
          "¿Leído?-${recipients["is_read"]}",
          "¿Eliminado?-${recipients["is_visible"]}",
          "Fecha envío-${CodeUtils.formatDate(
            recipients["message_date"].toDate(),
          )}",
        ]);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Información general",
          style: TextStyle(
            fontSize: screenSize.blockWidth >= 920 ? 18 : 14,
          ),
        ),
        const SizedBox(height: 30),
        _buildMessageTitle(),
        const SizedBox(height: 20),
        _buildMessageAndAttachments(),
        const SizedBox(height: 30),
        Text(
          "Lista de destinatarios",
          style: TextStyle(
            fontSize: screenSize.blockWidth >= 920 ? 18 : 14,
          ),
        ),
        screenSize.blockWidth >= 920
            ? _buildDataTable()
            : DataTableFromResponsive(
                listData: dataTableFromResponsive,
                screenSize: screenSize,
                type: 'list-recipients')
      ],
    );
  }

  Column _buildMessageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Título del mensaje",
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
          ),
        ),
        Container(
          height: screenSize.height * 0.06,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                  offset: Offset(0, 2), color: Colors.black12, blurRadius: 2)
            ],
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.messageInfo["data"]["title"],
              style: TextStyle(
                fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget getAttachments() {
    List<Widget> attachments = List<Widget>.from(
      widget.messageInfo["data"]["attachments"].map(
        (fileUrl) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: MessageAttachedWidget(fileUrl: fileUrl),
          );
        },
      ).toList(),
    );

    return (attachments.isEmpty)
        ? Text(
            "Sin adjuntos",
            style: TextStyle(
              fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
            ),
          )
        : Wrap(
            alignment: WrapAlignment.spaceEvenly,
            direction: Axis.horizontal,
            children: attachments,
          );
  }

  Widget _buildMessageAndAttachments() {
    return SizedBox(
      child: OverflowBar(
        overflowSpacing: 10,
        children: [
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Cuerpo del mensaje",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
                    ),
                  ),
                  Container(
                    width: screenSize.blockWidth >= 920
                        ? screenSize.blockWidth * 0.34
                        : screenSize.blockWidth,
                    height: screenSize.height * 0.2,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          offset: Offset(0, 2),
                          color: Colors.black12,
                          blurRadius: 2,
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 4),
                      child: Text(
                        widget.messageInfo["data"]["message"],
                        style: TextStyle(
                          fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Archivos adjuntos",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
                    ),
                  ),
                  Container(
                    width: screenSize.blockWidth >= 920
                        ? screenSize.blockWidth * 0.34
                        : screenSize.blockWidth,
                    height: screenSize.height * 0.2,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                            offset: Offset(0, 2),
                            color: Colors.black12,
                            blurRadius: 2)
                      ],
                    ),
                    child: Center(child: getAttachments()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return SizedBox(
      height: screenSize.height * 0.6,
      child: SelectionArea(
        child: PaginatedDataTable2(
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                "No hay información",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          columns: _getColums(),
          source: _MessageDetailsTableSource(
            destinataries: widget.messageInfo["employees"],
          ),
        ),
      ),
    );
  }

  List<DataColumn2> _getColums() {
    List<String> headers = [
      "Id",
      "Nombres",
      "Apellidos",
      "¿Leído?",
      "¿Eliminado?",
      "Fecha envío",
    ];

    return headers
        .map(
          (String header) => DataColumn2(
            size: ColumnSize.L,
            label: Text(
              header,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
        .toList();
  }
}

class _MessageDetailsTableSource extends DataTableSource {
  final List<Map<String, dynamic>> destinataries;

  _MessageDetailsTableSource({required this.destinataries});

  @override
  DataRow? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => destinataries.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    Map<String, dynamic> destinatary = destinataries[index];

    return <DataCell>[
      DataCell(
        Text(destinatary["employee_id"]),
      ),
      DataCell(
        Text(destinatary["employee_names"]),
      ),
      DataCell(
        Text(destinatary["employee_last_names"]),
      ),
      DataCell(
        Chip(
          backgroundColor:
              (destinatary["is_read"]) ? Colors.green : Colors.grey,
          label: Text(
            (destinatary["is_read"]) ? "Sí" : "No",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      DataCell(
        Chip(
          backgroundColor:
              (destinatary["is_visible"]) ? Colors.blue : Colors.orange,
          label: Text(
            (destinatary["is_visible"]) ? "No" : "Sí",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      DataCell(
        Text(
          CodeUtils.formatDate(
            destinatary["message_date"].toDate(),
          ),
        ),
      ),
    ];
  }
}
