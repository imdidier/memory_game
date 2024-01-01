class ActivityParams {
  final String description;
  final Map<String, dynamic> category;
  final Map<String, dynamic> personInCharge;
  final Map<String, dynamic> affectedUser;
  final DateTime date;

  ActivityParams({
    required this.description,
    required this.category,
    required this.personInCharge,
    required this.affectedUser,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return Map<String, dynamic>.from({
      "description": description,
      "category": category,
      "person_in_charge": personInCharge,
      "affected_user": affectedUser,
      "date": date,
    });
  }
}
