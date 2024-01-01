// ignore_for_file: use_build_context_synchronously

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/requests/display/screens/widgets/request_action_dialog.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/event_message_service/service.dart';
import '../../../../../core/services/local_notification_service.dart';
import '../../../../../core/utils/ui/ui_methods.dart';
import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../core/utils/ui/widgets/general/custom_tooltip.dart';
import '../../../data/models/event_model.dart';
import '../../../domain/entities/request_entity.dart';
import '../../providers/create_event_provider.dart';
import 'admin/clone_edit_requests_event_dialog.dart';

class QuickEventsActions extends StatefulWidget {
  final String selectedClientId;
  final Function(bool) onExpansionChanged;

  const QuickEventsActions({
    super.key,
    required this.selectedClientId,
    required this.onExpansionChanged,
  });

  @override
  State<QuickEventsActions> createState() => _QuickEventsActionsState();
}

class _QuickEventsActionsState extends State<QuickEventsActions> {
  bool isWidgetLoaded = false;
  bool isExpanded = false;
  late GetRequestsProvider getRequestsProvider;
  late ScreenSize screenSize;

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;

    getRequestsProvider = context.watch<GetRequestsProvider>();

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = context.read<GeneralInfoProvider>().screenSize;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(offset: Offset(0, 2), color: Colors.black12, blurRadius: 2)
        ],
      ),
      child: AnimatedSize(
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 500),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lista de eventos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    onTap: () {
                      isExpanded = !isExpanded;

                      widget.onExpansionChanged(isExpanded);

                      setState(() {});
                    },
                    child: Icon(isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down),
                  )
                ],
              ),
              if (isExpanded)
                Column(
                  children: [
                    const SizedBox(height: 15),
                    ...getRequestsProvider.filteredEvents
                        .where((event) =>
                            event.clientInfo.id == widget.selectedClientId)
                        .map((event) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  alignment: Alignment.topLeft,
                                  width: 290,
                                  child: CustomTooltip(
                                    message: event.eventName,
                                    child: Text(
                                      event.eventName,
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 40),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomTooltip(
                                      message: 'Agregar solicitudes',
                                      child: InkWell(
                                        onTap: () async {
                                          Provider.of<CreateEventProvider>(
                                                  context,
                                                  listen: false)
                                              .updateDialogStatus(
                                            true,
                                            screenSize,
                                            event,
                                          );
                                        },
                                        child: const Icon(
                                          Icons.add,
                                          size: 19,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    CustomTooltip(
                                      message: 'Editar solicitudes',
                                      child: InkWell(
                                        onTap: () async {
                                          List<Request> requests =
                                              getRequestsProvider.allRequests
                                                  .where((element) =>
                                                      element.eventId ==
                                                      event.id)
                                                  .toList();
                                          for (int i = 0;
                                              i < requests.length;
                                              i++) {
                                            getRequestsProvider
                                                .requestsToEditIndexes
                                                .add(i);
                                          }
                                          await RequestActionDialog.show(
                                            "move-requests",
                                            "Editar solicitudes",
                                            requests[0],
                                            event,
                                            [
                                              ...getRequestsProvider
                                                  .requestsToEditIndexes
                                            ],
                                            requests,
                                            false,
                                          );
                                          getRequestsProvider
                                              .requestsToEditIndexes
                                              .clear();
                                        },
                                        child: const Icon(
                                          Icons.edit,
                                          size: 19,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    CustomTooltip(
                                      message: 'Clonar solicitudes',
                                      child: InkWell(
                                        onTap: () {
                                          List<Request> requests =
                                              getRequestsProvider.allRequests
                                                  .where((element) =>
                                                      element.eventId ==
                                                      event.id)
                                                  .toList();

                                          for (int i = 0;
                                              i < requests.length;
                                              i++) {
                                            getRequestsProvider
                                                .requestsToEditIndexes
                                                .add(i);
                                          }
                                          CloneOrEditRequestsByEventDialog
                                              .showActionDialog(
                                            requestsList: requests,
                                            indexesList: [
                                              ...getRequestsProvider
                                                  .requestsToEditIndexes
                                            ],
                                            type: 'clone-requests',
                                            isItComeFromDialog: false,
                                          );
                                          getRequestsProvider
                                              .requestsToEditIndexes
                                              .clear();
                                        },
                                        child: const Icon(
                                          Icons.content_copy,
                                          size: 19,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    CustomTooltip(
                                      message: 'Modificar horario',
                                      child: InkWell(
                                        onTap: () async {
                                          List<Request> requests =
                                              getRequestsProvider.allRequests
                                                  .where((element) =>
                                                      element.eventId ==
                                                      event.id)
                                                  .toList();

                                          for (int i = 0;
                                              i < requests.length;
                                              i++) {
                                            getRequestsProvider
                                                .requestsToEditIndexes
                                                .add(i);
                                          }
                                          CloneOrEditRequestsByEventDialog
                                              .showActionDialog(
                                            requestsList: requests,
                                            indexesList: [
                                              ...getRequestsProvider
                                                  .requestsToEditIndexes
                                            ],
                                            type: 'change-schedule',
                                            isItComeFromDialog: false,
                                          );
                                          getRequestsProvider
                                              .requestsToEditIndexes
                                              .clear();
                                        },
                                        child: const Icon(
                                          Icons.alarm,
                                          size: 19,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    // if (event.details.status >= 2 &&
                                    //     event.details.status < 4)
                                    //   const SizedBox(width: 5),
                                    // if (event.details.status >= 2 &&
                                    //     event.details.status < 4)
                                    const SizedBox(width: 5),
                                    CustomTooltip(
                                      message: 'Enviar mensaje',
                                      child: InkWell(
                                        onTap: () async {
                                          List<String> ids = List<String>.from(
                                              getRequestsProvider.allRequests
                                                  .map(
                                            (Request requestItem) {
                                              return requestItem
                                                  .employeeInfo.id;
                                            },
                                          ).toList());
                                          await EventMessageService.send(
                                            eventItem: event,
                                            employeesIds: ids,
                                            company: context
                                                .read<AuthProvider>()
                                                .webUser
                                                .company,
                                            screenSize: screenSize,
                                          );
                                        },
                                        child: const Icon(
                                          Icons.circle_notifications_outlined,
                                          size: 19,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    CustomTooltip(
                                      message: 'Eliminar evento',
                                      child: InkWell(
                                        onTap: () async {
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
                                                    text: '${event.eventName}?',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            textCancel: const Text(
                                              "Cancelar",
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                            textOK: const Text(
                                              "Aceptar",
                                              style:
                                                  TextStyle(color: Colors.blue),
                                            ),
                                          );

                                          if (!itsConfirmed) {
                                            return;
                                          }
                                          UiMethods().showLoadingDialog(
                                              context: context);
                                          await Future.delayed(
                                            const Duration(milliseconds: 1200),
                                          );

                                          bool resp = await context
                                              .read<CreateEventProvider>()
                                              .deleteEvent(
                                                event as EventModel,
                                                getRequestsProvider.allRequests
                                                    .where((element) =>
                                                        element.eventId ==
                                                        event.id)
                                                    .toList(),
                                              );
                                          getRequestsProvider
                                              .updateDetailsStatus(
                                                  false, screenSize, event.id);

                                          if (resp) {
                                            LocalNotificationService
                                                .showSnackBar(
                                              type: "success",
                                              message:
                                                  "Evento eliminado correctamente.",
                                              icon: Icons.check_outlined,
                                            );
                                          } else {
                                            LocalNotificationService
                                                .showSnackBar(
                                              type: "fail",
                                              message:
                                                  "Ocurrió un problema al eliminar el evento.",
                                              icon: Icons.error_outline,
                                            );
                                          }
                                        },
                                        child: const Icon(
                                          Icons.delete,
                                          size: 19,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider()
                          ],
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
