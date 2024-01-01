abstract class Failure {
  final String? errorMessage;
  const Failure({required this.errorMessage});
}

class ServerFailure extends Failure {
  ServerFailure({required String? errorMessage})
      : super(errorMessage: errorMessage);
}

class LocalFailure extends Failure {
  LocalFailure({required String? errorMessage})
      : super(errorMessage: errorMessage);
}
