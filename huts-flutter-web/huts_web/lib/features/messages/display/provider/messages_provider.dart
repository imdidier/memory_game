import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/messages/data/datasources/messages_remote_datasource.dart';
import 'package:huts_web/features/messages/data/models/historical_message_model.dart';
import 'package:huts_web/features/messages/data/models/message_employee.dart';
import 'package:huts_web/features/messages/data/models/message_job.dart';
import 'package:huts_web/features/messages/data/repositories/messages_repository_impl.dart';
import 'package:huts_web/features/messages/domain/entities/message_entity.dart';
import 'package:huts_web/features/messages/domain/use_cases/send_message.dart';

import '../../../../core/firebase_config/firebase_services.dart';
import '../../../../core/services/event_message_service/upload_file_model.dart';
import '../../../../core/services/local_notification_service.dart';
import 'package:http/http.dart' as http;

class MessagesProvider with ChangeNotifier {
  List<MessageJob> jobsList = [];
  List<int> selectedMessageStatusValues = [];
  TextEditingController titleController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  List<UploadFile> filesToSend = [];
  List<String> employeesIds = [];
  List<MessageEmployee> employees = [];
  List<MessageEmployee> filteredEmployees = [];

  List<String> selectedMessageStatus = [];

  List<HistoricalMessage> allMessages = [];
  List<HistoricalMessage> filteredMessages = [];

  Future<void> getMessages(
    DateTime? start,
    DateTime? end,
  ) async {
    try {
      if (start == null) return;
      start = DateTime(
        start.year,
        start.month,
        start.day,
        00,
        00,
      );
      end ??= DateTime(
        start.year,
        start.month,
        start.day,
        23,
        59,
      );

      if (end.day != start.day) {
        end = DateTime(
          end.year,
          end.month,
          end.day,
          23,
          59,
        );
      }

      allMessages.clear();

      //TODO: Change this query to clean architecture
      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("messages")
          .where("date", isGreaterThanOrEqualTo: start)
          .where("date", isLessThanOrEqualTo: end)
          .get();

      for (DocumentSnapshot messageDoc in querySnapshot.docs) {
        Map<String, dynamic> messageData =
            messageDoc.data() as Map<String, dynamic>;
        messageData["id"] = messageDoc.id;

        if (messageData["type"] != "client-event") {
          allMessages.add(
            HistoricalMessageModel.fromMap(messageData),
          );
        }
      }
      filteredMessages = [...allMessages];
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("MessagesProvider, getMessages error: $e");
      }
    }
  }

  void filterMessages(String query) {
    filteredMessages.clear();
    query = query.toLowerCase();

    for (HistoricalMessage message in allMessages) {
      if (message.title.contains(query)) {
        filteredMessages.add(message);
        continue;
      }

      if (message.message.contains(query)) {
        filteredMessages.add(message);
        continue;
      }

      if (CodeUtils.formatDate(message.date).contains(query)) {
        filteredMessages.add(message);
        continue;
      }
    }
    notifyListeners();
  }

  selectJob(int jobIndex, bool newValue) {
    jobsList[jobIndex].isSelected = newValue;
    notifyListeners();
  }

  addMessageStatusValue() {
    selectedMessageStatusValues.clear();

    if (selectedMessageStatus.isEmpty) return;

    if (selectedMessageStatus.any((element) => element == "Todos")) {
      selectedMessageStatusValues.add(-1);
      return;
    }

    for (String statusName in selectedMessageStatus) {
      int index = CodeUtils.employeeStatus.values
          .toList()
          .indexWhere((element) => element["name"] == statusName);

      if (index != -1) {
        selectedMessageStatusValues.add(
          CodeUtils.employeeStatus.values.toList()[index]["value"],
        );
      }
    }
  }

  onSelectStatus(List<String> newSelection) {
    if (newSelection.contains("Todos")) {
      selectedMessageStatus.clear();
      selectedMessageStatus.add("Todos");
    } else {
      selectedMessageStatus = [...newSelection];
    }
    addMessageStatusValue();
    notifyListeners();
  }

  void filterEmployees(String query) {
    filteredEmployees.clear();

    if (query.isEmpty) {
      filteredEmployees = [...employees];
    } else {
      for (MessageEmployee messageEmployee in employees) {
        String statusName =
            CodeUtils.getEmployeeStatusName(messageEmployee.status);
        if (messageEmployee.names.toLowerCase().contains(query)) {
          filteredEmployees.add(messageEmployee);
          continue;
        }

        if (messageEmployee.lastNames.toLowerCase().contains(query)) {
          filteredEmployees.add(messageEmployee);
          continue;
        }

        if (statusName.toLowerCase().contains(query)) {
          filteredEmployees.add(messageEmployee);
          continue;
        }

        if (messageEmployee.id.toLowerCase().contains(query)) {
          filteredEmployees.add(messageEmployee);
          continue;
        }
      }
    }

    notifyListeners();
  }

  void loadFiles(List<PlatformFile> selectedFiles) {
    if (filesToSend.length + selectedFiles.length > 8) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Solo puedes adjuntar un máximo de 8 archivos",
        icon: Icons.error_outline,
      );
      return;
    }

    for (PlatformFile platformFile in selectedFiles) {
      filesToSend.add(
        UploadFile.fromPlatformFile(platformFile),
      );
    }
    notifyListeners();
  }

  Future<void> getFiles() async {
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
      loadFiles(filePickerResult.files);
    } catch (e) {
      if (kDebugMode) print("MessagesProvider, getFiles error: $e");
    }
  }

  void deleteFile(int index) {
    filesToSend.removeAt(index);
    notifyListeners();
  }

  Future<void> getEmployees() async {
    employees.clear();

    MessagesRepositoryImpl repository = MessagesRepositoryImpl(
      MessagesRemoteDataSourcesImpl(),
    );

    Either<Failure, List<MessageEmployee>> resp =
        await SendMessage(repository).getEmployees();

    resp.fold((l) => null, (List<MessageEmployee> employeesResp) {
      employees = [...employeesResp];
      filteredEmployees = [...employees];
    });
    notifyListeners();
  }

  Future<bool> sendMessage(String type) async {
    try {
      String newMessageId = FirebaseServices.db.collection("messages").doc().id;
      bool hasAttachedFiles = false;
      List<String> filesUrls = [];

      MessagesRepositoryImpl repository = MessagesRepositoryImpl(
        MessagesRemoteDataSourcesImpl(),
      );

      if (type == "admin-jobs") {
        final resp = await SendMessage(repository).getEmployeesIds(
          jobs: List<String>.from(
            jobsList
                .expand((MessageJob messageJob) =>
                    [if (messageJob.isSelected) messageJob.value])
                .toList(),
          ),
          status: selectedMessageStatusValues,
        );

        resp.fold(
          (Failure failure) {
            if (kDebugMode) {
              print(
                  "SendMessage, getEmployeesIds error: ${failure.errorMessage}");
            }
            return false;
          },
          (List<String> ids) => employeesIds = [...ids],
        );
      } else {
        employeesIds = filteredEmployees
            .expand((MessageEmployee item) => [if (item.isSelected) item.id])
            .toList();
      }

      if (employeesIds.isEmpty) return false;

      if (filesToSend.isNotEmpty) {
        int filesCounter = 0;
        hasAttachedFiles = true;
        filesUrls = [
          ...await FirebaseServices.uploadFilesFromBytes(
            filesToSend.map(
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
        "from": "Administrador Huts",
        "title": titleController.text,
        "message": messageController.text,
        "files_urls": encodedFilesUrls,
        "type": type,
        "employees_ids": encodedEmployeesIds,
      };

      http.Response response = await http.post(
        cloudUrl,
        body: postBody,
      );

      if (response.statusCode != 200) return false;
      for (MessageJob job in jobsList) {
        job.isSelected = false;
      }

      for (MessageEmployee employee in employees) {
        employee.isSelected = false;
      }

      selectedMessageStatus.clear();
      selectedMessageStatusValues.clear();
      titleController.text = "";
      messageController.text = "";
      filesToSend.clear();
      employeesIds.clear();
      jobsList[0].isSelected = true;
      filteredEmployees = [...employees];
      notifyListeners();

      return true;
    } catch (e) {
      if (kDebugMode) print("MessagesProvider, sendMessage: $e");
      return false;
    }
  }

  onEmployeeSelection(int index, bool newValue) {
    filteredEmployees[index].isSelected = newValue;

    int generalIndex = employees.indexWhere(
        (MessageEmployee item) => item.id == filteredEmployees[index].id);

    if (generalIndex != -1) {
      employees[generalIndex].isSelected = newValue;
    }

    notifyListeners();
  }
}
