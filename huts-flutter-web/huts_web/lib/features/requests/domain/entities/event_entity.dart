class Event {
  EventClientInfo clientInfo;
  EventDetails details;
  EventEmployeesInfo employeesInfo;
  String eventName;
  String id;
  int month;
  int year;
  String startWeek;
  String endWeek;
  String weekCut;

  Event({
    required this.clientInfo,
    required this.details,
    required this.employeesInfo,
    required this.eventName,
    required this.id,
    required this.month,
    required this.year,
    required this.startWeek,
    required this.endWeek,
    required this.weekCut,
  });
}

class EventClientInfo {
  String id;
  String imageUrl;
  String name;
  String country;

  EventClientInfo(this.id, this.imageUrl, this.name, this.country);
}

class EventFare {
  double totalToPayEmployees;
  double totalClientPays;

  EventFare(
    this.totalToPayEmployees,
    this.totalClientPays,
  );
}

class EventDetails {
  DateTime startDate;
  DateTime endDate;
  EventFare fare;
  Map<String, dynamic> location;
  Map<String, dynamic> rate;
  int status;
  double totalHours;

  EventDetails(
    this.startDate,
    this.endDate,
    this.fare,
    this.location,
    this.rate,
    this.status,
    this.totalHours,
  );
}

class EventEmployeesInfo {
  int acceptedEmployees;
  int arrivedEmployees;
  int neededEmployees;

  Map<String, dynamic> neededJobs;

  EventEmployeesInfo(
    this.acceptedEmployees,
    this.arrivedEmployees,
    this.neededEmployees,
    this.neededJobs,
  );
}
