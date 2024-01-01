// ignore_for_file: use_build_context_synchronously
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/display/screens/widgets/request_action_dialog.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/services/local_notification_service.dart';
import '../../../../../../core/utils/code/code_utils.dart';
import '../../../../../../core/utils/ui/ui_methods.dart';

import '../../../../domain/entities/request_entity.dart';

class ClientRequestsDataTable extends StatefulWidget {
  final List<Request> allRequests;
  final Function(bool, int?) onSort;

  final ScreenSize screenSize;
  final bool? isPrint;

  const ClientRequestsDataTable({
    required this.allRequests,
    required this.screenSize,
    required this.onSort,
    this.isPrint = false,
    Key? key,
  }) : super(key: key);

  @override
  State<ClientRequestsDataTable> createState() => _ClientRequestsDataTable();
}

class _ClientRequestsDataTable extends State<ClientRequestsDataTable> {
  bool isDataSetted = false;
  late Request request;
  bool _sortAscending = true;
  int? _sortColumnIndex;
  @override
  Widget build(BuildContext context) {
    if (!isDataSetted) {
      for (var i = 0; i < widget.allRequests.length; i++) {
        widget.allRequests[i].isSelected = false;
      }
      RequestsTableSource.selectedIndexes.clear();
      context.read<GetRequestsProvider>().updateRequestsToEditIndexes(
            RequestsTableSource.selectedIndexes,
            false,
          );
      isDataSetted = true;
    }
    return SizedBox(
      height: widget.allRequests.length > 10
          ? widget.screenSize.height
          : widget.screenSize.height * 0.5,
      width: double.infinity,
      child: SelectionArea(
        child: PaginatedDataTable2(
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay información"),
            ),
          ),
          horizontalMargin: 20,
          columnSpacing: 20,
          columns: getColumns(),
          source: RequestsTableSource(
            isPrint: widget.isPrint,
            allRequests: widget.allRequests,
            onTapItem: (List<int> indexes) {
              RequestsTableSource.selectedIndexes = indexes;
              context.read<GetRequestsProvider>().updateRequestsToEditIndexes(
                    RequestsTableSource.selectedIndexes,
                    mounted,
                  );
              for (var i = 0; i < widget.allRequests.length; i++) {
                widget.allRequests[i].isSelected = false;
              }
              for (int index in indexes) {
                widget.allRequests[index].isSelected = true;
                int filteredIndex = widget.allRequests.indexWhere(
                    (element) => element.id == widget.allRequests[index].id);
                if (filteredIndex != -1) {
                  widget.allRequests[filteredIndex].isSelected = true;
                }
              }
              if (mounted) setState(() {});
            },
            screenSize: widget.screenSize,
          ),
          wrapInCard: false,
          minWidth: 900,
          fit: FlexFit.tight,
          dataRowHeight: kMinInteractiveDimension + 10,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          sortArrowIcon: Icons.keyboard_arrow_up,
          sortArrowAnimationDuration: const Duration(milliseconds: 300),
          rowsPerPage: 10,
          onRowsPerPageChanged: (value) {},
          availableRowsPerPage: const [10, 20, 50],
        ),
      ),
    );
  }

  List<DataColumn> getColumns() {
    return <DataColumn>[
      if (!widget.isPrint!)
        const DataColumn2(
          label:
              Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.L,
        ),
      if (!widget.isPrint!)
        const DataColumn2(
            label: Text(
              "Foto",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            size: ColumnSize.M),
      DataColumn2(
          onSort: (columnIndex, isAscending) {
            _sortAscending = isAscending;
            _sortColumnIndex = columnIndex;

            setState(() {});

            widget.onSort(_sortAscending, _sortColumnIndex);
          },
          label: const Text("Nombre",
              style: TextStyle(fontWeight: FontWeight.bold))),
      const DataColumn(
          label: Text("Evento", style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn2(
          onSort: (columnIndex, isAscending) {
            _sortAscending = isAscending;
            _sortColumnIndex = columnIndex;

            setState(() {});

            widget.onSort(_sortAscending, _sortColumnIndex);
          },
          label: const Text("Cargo",
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn2(
          onSort: (columnIndex, isAscending) {
            _sortAscending = isAscending;
            _sortColumnIndex = columnIndex;

            setState(() {});

            widget.onSort(_sortAscending, _sortColumnIndex);
          },
          label: const Text("Fecha inicio",
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn2(
          onSort: (columnIndex, isAscending) {
            _sortAscending = isAscending;
            _sortColumnIndex = columnIndex;

            setState(() {});

            widget.onSort(_sortAscending, _sortColumnIndex);
          },
          label: const Text("Fecha fin",
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn2(
          onSort: (columnIndex, isAscending) {
            _sortAscending = isAscending;
            _sortColumnIndex = columnIndex;

            setState(() {});

            widget.onSort(_sortAscending, _sortColumnIndex);
          },
          label: const Text("Total horas",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold))),
      if (!widget.isPrint!)
        DataColumn2(
            onSort: (columnIndex, isAscending) {
              _sortAscending = isAscending;
              _sortColumnIndex = columnIndex;

              setState(() {});

              widget.onSort(_sortAscending, _sortColumnIndex);
            },
            label: const Text("Estado",
                style: TextStyle(fontWeight: FontWeight.bold)),
            size: ColumnSize.M),
    ];
  }
}

class RequestsTableSource extends DataTableSource {
  final List<Request> allRequests;

  final ScreenSize screenSize;
  final Function onTapItem;
  final bool? isPrint;

  RequestsTableSource({
    required this.allRequests,
    required this.screenSize,
    required this.onTapItem,
    this.isPrint = false,
  });

  static List<int> selectedIndexes = [];

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
  int get rowCount => allRequests.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    bool isEmployeeRatingEnabled = false;
    bool isEmployeeFavoriteEnabled = false;
    bool isBlockEmployeeEnabled = false;
    Request request = allRequests[index];
    RequestEmployeeInfo employeeInfo = request.employeeInfo;

    Color? favoriteIconColor;
    Color? blockedIconColor;
    Color? ratedIconColor;
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return List<DataCell>.from([]);

    AuthProvider authProvider =
        Provider.of<AuthProvider>(globalContext, listen: false);

    GetRequestsProvider getRequestsProvider =
        Provider.of<GetRequestsProvider>(globalContext);

    isEmployeeRatingEnabled = request.details.status == 4;

    if (request.details.status >= 1 && request.details.status <= 4) {
      bool isInFavorite = authProvider.webUser.company.favoriteEmployees.any(
        (favoriteEmployee) => favoriteEmployee.uid == request.employeeInfo.id,
      );

      bool isInBlocked = authProvider.webUser.company.blockedEmployees.any(
        (blockedEmployee) => blockedEmployee.uid == request.employeeInfo.id,
      );

      favoriteIconColor =
          (isInFavorite && isInBlocked) || (isInFavorite && !isInBlocked)
              ? Colors.red
              : null;
      isEmployeeFavoriteEnabled = !isInBlocked;

      blockedIconColor =
          (isInBlocked && isInFavorite) || (!isInFavorite && isInBlocked)
              ? Colors.orange
              : null;
      isBlockEmployeeEnabled = !isInFavorite;

      ratedIconColor = request.details.rate.isNotEmpty ? Colors.amber : null;
    }

    return <DataCell>[
      if (!isPrint!)
        DataCell(
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: getClientActions(
                request,
                isEmployeeRatingEnabled,
                isEmployeeFavoriteEnabled,
                isBlockEmployeeEnabled,
                ratedIconColor,
                favoriteIconColor,
                blockedIconColor,
                getRequestsProvider,
              ),
            ),
          ),
        ),
      if (!isPrint!)
        DataCell(
          Container(
            margin: const EdgeInsets.only(
              right: 30,
              top: 4,
              bottom: 4,
            ),
            child: (employeeInfo.imageUrl.isNotEmpty)
                ? CircleAvatar(
                    radius: 60,
                    // foregroundImage: NetworkImage(
                    //   employeeInfo.imageUrl,
                    // ),
                    child: ClipOval(
                      child: Image.network(
                        employeeInfo.imageUrl,
                      ),
                    ),
                  )
                : const CircleAvatar(
                    radius: 60,
                    child: Icon(
                      Icons.hide_image_outlined,
                    ),
                  ),
          ),
        ),
      DataCell(
        Text(
          CodeUtils.getFormatedName(
            employeeInfo.names,
            employeeInfo.lastNames,
          ),
        ),
      ),
      DataCell(
        Text(request.eventName),
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
      if (!isPrint!)
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
                    request.details.status == 0 || request.details.status == 1
                        ? Colors.black
                        : Colors.white,
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> getClientActions(
      Request request,
      bool isEmployeeRatingEnabled,
      bool isEmployeeFavoriteEnabled,
      bool isBlockEmployeeEnabled,
      Color? ratedIconColor,
      Color? favoriteIconColor,
      Color? blockedIconColor,
      [GetRequestsProvider? provider]) {
    return [
      const SizedBox(height: 10),
      Row(
        children: [
          getActionItem(request.details.status <= 4, "Modificar horario",
              Icons.access_time, "time", request, provider),
          const SizedBox(width: 10),
          getActionItem(
              true, "Clonar", Icons.content_copy, "clone", request, provider),
          const SizedBox(width: 10),
          getActionItem(request.details.status <= 4, "Editar",
              Icons.create_outlined, "edit", request, provider),
          const SizedBox(width: 10),
          CustomTooltip(
            message: "Eliminar solicitud",
            child: InkWell(
              onTap: () async {
                if (request.details.status >= 4) return;
                DateTime startDate = DateTime(
                  request.details.startDate.year,
                  request.details.startDate.month,
                  request.details.startDate.day - 1,
                  23,
                  59,
                );
                DateTime startDateHours = DateTime(
                  request.details.startDate.year,
                  request.details.startDate.month,
                  request.details.startDate.day,
                  request.details.startDate.hour - 12,
                  request.details.startDate.minute,
                );
                if (DateTime.now().isAfter(startDate) ||
                    DateTime.now().isAfter(startDateHours)) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message:
                        "Solo puedes eliminar la solicitud hasta media noche del día anterior o 12 horas antes de iniciar el evento.",
                    icon: Icons.error,
                    duration: 5,
                  );
                  return;
                }

                if (allRequests.length == 1) {
                  provider!
                      .updateDetailsStatus(false, screenSize, request.eventId);
                }

                await provider!.deleteRequest(request);
              },
              child: Icon(
                Icons.delete,
                color: request.details.status >= 4
                    ? Colors.grey[300]
                    : Colors.black54,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Row(
        children: [
          getActionItem(
            isEmployeeRatingEnabled,
            ratedIconColor != null
                ? "Ver Calificación"
                : "Calificar colaborador",
            Icons.star_outline,
            "rate",
            request,
            provider,
            iconColor: ratedIconColor,
          ),
          const SizedBox(width: 10),
          getActionItem(
            isEmployeeFavoriteEnabled,
            favoriteIconColor != null
                ? "Eliminar de favoritos"
                : "Agregar a favoritos",
            Icons.favorite_outline,
            "favorite",
            request,
            provider,
            iconColor: favoriteIconColor,
          ),
          const SizedBox(width: 10),
          getActionItem(
            isBlockEmployeeEnabled,
            blockedIconColor != null ? "Desbloquear" : "Agregar a bloqueados",
            Icons.block,
            "block",
            request,
            provider,
            iconColor: blockedIconColor,
          ),
          const SizedBox(width: 10),
          CustomTooltip(
            message: "Marcar llegada",
            child: InkWell(
              onTap: () async {
                if (request.details.status != 2) return;

                if (!isDatesSameDay(
                    DateTime.now(), request.details.startDate)) {
                  LocalNotificationService.showSnackBar(
                    type: 'fail',
                    message:
                        'Solo puede marcar la llegada del colaborador el día del evento',
                    icon: Icons.warning,
                  );
                  return;
                }
                BuildContext? globalContext =
                    NavigationService.getGlobalContext();
                if (globalContext == null) return;
                UiMethods().showLoadingDialog(context: globalContext);

                bool resp = await provider!.markArrival(request, screenSize);

                UiMethods().hideLoadingDialog(context: globalContext);

                if (!resp) {
                  LocalNotificationService.showSnackBar(
                    type: 'fail',
                    message: 'No se marcó la llegada del colaborador.',
                    icon: Icons.warning,
                  );
                } else {
                  LocalNotificationService.showSnackBar(
                    type: 'success',
                    message:
                        'Se marcó la llegada del colaborador correctamente.',
                    icon: Icons.check_outlined,
                  );
                }
              },
              child: Icon(
                Icons.location_on_outlined,
                color: request.details.status != 2 ||
                        !isDatesSameDay(
                            DateTime.now(), request.details.startDate)
                    ? Colors.grey[300]
                    : Colors.black54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
    ];
  }

  bool isDatesSameDay(DateTime firsDate, DateTime secondDate) {
    if (firsDate.year != secondDate.year) return false;
    if (firsDate.month != secondDate.month) return false;
    if (firsDate.day != secondDate.day) return false;

    return true;
  }

  CustomTooltip getActionItem(
    bool isEnabled,
    String message,
    IconData icon,
    String type,
    Request request,
    GetRequestsProvider? provider, {
    Color? iconColor,
  }) {
    return CustomTooltip(
      message: message,
      child: InkWell(
        onTap: () async => !isEnabled
            ? null
            : await RequestActionDialog.show(
                type,
                message,
                request,
                provider!.clientFilteredEvents
                    .firstWhere((element) => element.id == request.eventId),
                [],
                [],
                false,
              ),
        child: Icon(
          icon,
          size: 18,
          color: (iconColor != null)
              ? iconColor
              : isEnabled
                  ? Colors.black54
                  : Colors.grey.withOpacity(0.65),
        ),
      ),
    );
  }
}
