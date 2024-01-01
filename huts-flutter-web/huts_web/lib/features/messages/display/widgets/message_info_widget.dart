import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:multiselect/multiselect.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/event_message_service/upload_file_model.dart';
import '../provider/messages_provider.dart';

class MessageInfoWidget extends StatefulWidget {
  final ScreenSize screenSize;
  final List<String> statusOptions;
  final bool isJobMessage;

  const MessageInfoWidget({
    required this.screenSize,
    required this.statusOptions,
    required this.isJobMessage,
    Key? key,
  }) : super(key: key);

  @override
  State<MessageInfoWidget> createState() => _MessageInfoWidgetState();
}

class _MessageInfoWidgetState extends State<MessageInfoWidget> {
  bool isWidgetLoaded = false;
  late MessagesProvider provider;
  bool isDesktop = false;
  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    provider = Provider.of<MessagesProvider>(context);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    isDesktop = widget.screenSize.width >= 1120;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "2. Completa la información del mensaje",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 20),
          width: widget.screenSize.blockWidth,
          child: OverflowBar(
            children: [
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.isJobMessage) buildStatusField(),
                  buildTitleField(),
                ],
              ),
              const SizedBox(height: 10),
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildMessageField(),
                  buildFilesField(),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Column buildFilesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Archivos adjuntos",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
          child: Container(
            width: isDesktop
                ? widget.screenSize.width * 0.4
                : widget.screenSize.width,
            height: widget.screenSize.height * 0.2,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    offset: Offset(0, 2), color: Colors.black12, blurRadius: 2)
              ],
            ),
            child: Stack(
              children: [
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: widget.screenSize.width /
                        widget.screenSize.height *
                        1.4,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: provider.filesToSend.length,
                  itemBuilder: (_, int index) {
                    return _FileItemWidget(
                      currentFile: provider.filesToSend[index],
                      index: index,
                      provider: provider,
                      screenSize: widget.screenSize,
                    );
                  },
                ),
                Positioned(
                  bottom: 10,
                  right: 0,
                  child: InkWell(
                    onTap: () async => await provider.getFiles(),
                    child: Icon(
                      Icons.attach_file_outlined,
                      color: UiVariables.primaryColor.withOpacity(0.8),
                      size: 25,
                    ),
                  ),
                ),
                if (provider.filesToSend.isEmpty)
                  const Center(
                    child: Text(
                      "No has adjuntado archivos",
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Column buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Cuerpo del mensaje",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
          child: Container(
            width: isDesktop
                ? widget.screenSize.width * 0.4
                : widget.screenSize.width,
            height: widget.screenSize.height * 0.2,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    offset: Offset(0, 2), color: Colors.black12, blurRadius: 2)
              ],
            ),
            child: TextField(
              style: const TextStyle(fontSize: 13),
              controller: provider.messageController,
              cursorColor: UiVariables.primaryColor,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counter: SizedBox(),
                hintText: "Agrega un mensaje",
                hintStyle: TextStyle(fontSize: 13),
              ),
              maxLines: 12,
            ),
          ),
        ),
      ],
    );
  }

  Column buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Título del mensaje",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
          child: Container(
            width: isDesktop
                ? widget.screenSize.width * 0.4
                : widget.screenSize.width,
            height: widget.screenSize.height * 0.06,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    offset: Offset(0, 2), color: Colors.black12, blurRadius: 2)
              ],
            ),
            child: TextField(
              style: const TextStyle(fontSize: 13),
              controller: provider.titleController,
              cursorColor: UiVariables.primaryColor,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counter: SizedBox(),
                hintText: "Agrega un título",
                hintStyle: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Column buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Estado de los colaboradores a quienes le llegará el mensaje.",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
          child: Container(
            width: isDesktop
                ? widget.screenSize.width * 0.4
                : widget.screenSize.width,
            height: widget.screenSize.height * 0.06,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    offset: Offset(0, 2), color: Colors.black12, blurRadius: 2)
              ],
            ),
            child: DropDownMultiSelect(
              options: widget.statusOptions,
              selectedValues: provider.selectedMessageStatus,
              onChanged: provider.onSelectStatus,
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              hint: const Text(
                "Selecciona un estado",
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FileItemWidget extends StatelessWidget {
  final ScreenSize screenSize;
  final MessagesProvider provider;
  final UploadFile currentFile;
  final int index;

  const _FileItemWidget({
    Key? key,
    required this.screenSize,
    required this.index,
    required this.provider,
    required this.currentFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenSize.width * 0.1,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          )
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
    );
  }
}
