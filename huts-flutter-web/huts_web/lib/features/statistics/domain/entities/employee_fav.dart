class ClientEmployee {
  final String photo;
  final String fullname;
  final String uid;
  final List<String> jobs;
  final String phone;
  double hoursWorked;
  bool isSelected;
  String idClientEmployee;
  ClientEmployee(
      {required this.photo,
      required this.fullname,
      required this.uid,
      required this.jobs,
      required this.phone,
      required this.hoursWorked,
      this.isSelected = false,
      this.idClientEmployee = ''});
}
