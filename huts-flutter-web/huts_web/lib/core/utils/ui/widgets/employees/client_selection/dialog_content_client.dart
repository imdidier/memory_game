import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../../ui_variables.dart';

class DialogContentClients extends StatefulWidget {
  final List<ClientEntity> clients;

  const DialogContentClients({
    required this.clients,
    super.key,
  });

  @override
  State<DialogContentClients> createState() => _DialogContentClientsState();
}

class _DialogContentClientsState extends State<DialogContentClients> {
  ScreenSize? screenSize;
  int selectedIndex = -1;
  List<List<String>> dataTableFromResponsive = [];
  @override
  Widget build(BuildContext context) {
    screenSize ??=
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    dataTableFromResponsive.clear();

    if (widget.clients.isNotEmpty) {
      dataTableFromResponsive.clear();

      for (var selectClient in widget.clients) {
        dataTableFromResponsive.add([
          "Acciones-",
          "Foto-${selectClient.imageUrl}",
          "Nombre-${selectClient.name}",
          "Id-${selectClient.accountInfo.id}",
        ]);
      }
    }
    return Container(
      width: screenSize!.blockWidth * 0.83,
      height: screenSize!.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: ScrollController(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              margin: EdgeInsets.symmetric(vertical: screenSize!.height * 0.09),
              child: Column(
                children: [
                  screenSize!.blockWidth >= 920
                      ? ClientsDataTable(
                          clients: widget.clients,
                          screenSize: screenSize!,
                        )
                      : DataTableFromResponsive(
                          listData: dataTableFromResponsive,
                          screenSize: screenSize!,
                          type: 'selected-client')
                ],
              ),
            ),
          ),
          _buildHeader(context),
          screenSize!.blockWidth >= 920 ? _buildAceptBtn() : const SizedBox()
        ],
      ),
    );
  }

  Container _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(null),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: screenSize!.blockWidth * 0.02,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Selecciona un cliente",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize!.blockWidth >= 920 ? 18 : 14,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Positioned _buildAceptBtn() {
    return Positioned(
      bottom: 20,
      right: 30,
      child: InkWell(
        onTap: () {
          if (screenSize!.blockWidth <= 920) return;
          if (_TableSource.selectedId.isEmpty) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: "Debes seleccionar un cliente",
              icon: Icons.error_outline,
            );
            return;
          }
          Navigator.of(context).pop(
            widget.clients.firstWhere(
                (element) => element.accountInfo.id == _TableSource.selectedId),
          );
          _TableSource.selectedId = "";
        },
        child: Container(
          width: screenSize!.blockWidth >= 920
              ? screenSize!.blockWidth * 0.08
              : 200,
          height: 35,
          decoration: BoxDecoration(
            color: UiVariables.primaryColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Aceptar",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenSize!.blockWidth >= 920 ? 15 : 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClientsDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  final List<ClientEntity> clients;
  const ClientsDataTable({
    required this.screenSize,
    required this.clients,
    Key? key,
  }) : super(key: key);

  @override
  State<ClientsDataTable> createState() => _ClientsDataTableState();
}

class _ClientsDataTableState extends State<ClientsDataTable> {
  List<String> headers = [
    "Acciones",
    "Foto",
    "Nombre",
    // "Id",
  ];

  ScreenSize? screenSize;
  final TextEditingController _searchController = TextEditingController();
  List<ClientEntity> filteredClients = [];

  bool isWidgetLoaded = false;

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    filteredClients = [...widget.clients];
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize ??= context.read<GeneralInfoProvider>().screenSize;
    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 20),
        SizedBox(
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
              columnSpacing: 0,
              columns: _getColums(),
              onRowsPerPageChanged: (value) {},
              availableRowsPerPage: const [10, 20, 50],
              source: _TableSource(
                clients: filteredClients,
                onTapItem: (String id) {
                  setState(() {
                    _TableSource.selectedId = id;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  _filterClients(String query) {
    query = query.toLowerCase().trim();
    filteredClients.clear();
    if (query.isEmpty) {
      filteredClients = [...widget.clients];
    } else {
      for (ClientEntity client in widget.clients) {
        String name = client.name.toLowerCase().trim();
        if (name.contains(query)) filteredClients.add(client);
      }
    }

    setState(() {});
  }

  List<DataColumn2> _getColums() {
    return headers.map(
      (String header) {
        return DataColumn2(
          size: (header == "Nombre") ? ColumnSize.L : ColumnSize.S,
          label: Text(
            header,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    ).toList();
  }

  Widget _buildSearchBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        height: screenSize!.blockWidth >= 920 ? screenSize!.height * 0.055 : 30,
        width: screenSize!.blockWidth >= 920
            ? screenSize!.blockWidth * 0.3
            : screenSize!.blockWidth * 0.35,
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
          controller: _searchController,
          decoration: InputDecoration(
            suffixIcon: Icon(
              Icons.search,
              size: screenSize!.blockWidth >= 920 ? 16 : 12,
            ),
            hintText: "Buscar cliente",
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: screenSize!.blockWidth >= 920 ? 14 : 10,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: screenSize!.blockWidth >= 920 ? 12 : 4),
          ),
          onChanged: _filterClients,
        ),
      ),
    );
  }
}

class _TableSource extends DataTableSource {
  final List<ClientEntity> clients;
  final Function onTapItem;
  _TableSource({required this.clients, required this.onTapItem});

  static String selectedId = "";

  @override
  DataRow? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => clients.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    ClientEntity client = clients[index];

    return <DataCell>[
      DataCell(
        Checkbox(
          value: selectedId == client.accountInfo.id,
          onChanged: (bool? newValue) {
            if (newValue!) {
              selectedId = client.accountInfo.id;
            } else {
              selectedId = "";
            }
            onTapItem(selectedId);
          },
        ),
      ),
      DataCell(CustomTooltip(
        message: "Copiar ID",
        child: InkWell(
            onTap: () async => await Clipboard.setData(
                ClipboardData(text: client.accountInfo.id)),
            child:
                CircleAvatar(backgroundImage: NetworkImage(client.imageUrl))),
      )),
      DataCell(Text(client.name)),
      //DataCell(Text(client.accountInfo.id)),
    ];
  }
}
