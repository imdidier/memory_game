import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_date_selector.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/messages/display/widgets/employees_data_table.dart';
import 'package:huts_web/features/messages/display/widgets/job_item.dart';
import 'package:huts_web/features/messages/display/widgets/message_info_widget.dart';
import 'package:huts_web/features/messages/display/provider/messages_provider.dart';
import 'package:huts_web/features/messages/display/widgets/messages_data_table.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool isScreenLoaded = false;
  late MessagesProvider messagesProvider;
  late GeneralInfoProvider generalInfoProvider;
  late ScreenSize screenSize;
  bool isNewMessageSelected = true;
  bool isJobsMessageEnabled = true;
  List<String> messageStatusOptions = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController searchMessageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isShowingDateWidget = true;
  bool isDesktop = false;

  @override
  void didChangeDependencies() {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    messagesProvider = Provider.of<MessagesProvider>(context);
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);

    messageStatusOptions.add("Todos");
    CodeUtils.employeeStatus.forEach((key, value) {
      messageStatusOptions.add(value["name"]);
    });

    super.didChangeDependencies();
  }

  List<List<String>> dataTableFromResponsive = [];
  List<List<String>> dataTableFromResponsiveHistoryMessagues = [];

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    isDesktop = screenSize.width >= 1120;
    dataTableFromResponsive.clear();

    if (messagesProvider.filteredEmployees.isNotEmpty) {
      dataTableFromResponsive.clear();
      for (var employee in messagesProvider.filteredEmployees) {
        dataTableFromResponsive.add([
          "Acciones-",
          "Foto-${employee.imageUrl}",
          "Nombre-${CodeUtils.getFormatedName(employee.names, employee.lastNames)}",
          "Estado-${employee.status}",
          "Id-${employee.id}",
        ]);
      }
    }
    dataTableFromResponsiveHistoryMessagues.clear();

    if (messagesProvider.filteredMessages.isNotEmpty) {
      dataTableFromResponsiveHistoryMessagues.clear();

      for (var historyMessages in messagesProvider.filteredMessages) {
        dataTableFromResponsiveHistoryMessagues.add([
          "Título-${historyMessages.title}",
          "Mensaje-${historyMessages.message}",
          "Tipo-${CodeUtils.getMessageTypeName(historyMessages.type)}",
          "Destinatarios-${historyMessages.recipients}",
          "Adjuntos-${historyMessages.attachments.join(', ')}",
          "Fecha-${CodeUtils.formatDate(historyMessages.date)}",
          "Acciones-",
        ]);
      }
    }
    return SizedBox(
      height: screenSize.height,
      width: screenSize.blockWidth,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: NotificationListener(
              onNotification: (Notification notification) {
                if (_scrollController.position.pixels > 20 &&
                    isShowingDateWidget) {
                  isShowingDateWidget = false;
                  setState(() {});

                  return true;
                }

                if (_scrollController.position.pixels <= 30 &&
                    !isShowingDateWidget) {
                  isShowingDateWidget = true;
                  setState(() {});
                }
                return true;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTitle(screenSize),
                    buildTabs(),
                    (isNewMessageSelected)
                        ? buildMessageBody()
                        : buildHistoricalBody(),
                    const SizedBox(height: 35),
                    if (isNewMessageSelected) buildSendBtn(),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: screenSize.height * 0.05,
            right: 10,
            child: CustomDateSelector(
              isVisible: !isNewMessageSelected && isShowingDateWidget,
              onDateSelected: (DateTime? startDate, DateTime? endDate) async =>
                  await messagesProvider.getMessages(startDate, endDate),
            ),
          )
        ],
      ),
    );
  }

  Widget buildSendBtn() {
    return Center(
      child: InkWell(
        onTap: () async {
          if (isJobsMessageEnabled &&
              messagesProvider.selectedMessageStatusValues.isEmpty) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: "Debes elegir un estado",
              icon: Icons.error_outline,
            );
            return;
          }

          if (!isJobsMessageEnabled &&
              !messagesProvider.filteredEmployees
                  .any((element) => element.isSelected)) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: "Debes seleccionar al menos un colaborador",
              icon: Icons.error_outline,
            );
            return;
          }

          if (messagesProvider.messageController.text.isEmpty ||
              messagesProvider.titleController.text.isEmpty) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: "Debes agregar el título y el mensaje",
              icon: Icons.error_outline,
            );
            return;
          }

          UiMethods().showLoadingDialog(context: context);
          bool itsOK = await messagesProvider.sendMessage(
            isJobsMessageEnabled ? "admin-jobs" : "admin-employees",
          );
          UiMethods().hideLoadingDialog(context: context);

          if (!itsOK) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: "Ocurrió un error al enviar el mensaje",
              icon: Icons.error_outline,
            );
            return;
          }

          LocalNotificationService.showSnackBar(
            type: "success",
            message: "Mensaje enviado correctamente",
            icon: Icons.check_outlined,
          );
        },
        child: Container(
          width:
              isDesktop ? screenSize.blockWidth * 0.2 : screenSize.width - 50,
          height: screenSize.height * 0.055,
          decoration: BoxDecoration(
            color: UiVariables.primaryColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Envíar Mensaje",
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 15 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column buildHistoricalBody() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 35),
              child: Text(
                "Total mensajes: ${messagesProvider.allMessages.length}",
                style: TextStyle(fontSize: isDesktop ? 16 : 12),
              ),
            ),
            buildMessagesSearchBar(),
          ],
        ),
        buildMessages(),
      ],
    );
  }

  Container buildMessages() {
    return Container(
        margin: const EdgeInsets.only(top: 30),
        child: screenSize.blockWidth <= 920
            ? DataTableFromResponsive(
                listData: dataTableFromResponsiveHistoryMessagues,
                screenSize: screenSize,
                type: 'history-messages')
            : (messagesProvider.filteredMessages.isNotEmpty)
                ? MessagesDataTable(screenSize: screenSize)
                : const Center(
                    child: Text("No hay información"),
                  ));
  }

  Widget buildMessagesSearchBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        width: isDesktop
            ? screenSize.blockWidth * 0.3
            : screenSize.blockWidth * 0.45,
        height: screenSize.height * 0.055,
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
          controller: searchMessageController,
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.search),
            hintText: "Buscar mensaje",
            hintStyle:
                TextStyle(color: Colors.grey, fontSize: isDesktop ? 14 : 10),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onChanged: messagesProvider.filterMessages,
        ),
      ),
    );
  }

  SizedBox buildMessageBody() {
    return SizedBox(
      width: screenSize.blockWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Envíar mensaje por cargos",
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 12,
                ),
              ),
              Transform.scale(
                scale: isDesktop ? 0.82 : 0.6,
                child: CupertinoSwitch(
                  activeColor: UiVariables.primaryColor,
                  value: isJobsMessageEnabled,
                  onChanged: (bool newValue) async {
                    setState(() {
                      isJobsMessageEnabled = newValue;
                    });

                    if (messagesProvider.employees.isEmpty &&
                        !isJobsMessageEnabled) {
                      UiMethods().showLoadingDialog(context: context);
                      await messagesProvider.getEmployees();
                      UiMethods().hideLoadingDialog(context: context);
                    }
                  },
                ),
              )
            ],
          ),
          (isJobsMessageEnabled)
              ? buildMessageJobs()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "1. Selecciona a qué colaboradores enviarás el mensaje",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    buildSearchBar(),
                    const SizedBox(height: 20),
                    screenSize.blockWidth <= 920
                        ? DataTableFromResponsive(
                            listData: dataTableFromResponsive,
                            screenSize: screenSize,
                            type: 'message-employees')
                        : (messagesProvider.filteredEmployees.isNotEmpty)
                            ? EmployeesDataTable(screenSize: screenSize)
                            : const Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: Center(
                                  child:
                                      Text("No hay colaboradores disponibles"),
                                ),
                              ),
                  ],
                ),
          MessageInfoWidget(
            isJobMessage: isJobsMessageEnabled,
            screenSize: screenSize,
            statusOptions: messageStatusOptions,
          ),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 30),
        width: isDesktop
            ? screenSize.blockWidth * 0.3
            : screenSize.blockWidth * 0.45,
        height: screenSize.height * 0.055,
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
            hintText: "Buscar Colaborador",
            hintStyle:
                TextStyle(color: Colors.grey, fontSize: isDesktop ? 14 : 10),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onChanged: messagesProvider.filterEmployees,
        ),
      ),
    );
  }

  Column buildMessageJobs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "1. Selecciona a qué cargos enviarás el mensaje",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 20),
          width: isDesktop ? screenSize.blockWidth : screenSize.width,
          //height: screenSize.height * 0.4,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 6,
              crossAxisCount: isDesktop ? 3 : 1,
            ),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: messagesProvider.jobsList.length,
            itemBuilder: (BuildContext listCtx, int index) {
              return JobItem(
                jobIndex: index,
                isDesktop: isDesktop,
              );
            },
          ),
        )
      ],
    );
  }

  Container buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      child: OverflowBar(
        spacing: 20,
        overflowSpacing: 10,
        children: [
          ChoiceChip(
            backgroundColor: Colors.white,
            label: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Nuevo mensaje",
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 12,
                  color: isNewMessageSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
            selected: isNewMessageSelected,
            elevation: 2,
            selectedColor: UiVariables.primaryColor,
            onSelected: (bool newValue) {
              setState(() {
                isNewMessageSelected = newValue;
              });
            },
          ),
          ChoiceChip(
            backgroundColor: Colors.white,
            label: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Historial de mensajes",
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 12,
                  color: !isNewMessageSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
            selected: !isNewMessageSelected,
            elevation: 2,
            selectedColor: UiVariables.primaryColor,
            onSelected: (bool newValue) async {
              setState(() {
                isNewMessageSelected = !newValue;
              });
            },
          ),
        ],
      ),
    );
  }

  Column buildTitle(ScreenSize screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mensajes",
          style: TextStyle(
            color: Colors.black,
            fontSize: screenSize.width * 0.016,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "Envía mensajes a los colaboradores de Huts.",
          style: TextStyle(
            color: Colors.black54,
            fontSize: screenSize.width * 0.01,
          ),
        ),
      ],
    );
  }
}
