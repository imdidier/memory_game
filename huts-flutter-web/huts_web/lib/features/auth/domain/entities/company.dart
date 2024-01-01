import 'package:huts_web/features/statistics/domain/entities/employee_fav.dart';

class Company {
  final String id;
  final Map<String, dynamic> accountInfo;
  final Map<String, dynamic> legalInfo;
  final String country;
  final String image;
  final String description;
  final String name;
  final Map<String, dynamic> location;
  final List<ClientEmployee> favoriteEmployees;
  final List<ClientEmployee> blockedEmployees;
  List<Map<String, dynamic>> webUserEmployees;

  final List<Job> jobs;

  Company({
    required this.id,
    required this.accountInfo,
    required this.legalInfo,
    required this.country,
    required this.image,
    required this.description,
    required this.name,
    required this.location,
    required this.favoriteEmployees,
    required this.blockedEmployees,
    required this.webUserEmployees,
    required this.jobs,
  });
}

class Job {
  final String name;
  final String value;
  final Map<String, dynamic> fares;

  Job({
    required this.name,
    required this.value,
    required this.fares,
  });
}
