class ExcelParams {
  final List<Map<String, dynamic>> headers;
  final List<Map<String, dynamic>> data;
  final Map<String, dynamic> otherInfo;
  final String fileName;

  ExcelParams({
    required this.headers,
    required this.data,
    required this.otherInfo,
    required this.fileName,
  });
}
