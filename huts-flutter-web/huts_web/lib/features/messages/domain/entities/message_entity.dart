import '../../../../core/utils/code/code_utils.dart';

class HistoricalMessage {
  String id;
  String title;
  String message;
  String type;
  String recipients;
  List<String> attachments;
  DateTime date;

  HistoricalMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.recipients,
    required this.attachments,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "message": message,
      "type": type,
      "recipients": recipients,
      "attachments": attachments,
      "date": CodeUtils.formatDate(date),
    };
  }
}
