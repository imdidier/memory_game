import 'package:huts_web/features/statistics/domain/entities/employee_fav.dart';

class ClientEmployeeModel extends ClientEmployee {
  ClientEmployeeModel({
    required super.photo,
    required super.fullname,
    required super.uid,
    required super.jobs,
    required super.phone,
    required super.hoursWorked,
  });

  factory ClientEmployeeModel.fromMap(Map<String, dynamic> map) {
    String fullName = '';
    map.containsKey('full_name')
        ? fullName = map['full_name']
        : fullName = map['fullname'] ??
            '${map['employee_info']['names']} ${map['employee_info']['last_names']}';
    return ClientEmployeeModel(
      fullname: fullName,
      jobs: List<String>.from(map['jobs'] ?? []),
      phone: map['phone'] ?? '${map['employee_info']['phone']}',
      photo: map.containsKey('photo')
          ? map['photo']
          : (map.containsKey('employee_info'))
              ? '${map['employee_info']['image']}'
              : map['image'] ?? '',
      uid: map['uid'] ?? '${map['employee_info']['id']}',
      hoursWorked: (map.containsKey('details'))
          ? map['details']['total_hours'].toDouble()
          : 0,
    );
  }
}
