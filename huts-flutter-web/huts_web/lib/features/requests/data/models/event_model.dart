import 'package:huts_web/features/requests/domain/entities/event_entity.dart';

class EventModel extends Event {
  EventModel({
    required super.clientInfo,
    required super.details,
    required super.employeesInfo,
    required super.eventName,
    required super.id,
    required super.month,
    required super.year,
    required super.startWeek,
    required super.endWeek,
    required super.weekCut,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> clientInfoMap = map["client_info"];
    Map<String, dynamic> detailsMap = map["details"];
    Map<String, dynamic> fareMap = detailsMap["fare"];
    Map<String, dynamic> employeesInfoMap = map["employees_info"];

    return EventModel(
      clientInfo: EventClientInfo(
        clientInfoMap["id"],
        clientInfoMap["image"],
        clientInfoMap["name"],
        clientInfoMap["country"],
      ),
      details: EventDetails(
        detailsMap["start_date"].toDate(),
        detailsMap["end_date"].toDate(),
        EventFare(
          fareMap["total_to_pay_employees"],
          fareMap["total_client_pays"],
        ),
        detailsMap["location"],
        detailsMap["rate"],
        detailsMap["status"],
        detailsMap["total_hours"],
      ),
      employeesInfo: EventEmployeesInfo(
        employeesInfoMap["employees_accepted"],
        employeesInfoMap["employees_arrived"],
        employeesInfoMap["employees_needed"],
        employeesInfoMap["jobs_needed"],
      ),
      endWeek: map["week_end"],
      startWeek: map["week_start"],
      eventName: map["event_number"],
      id: map["id"],
      month: map["month"],
      year: map["year"],
      weekCut: map["week_cut"],
    );
  }

  factory EventModel.emptyEvent() {
    return EventModel(
      clientInfo: EventClientInfo("id", "", "", ""),
      details: EventDetails(
        DateTime.now(),
        DateTime.now(),
        EventFare(
          0,
          0,
        ),
        {},
        {},
        0,
        0,
      ),
      employeesInfo: EventEmployeesInfo(0, 0, 0, {}),
      startWeek: "",
      endWeek: "",
      eventName: "",
      id: "",
      month: 0,
      weekCut: "",
      year: 0,
    );
  }

  toMap() {
    return <String, dynamic>{
      "client_info": {
        "id": clientInfo.id,
        "image": clientInfo.imageUrl,
        "name": clientInfo.name,
        "country": clientInfo.country,
      },
      "details": {
        "start_date": details.startDate,
        "end_date": details.endDate,
        "fare": {
          "total_to_pay_employees": details.fare.totalToPayEmployees,
          "total_client_pays": details.fare.totalClientPays,
        },
        "location": details.location,
        "rate": details.rate,
        "status": details.status,
        "total_hours": details.totalHours,
      },
      "employees_info": {
        "employees_accepted": employeesInfo.acceptedEmployees,
        "employees_arrived": employeesInfo.arrivedEmployees,
        "employees_needed": employeesInfo.neededEmployees,
        "jobs_needed": employeesInfo.neededJobs,
      },
      "week_end": endWeek,
      "week_start": startWeek,
      "event_number": eventName,
      "id": id,
      "month": month,
      "year": year,
      "week_cut": weekCut
    };
  }
}
