class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class LocalException implements Exception {
  final String message;
  const LocalException(this.message);
}
