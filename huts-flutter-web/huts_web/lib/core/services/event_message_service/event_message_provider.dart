import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/event_message_service/upload_file_model.dart';

import '../../../features/auth/domain/entities/company.dart';
import '../../../features/auth/domain/entities/screen_size_entity.dart';
import '../../../features/requests/domain/entities/event_entity.dart';
import '../local_notification_service.dart';

class EventMessageProvider with ChangeNotifier {
  Event? event;
  late ScreenSize screenSize;
  Company? company;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  List<UploadFile> uploadFiles = [];
  List<String> employeesIds = [];

  void loadFiles(List<PlatformFile> selectedFiles) {
    if (uploadFiles.length + selectedFiles.length > 5) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Solo puedes adjuntar un máximo de 5 archivos",
        icon: Icons.error_outline,
      );
      return;
    }

    for (PlatformFile platformFile in selectedFiles) {
      uploadFiles.add(
        UploadFile.fromPlatformFile(platformFile),
      );
    }

    notifyListeners();
  }

  void deleteFile(int index) {
    uploadFiles.removeAt(index);
    notifyListeners();
  }

  Future<bool> sendMessage(List<String> employeesIds) async {
    try {
      String newMessageId = FirebaseServices.db.collection("messages").doc().id;
      bool hasAttachedFiles = false;
      List<String> filesUrls = [];
      if (uploadFiles.isNotEmpty) {
        int filesCounter = 0;
        hasAttachedFiles = true;
        filesUrls = [
          ...await FirebaseServices.uploadFilesFromBytes(
            uploadFiles.map(
              (UploadFile item) {
                filesCounter++;
                return Map<String, dynamic>.from(
                  {
                    "path":
                        "messages/$newMessageId/-key-${item.name}-key-${item.getPathType()}-$filesCounter",
                    "type": item.getPathType(),
                    "bytes": item.bytes,
                  },
                );
              },
            ).toList(),
          ),
        ];
      }
      if (hasAttachedFiles && filesUrls.isEmpty) return false;

      Uri cloudUrl = Uri.parse(
        "https://us-central1-huts-services.cloudfunctions.net/sendEventMessage",
        // "http://localhost:5001/huts-services/us-central1/sendEventMessage",
      );

      String encodedEmployeesIds = "";
      String encodedFilesUrls = "";

      for (String id in employeesIds) {
        encodedEmployeesIds += (encodedEmployeesIds.isEmpty) ? id : ",$id";
      }

      for (String url in filesUrls) {
        encodedFilesUrls += (encodedFilesUrls.isEmpty) ? url : ",$url";
      }

      Map<String, dynamic> postBody = {
        "message_id": newMessageId,
        "from": (company == null)
            ? "Administrador Huts"
            : "${company!.name}: ${event!.eventName}",
        "title": titleController.text,
        "message": messageController.text,
        "files_urls": encodedFilesUrls,
        "type": "admin-employees",
        "employees_ids": encodedEmployeesIds,
      };

      http.Response response = await http.post(
        cloudUrl,
        body: postBody,
      );

      if (response.statusCode != 200) return false;
      return true;
    } catch (e) {
      if (kDebugMode) print("EventMessageProvider, sendMessage: $e");
      return false;
    }
  }
}
