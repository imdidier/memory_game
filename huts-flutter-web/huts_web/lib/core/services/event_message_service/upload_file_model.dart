import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class UploadFile {
  final String name;
  final String size;
  final String fileExtension;
  final Uint8List bytes;

  UploadFile({
    required this.name,
    required this.fileExtension,
    required this.size,
    required this.bytes,
  });

  UploadFile.fromPlatformFile(PlatformFile platformFile)
      : name = platformFile.name.split(platformFile.extension ?? "")[0],
        fileExtension = platformFile.extension?.toUpperCase() ?? "UNk",
        size = "${(platformFile.size / 1000000).toStringAsFixed(2)} Mb",
        bytes = platformFile.bytes ?? Uint8List.fromList([]);

  Color getColor() {
    if (fileExtension == "PDF") return Colors.red;
    if (fileExtension == "XLS" || fileExtension == "XLSX") return Colors.green;
    if (fileExtension == "DOCX") return Colors.blue;
    return Colors.orange;
  }

  String getPathType() {
    if (fileExtension == "PDF") return "pdf";
    if (fileExtension == "XLS") return "excel";
    if (fileExtension == "XLSX") return "excelx";
    if (fileExtension == "DOCX") return "word";
    return "image";
  }
}
