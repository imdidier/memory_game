import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';

class MessageAttachedWidget extends StatelessWidget {
  final String fileUrl;
  const MessageAttachedWidget({required this.fileUrl, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String fileType = CodeUtils.getFileTypeFromUrl(fileUrl);
    return InkWell(
      onTap: () => CodeUtils.launchURL(fileUrl),
      child: CustomTooltip(
        message: fileUrl.split("-key-")[1].replaceAll("%20", " "),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: getFileColor(fileType),
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
                fileType,
                style: TextStyle(
                  fontSize: 6,
                  color: getFileColor(fileType),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getFileColor(String fileType) {
    if (fileType == "PDF") return Colors.red;
    if (fileType == "XLS" || fileType == "XLSX") return Colors.green;
    if (fileType == "DOCX") return Colors.blue;
    return Colors.orange;
  }
}
