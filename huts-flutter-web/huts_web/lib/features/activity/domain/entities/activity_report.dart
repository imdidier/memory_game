class ActivityReport {
  String description;
  Map<String, dynamic> category;
  Map<String, dynamic> personInCharge;
  Map<String, dynamic> affectedUser;
  DateTime date;

  ActivityReport({
    required this.description,
    required this.category,
    required this.personInCharge,
    required this.affectedUser,
    required this.date,
  });
}
