import 'package:huts_web/features/messages/domain/entities/message_entity.dart';

class HistoricalMessageModel extends HistoricalMessage {
  HistoricalMessageModel({
    required super.id,
    required super.title,
    required super.message,
    required super.type,
    required super.recipients,
    required super.attachments,
    required super.date,
  });

  factory HistoricalMessageModel.fromMap(Map<String, dynamic> map) {
    return HistoricalMessageModel(
      id: map["id"],
      title: map["title"],
      message: map["message"],
      type: map["type"],
      recipients: map["type"] == "admin-jobs" ? "Cargos" : "Empleados",
      attachments: List<String>.from(map["attached_files_urls"]),
      date: map["date"].toDate(),
    );
  }
}
