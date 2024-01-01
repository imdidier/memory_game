import 'package:huts_web/features/auth/domain/entities/company.dart';

import '../../../statistics/data/models/employee_fav_model.dart';
import '../../../statistics/domain/entities/employee_fav.dart';

class CompanyModel extends Company {
  CompanyModel({
    required super.id,
    required super.accountInfo,
    required super.legalInfo,
    required super.country,
    required super.image,
    required super.description,
    required super.name,
    required super.favoriteEmployees,
    required super.blockedEmployees,
    required super.location,
    required super.jobs,
    required super.webUserEmployees,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    List<ClientEmployee> finalEmployeeFavs = [];
    List<ClientEmployee> finalBlockedEmployees = [];
    List<Map<String, dynamic>> finalWebUserEmployees = [];

    List<Job> finalJobs = [];
    if (map['favorites'] != null) {
      map['favorites'].forEach((key, value) {
        ClientEmployee newFav = ClientEmployeeModel.fromMap(value);
        finalEmployeeFavs.add(newFav);
      });
    }
    if (map['web_users'] != null) {
      map['web_users'].forEach((key, value) {
        Map<String, dynamic> newWebUser = value;
        finalWebUserEmployees.add(newWebUser);
      });
    }

    if (map["jobs"] != null) {
      map['jobs'].forEach((key, value) {
        Job newJob = JobModel.fromMap(value);
        finalJobs.add(newJob);
      });
    }

    if (map["blocked_employees"] != null) {
      map['blocked_employees'].forEach((key, value) {
        ClientEmployee newBlocked = ClientEmployeeModel.fromMap(value);
        finalBlockedEmployees.add(newBlocked);
      });
    }

    return CompanyModel(
      id: map['id'] ?? '',
      accountInfo: map['account_info'] ?? {},
      legalInfo: map['legal_info'] ?? {},
      country: map['country'] ?? '',
      image: map['image'] ?? 'images/icon_huts.jpeg',
      description: map['description'] ?? '',
      name: map['name'] ?? 'Huts Services',
      favoriteEmployees: finalEmployeeFavs,
      blockedEmployees: finalBlockedEmployees,
      location: map['location'] ?? {},
      jobs: finalJobs,
      webUserEmployees: finalWebUserEmployees,
    );
  }
}

class JobModel extends Job {
  JobModel({
    required super.name,
    required super.value,
    required super.fares,
  });

  factory JobModel.fromMap(Map<String, dynamic> map) {
    return JobModel(
      name: map["name"],
      value: map["value"],
      fares: map["fares"],
    );
  }
}
