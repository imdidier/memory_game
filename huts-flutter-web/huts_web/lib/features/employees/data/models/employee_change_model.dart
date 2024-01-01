class EmployeeChange {
  String imageUrl;
  String names;
  String lastNames;
  String phone;
  String id;
  List<String> jobs;
  bool isSelected;

  EmployeeChange({
    required this.imageUrl,
    required this.names,
    required this.lastNames,
    required this.phone,
    required this.id,
    required this.isSelected,
    required this.jobs,
  });

  EmployeeChange.fromMap(Map<String, dynamic> map)
      : imageUrl = map["profile_info"]["image"],
        names = map["profile_info"]["names"],
        lastNames = map["profile_info"]["last_names"],
        phone = map["account_info"]["phone"],
        id = map["uid"],
        isSelected = false,
        jobs = map['jobs'];
}
