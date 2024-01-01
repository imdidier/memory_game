import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/domain/entities/company.dart';
import '../../../features/auth/domain/entities/screen_size_entity.dart';
import '../../../features/requests/domain/entities/event_entity.dart';
import '../../utils/ui/widgets/general/custom_scroll_behavior.dart';
import '../../utils/ui/ui_variables.dart';
import '../local_notification_service.dart';
import 'event_message_provider.dart';
import 'upload_file_model.dart';

class DialogInfoWidget extends StatefulWidget {
  final Event? event;
  final List<String> employeesIds;
  final Company? company;
  final ScreenSize screenSize;
  final String employeeName;

  const DialogInfoWidget({
    required this.event,
    required this.employeesIds,
    required this.company,
    required this.screenSize,
    this.employeeName = "",
    Key? key,
  }) : super(key: key);

  @override
  State<DialogInfoWidget> createState() => _DialogInfoWidgetState();
}

class _DialogInfoWidgetState extends State<DialogInfoWidget> {
  late EventMessageProvider provider;
  late GeneralInfoProvider generalInfoProvider;
  @override
  Widget build(BuildContext context) {
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    provider = Provider.of<EventMessageProvider>(context);
    provider.event = widget.event;
    provider.employeesIds = widget.employeesIds;
    provider.company = widget.company;
    provider.screenSize = widget.screenSize;
    return Container(
      width: 700,
      // height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: ScrollController(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
              ),
              margin: EdgeInsets.symmetric(
                vertical: provider.screenSize.height * 0.09,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      buildFromToInfo(),
                      _buildTitleField(),
                      _buildMessageField(),
                    ],
                  ),
                  if (provider.uploadFiles.isNotEmpty) _buildAttachedList()
                ],
              ),
            ),
          ),
          _buildHeader(context),
          _buildFooter(),
        ],
      ),
      // ),
    );
  }

  Widget buildFromToInfo() {
    List<Widget> children = [
      buildFromWidget(),
      if (!generalInfoProvider.isDesktop) const SizedBox(height: 10),
      buildToWidget(provider.event),
    ];

    Widget fatherWidget = (generalInfoProvider.isDesktop)
        ? OverflowBar(
            overflowSpacing: 10,
            spacing: 10,
            alignment: MainAxisAlignment.spaceBetween,
            children: children,
          )
        : Column(
            children: children,
          );

    return fatherWidget;
  }

  Container _buildAttachedList() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      width: double.infinity,
      height: 60,
      child: ScrollConfiguration(
        behavior: CustomScrollBehavior(),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: provider.uploadFiles.length,
          itemBuilder: (BuildContext listCtx, int index) {
            UploadFile currentFile = provider.uploadFiles[index];
            return FileItemWidget(
              provider: provider,
              currentFile: currentFile,
              index: index,
            );
          },
        ),
      ),
    );
  }

  Future<void> _getFiles() async {
    try {
      FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowCompression: true,
        allowedExtensions: [
          "jpg",
          "jpeg",
          "pdf",
          "png",
          "XLS",
          "XLSX",
          "docx",
        ],
      );
      if (filePickerResult == null) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "No seleccionaste nigún archivo",
          icon: Icons.error_outline,
        );
        return;
      }
      provider.loadFiles(filePickerResult.files);
    } catch (e) {
      if (kDebugMode) print("EventMessageService, _loadFiles error: $e");
    }
  }

  Positioned _buildFooter() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
          left: 8.0,
          right: 14.0,
        ),
        width: double.infinity,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () async => await _getFiles(),
                child: Icon(
                  Icons.attach_file_outlined,
                  color: UiVariables.primaryColor.withOpacity(0.8),
                  size: 25,
                ),
              ),
              const SizedBox(width: 15),
              InkWell(
                onTap: () async {
                  if (provider.messageController.text.isEmpty ||
                      provider.titleController.text.isEmpty) {
                    LocalNotificationService.showSnackBar(
                      type: "fail",
                      message: "Debes agregar el título y el mensaje",
                      icon: Icons.error_outline,
                    );
                    return;
                  }
                  UiMethods().showLoadingDialog(context: context);
                  bool itsOK = await provider.sendMessage(widget.employeesIds);
                  UiMethods().hideLoadingDialog(context: context);

                  if (!itsOK) {
                    LocalNotificationService.showSnackBar(
                      type: "fail",
                      message: "Ocurrió un error al enviar el mensaje",
                      icon: Icons.error_outline,
                    );
                    return;
                  }

                  if (mounted) Navigator.of(context).pop();

                  LocalNotificationService.showSnackBar(
                    type: "success",
                    message: "Mensaje enviado correctamente",
                    icon: Icons.check_outlined,
                  );
                },
                child: Container(
                  width: 90,
                  height: 35,
                  decoration: BoxDecoration(
                    color: UiVariables.primaryColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Envíar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container _buildMessageField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: UiVariables.lightBlueColor,
      ),
      width: double.infinity,
      // height: 300,
      margin: EdgeInsets.only(
        top: provider.screenSize.height * 0.0,
        //bottom: provider.screenSize.height * 0.04,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          maxLines: 3,
          style: const TextStyle(fontSize: 15),
          controller: provider.messageController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: "Mensaje",
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Container _buildTitleField() {
    return Container(
      height: 50,
      width: double.infinity,
      margin: EdgeInsets.only(
        top: provider.screenSize.height * 0.02,
        bottom: provider.screenSize.height * 0.02,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: UiVariables.lightBlueColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        child: Center(
          child: TextField(
            style: const TextStyle(fontSize: 15),
            controller: provider.titleController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Título del mensaje",
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Row buildToWidget(Event? event) {
    return Row(
      children: [
        const Text(
          "Para: ",
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          (event != null)
              ? "Colaboradores ${event.eventName}"
              : widget.employeeName,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  Row buildFromWidget() {
    return Row(
      children: [
        const Text(
          "De: ",
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(
          width: 5,
        ),
        CircleAvatar(
          radius: 15,
          backgroundImage: (provider.company != null)
              ? NetworkImage(provider.company!.image)
              : Image.asset("assets/images/icon_huts.jpeg").image,
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          (provider.company != null)
              ? provider.company!.name
              : "Administrador Huts",
          style: const TextStyle(fontSize: 15),
        ),
      ],
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
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: provider.screenSize.width * 0.02,
            ),
          ),
        ),
      ),
    );
  }
}

class FileItemWidget extends StatelessWidget {
  const FileItemWidget({
    Key? key,
    required this.index,
    required this.provider,
    required this.currentFile,
  }) : super(key: key);

  final EventMessageProvider provider;
  final UploadFile currentFile;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            )
          ],
        ),
        margin: (index == 0)
            ? const EdgeInsets.only(left: 30, right: 10)
            : (index == provider.uploadFiles.length - 1)
                ? const EdgeInsets.only(left: 10, right: 30)
                : const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: currentFile.getColor().withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.folder,
                    color: Colors.white,
                    size: 25,
                  ),
                  Text(
                    currentFile.fileExtension,
                    style: TextStyle(
                      fontSize: 6,
                      color: currentFile.getColor(),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        currentFile.name,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      currentFile.size,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: InkWell(
                    onTap: () => provider.deleteFile(index),
                    child: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 15,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
