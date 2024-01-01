// ignore_for_file: use_build_context_synchronously

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/event_message_service/service.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/requests/display/providers/create_event_provider.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/display/screens/widgets/request_action_dialog.dart';
import 'package:huts_web/features/requests/display/screens/widgets/requests_data_table.dart';
import 'package:huts_web/features/requests/domain/entities/event_entity.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/local_notification_service.dart';
import '../../../data/models/event_model.dart';
import '../../../domain/entities/request_entity.dart';
import 'admin/clone_edit_requests_event_dialog.dart';

class EventItemWidget extends StatelessWidget {
  final ScreenSize screenSize;
  final Event event;
  final bool isAdmin;

  const EventItemWidget({
    Key? key,
    required this.screenSize,
    required this.event,
    required this.isAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    GetRequestsProvider requestsProvider =
        Provider.of<GetRequestsProvider>(context, listen: false);

    return InkWell(
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        UiMethods().showLoadingDialog(context: context);
        requestsProvider.getRequestsOrFail(event, context);
        _validateRequestsGotten(requestsProvider).then((value) {
          UiMethods().hideLoadingDialog(context: context);
          requestsProvider.updateDetailsStatus(true, screenSize, event.id);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        padding: const EdgeInsets.all(12),
        width: screenSize.width * 0.56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 2,
              color: Colors.black12,
            ),
          ],
        ),
        child: (screenSize.blockWidth >= 580)
            ? buildDesktopItem()
            : buildMobileItem(),
      ),
    );
  }

  Future<void> _validateRequestsGotten(GetRequestsProvider provider) async {
    await Future.delayed(const Duration(milliseconds: 600), () async {
      if (provider.isGettingRequests) {
        return await _validateRequestsGotten(provider);
      }
    });
  }

  Column buildMobileItem() {
    SizedBox verticalMargin = SizedBox(height: screenSize.height * 0.025);
    return Column(
      children: [
        Text("Horas por eventos: ${event.details.totalHours.toString()}"),
        const SizedBox(
          height: 15,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Nombre",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(
              width: screenSize.blockWidth * 0.6,
              child: Text(
                event.eventName,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 14, overflow: TextOverflow.ellipsis),
                maxLines: 3,
              ),
            ),
          ],
        ),
        verticalMargin,
        if (isAdmin)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Cliente",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(
                width: screenSize.blockWidth * 0.6,
                child: Text(
                  event.clientInfo.name,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 14, overflow: TextOverflow.ellipsis),
                  maxLines: 3,
                ),
              ),
            ],
          ),
        if (isAdmin) verticalMargin,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Colaboradores",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text("${event.employeesInfo.neededEmployees}"),
          ],
        ),
        verticalMargin,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Fecha inicio",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(CodeUtils.formatDate(event.details.startDate)),
          ],
        ),
        verticalMargin,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Fecha fin",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(CodeUtils.formatDate(event.details.endDate)),
          ],
        ),
        verticalMargin,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Estado",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CodeUtils.getStatusColor(event.details.status, false),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                CodeUtils.getEventStatusName(event.details.status),
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Row buildDesktopItem() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: screenSize.blockWidth * 0.1,
          // color: Colors.red,
          child: Column(
            children: [
              const Text(
                "Nombre",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              CustomTooltip(
                message: event.eventName,
                child: Text(
                  event.eventName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              )
            ],
          ),
        ),
        if (isAdmin)
          SizedBox(
            width: screenSize.blockWidth * 0.1,
            // color: Colors.red,
            child: Column(
              children: [
                const Text(
                  "Cliente",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                CustomTooltip(
                  message: event.clientInfo.name,
                  child: Text(
                    event.clientInfo.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                )
              ],
            ),
          ),
        Column(
          children: [
            const Text(
              "Colaboradores",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text("${event.employeesInfo.neededEmployees}"),
          ],
        ),
        Column(
          children: [
            const Text(
              "Fecha inicio",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(CodeUtils.formatDate(event.details.startDate)),
          ],
        ),
        Column(
          children: [
            const Text(
              "Fecha fin",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(CodeUtils.formatDate(event.details.endDate)),
          ],
        ),
        Column(
          children: [
            const Text(
              "Estado",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CodeUtils.getStatusColor(event.details.status, false),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                CodeUtils.getEventStatusName(event.details.status),
                style: TextStyle(
                  color:
                      event.details.status == 1 ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class EventDetailDialog extends StatefulWidget {
  final ScreenSize screenSize;
  final Event event;
  final bool isAdmin;
  const EventDetailDialog({
    required this.screenSize,
    required this.event,
    required this.isAdmin,
    Key? key,
  }) : super(key: key);

  @override
  State<EventDetailDialog> createState() => _EventDetailDialogState();
}

class _EventDetailDialogState extends State<EventDetailDialog> {
  TextEditingController searchController = TextEditingController();
  TextEditingController nameEventController = TextEditingController();

  late AuthProvider authProvider;
  late GetRequestsProvider requestsProvider;
  late GeneralInfoProvider generalInfoProvider;
  late bool isDesktop;

  // @override
  // void didChangeDependencies() {
  //   nameEventController.text = widget.event.eventName;
  //   super.didChangeDependencies();
  // }
  List<List<String>> dataTableFromResponsive = [];
  List<Request> requestIndication = [];
  @override
  Widget build(BuildContext context) {
    requestsProvider = Provider.of<GetRequestsProvider>(context);
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);

    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      width: widget.screenSize.blockWidth * 0.95,
      height: widget.screenSize.height * 0.8,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: widget.screenSize.blockWidth * 0.95,
              margin: EdgeInsets.only(
                top: widget.screenSize.height * 0.08,
              ),
              child: SingleChildScrollView(
                controller: ScrollController(),
                child: Column(
                  children: [
                    (requestsProvider.filteredRequests.isNotEmpty ||
                            !requestsProvider.isGettingRequests)
                        ? buildBody(requestsProvider)
                        : CircularProgressIndicator(
                            color: UiVariables.primaryColor,
                          ),
                  ],
                ),
              ),
            ),
          ),
          buildHeader(requestsProvider),
        ],
      ),
    );
  }

  Padding buildBody(GetRequestsProvider requestsProvider) {
    List<Widget> titleWidgetChildren = [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Colaboradores: ${widget.event.employeesInfo.neededEmployees}",
            style: TextStyle(
              fontSize: widget.screenSize.width * 0.012,
            ),
          ),
          const SizedBox(height: 8),
          if (authProvider.webUser.clientAssociationInfo.isEmpty)
            Text(
              (widget.event.details.fare.totalClientPays > 0)
                  ? "Total:  ${CodeUtils.formatMoney(widget.event.details.fare.totalClientPays)}"
                  : "Total: ₡0",
              style: TextStyle(
                fontSize: widget.screenSize.width * 0.012,
              ),
            ),
          const SizedBox(height: 15)
        ],
      ),
      Container(
        width: widget.screenSize.blockWidth >= 920
            ? widget.screenSize.blockWidth * 0.3
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
            suffixIcon: const Icon(Icons.search),
            hintText: "Buscar solicitud",
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: widget.screenSize.blockWidth >= 920
                  ? widget.screenSize.width * 0.012
                  : 13,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onChanged: requestsProvider.filterRequests,
        ),
      ),
    ];

    Widget titleWidget = (generalInfoProvider.isDesktop)
        ? OverflowBar(
            spacing: 10,
            alignment: MainAxisAlignment.spaceBetween,
            children: titleWidgetChildren,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: titleWidgetChildren,
          );
    dataTableFromResponsive.clear();

    if (requestsProvider.filteredRequests.isNotEmpty) {
      dataTableFromResponsive.clear();
      for (var requests in requestsProvider.filteredRequests) {
        dataTableFromResponsive.add([
          "Foto-${requests.employeeInfo.imageUrl}",
          "Nombre-${CodeUtils.getFormatedName(
            requests.employeeInfo.names,
            requests.employeeInfo.lastNames,
          )}",
          "Cargo-${requests.details.job['name']}",
          "Fecha inicio-${CodeUtils.formatDate(requests.details.startDate)}",
          "Fecha fin-${CodeUtils.formatDate(requests.details.endDate)}",
          "Total horas-${requests.details.totalHours}",
          "Estado-${CodeUtils.getStatusName(requests.details.status)}",
          "Acciones-",
        ]);
        requestIndication.add(requests);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          SizedBox(
            width: widget.screenSize.blockWidth,
            child: titleWidget,
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            height: widget.screenSize.height * 0.7,
            child: widget.screenSize.blockWidth >= 920
                ? RequestsDataTable(
                    requests: requestsProvider.filteredRequests,
                    allRequests: requestsProvider.allRequests,
                    screenSize: widget.screenSize,
                    event: widget.event,
                    onSort: (bool sortAscending, int? sortColumnIndex) {
                      if (sortColumnIndex == 2) {
                        requestsProvider.filteredRequests.sort((a, b) {
                          String aName = CodeUtils.getFormatedName(
                            a.employeeInfo.names,
                            a.employeeInfo.lastNames,
                          ).toLowerCase();

                          String bName = CodeUtils.getFormatedName(
                            b.employeeInfo.names,
                            b.employeeInfo.lastNames,
                          ).toLowerCase();

                          return sortAscending
                              ? aName.compareTo(bName)
                              : bName.compareTo(aName);
                        });
                      }

                      if (sortColumnIndex == 3) {
                        requestsProvider.filteredRequests.sort((a, b) {
                          String aJob = a.details.job["name"].toLowerCase();
                          String bJob = b.details.job["name"].toLowerCase();

                          return sortAscending
                              ? aJob.compareTo(bJob)
                              : bJob.compareTo(aJob);
                        });
                      }

                      if (sortColumnIndex == 4) {
                        requestsProvider.filteredRequests.sort((a, b) {
                          DateTime aStartDate = a.details.startDate;
                          DateTime bStartDate = b.details.startDate;

                          return sortAscending
                              ? aStartDate.compareTo(bStartDate)
                              : bStartDate.compareTo(aStartDate);
                        });
                      }

                      if (sortColumnIndex == 5) {
                        requestsProvider.filteredRequests.sort((a, b) {
                          DateTime aEndDate = a.details.endDate;
                          DateTime bEndDate = b.details.endDate;

                          return sortAscending
                              ? aEndDate.compareTo(bEndDate)
                              : bEndDate.compareTo(aEndDate);
                        });
                      }

                      if (sortColumnIndex == 6) {
                        requestsProvider.filteredRequests.sort((a, b) {
                          return sortAscending
                              ? a.details.totalHours
                                  .compareTo(b.details.totalHours)
                              : b.details.totalHours
                                  .compareTo(a.details.totalHours);
                        });
                      }

                      if (sortColumnIndex == 7) {
                        requestsProvider.filteredRequests.sort((a, b) {
                          return sortAscending
                              ? a.details.status.compareTo(b.details.status)
                              : b.details.status.compareTo(a.details.status);
                        });
                      }

                      setState(() {});
                    },
                  )
                : SingleChildScrollView(
                    child: DataTableFromResponsive(
                        listData: dataTableFromResponsive,
                        screenSize: widget.screenSize,
                        type: 'requests-event',
                        event: widget.event,
                        isAdmin: widget.isAdmin),
                  ),
          ),
        ],
      ),
    );
  }

  Container buildHeader(GetRequestsProvider provider) {
    return Container(
      width: widget.screenSize.blockWidth,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: widget.screenSize.blockWidth * 0.25,
            child: Row(
              children: [
                InkWell(
                  onTap: () => provider.updateDetailsStatus(
                      false, widget.screenSize, widget.event.id),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: widget.screenSize.width * 0.018,
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomTooltip(
                      message: "Evento: ${widget.event.eventName}",
                      child: SizedBox(
                        height: 25,
                        width: widget.screenSize.blockWidth * 0.15,
                        child: Text(
                          "Evento: ${widget.event.eventName}",
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.screenSize.blockWidth >= 920
                                ? widget.screenSize.width * 0.013
                                : 14,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    //  const SizedBox(height: 5),
                    // SizedBox(
                    //   height: 20,
                    //   width: widget.screenSize.blockWidth * 0.15,
                    //   child: Text(
                    //     "ID: ${widget.event.id}",
                    //     style: TextStyle(
                    //       color: Colors.white,
                    //       fontSize: widget.screenSize.blockWidth >= 920
                    //           ? widget.screenSize.width * 0.01
                    //           : 12,
                    //       overflow: TextOverflow.ellipsis,
                    //     ),
                    //     maxLines: 1,
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.event.details.status != 5 &&
              widget.screenSize.blockWidth > 1100)
            OverflowBar(
              spacing: 12,
              overflowSpacing: 12,
              children: [
                if (provider.requestsToEditIndexes.isNotEmpty)
                  InkWell(
                    onTap: () async => await RequestActionDialog.show(
                      "move-requests",
                      "Editar solicitudes",
                      requestsProvider.allRequests[0],
                      widget.event,
                      [...provider.requestsToEditIndexes],
                      [...provider.allRequests],
                    ),
                    child: Text(
                      "Editar solicitudes",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.screenSize.blockWidth >= 920
                            ? widget.screenSize.width * 0.011
                            : 11,
                      ),
                    ),
                  ),
                if (provider.requestsToEditIndexes.isNotEmpty)
                  InkWell(
                    onTap: () {
                      List<Request> newList = [...provider.allRequests];
                      CloneOrEditRequestsByEventDialog.showActionDialog(
                        requestsList: newList,
                        indexesList: [...provider.requestsToEditIndexes],
                        type: 'clone-requests',
                      );
                    },
                    child: Text(
                      "Clonar solicitudes",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.screenSize.blockWidth >= 920
                            ? widget.screenSize.width * 0.011
                            : 11,
                      ),
                    ),
                  ),
                if (provider.requestsToEditIndexes.isNotEmpty)
                  InkWell(
                    onTap: () =>
                        CloneOrEditRequestsByEventDialog.showActionDialog(
                      requestsList: [...provider.allRequests],
                      indexesList: [...provider.requestsToEditIndexes],
                      type: 'change-schedule',
                    ),
                    child: Text(
                      "Modificar horario",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.screenSize.blockWidth >= 920
                            ? widget.screenSize.width * 0.011
                            : 11,
                      ),
                    ),
                  ),
                widget.event.details.status != 3 &&
                        widget.event.details.status != 4
                    ? InkWell(
                        onTap: () async {
                          Provider.of<CreateEventProvider>(context,
                                  listen: false)
                              .updateDialogStatus(
                            true,
                            widget.screenSize,
                            widget.event,
                          );
                        },
                        child: Text(
                          "Agregar solicitudes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.screenSize.blockWidth >= 920
                                ? widget.screenSize.width * 0.011
                                : 11,
                          ),
                        ),
                      )
                    : const SizedBox(),
                if (provider.requestsToEditIndexes.length ==
                    provider.allRequests.length)
                  InkWell(
                    onTap: () async {
                      if ((!widget.isAdmin &&
                              widget.event.details.status == 3 ||
                          widget.event.details.status == 4 &&
                              !widget.isAdmin)) {
                        LocalNotificationService.showSnackBar(
                          type: "fail",
                          message:
                              "No puedes eliminar un evento cuando esta activo o finalizado.",
                          icon: Icons.error,
                          duration: 5,
                        );
                        return;
                      }
                      DateTime startDate = DateTime(
                        widget.event.details.startDate.year,
                        widget.event.details.startDate.month,
                        widget.event.details.startDate.day - 1,
                        23,
                        59,
                      );
                      DateTime startDateHours = DateTime(
                        widget.event.details.startDate.year,
                        widget.event.details.startDate.month,
                        widget.event.details.startDate.day,
                        widget.event.details.startDate.hour - 12,
                        widget.event.details.startDate.minute,
                      );
                      if (!widget.isAdmin &&
                          (DateTime.now().isAfter(startDate) &&
                              DateTime.now().isAfter(startDateHours))) {
                        LocalNotificationService.showSnackBar(
                          type: "fail",
                          message:
                              "Solo puedes eliminar el evento hasta media noche del día anterior o 12 horas antes que inicie",
                          icon: Icons.error,
                          duration: 5,
                        );
                        return;
                      }
                      bool itsConfirmed = await confirm(
                        context,
                        title: Text(
                          "¿Seguro quieres eliminar el evento?",
                          style: TextStyle(
                            color: UiVariables.primaryColor,
                          ),
                        ),
                        content: RichText(
                          text: TextSpan(
                            text:
                                '¿Quieres eliminar el evento y las solicitudes asociadas al evento: ',
                            children: <TextSpan>[
                              TextSpan(
                                text: '${widget.event.eventName}?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        textCancel: const Text(
                          "Cancelar",
                          style: TextStyle(color: Colors.grey),
                        ),
                        textOK: const Text(
                          "Aceptar",
                          style: TextStyle(color: Colors.blue),
                        ),
                      );

                      if (!itsConfirmed) return;

                      CreateEventProvider createEventProvider =
                          context.read<CreateEventProvider>();
                      provider.updateDetailsStatus(
                          false, widget.screenSize, widget.event.id);
                      UiMethods().showLoadingDialog(context: context);
                      bool resp = await createEventProvider.deleteEvent(
                        widget.event as EventModel,
                        requestsProvider.allRequests
                            .where(
                                (element) => element.eventId == widget.event.id)
                            .toList(),
                      );
                      UiMethods().hideLoadingDialog(
                          context: NavigationService.getGlobalContext()!);
                      if (resp) {
                        LocalNotificationService.showSnackBar(
                          type: "success",
                          message: "Evento eliminado correctamente.",
                          icon: Icons.check_outlined,
                        );
                      } else {
                        LocalNotificationService.showSnackBar(
                          type: "fail",
                          message: "Ocurrió un problema al eliminar el evento.",
                          icon: Icons.error_outline,
                        );
                      }
                    },
                    child: Text(
                      "Eliminar evento",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.screenSize.blockWidth >= 920
                            ? widget.screenSize.width * 0.011
                            : 11,
                      ),
                    ),
                  ),
                if (widget.event.details.status >= 2 &&
                    widget.event.details.status < 4)
                  InkWell(
                    onTap: () async {
                      List<String> ids =
                          List<String>.from(requestsProvider.allRequests.map(
                        (Request requestItem) {
                          return requestItem.employeeInfo.id;
                        },
                      ).toList());
                      await EventMessageService.send(
                        eventItem: widget.event,
                        employeesIds: ids,
                        company: authProvider.webUser.company,
                        screenSize: widget.screenSize,
                      );
                    },
                    child: Text(
                      "Mensaje",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.screenSize.blockWidth >= 920
                            ? widget.screenSize.width * 0.011
                            : 11,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
