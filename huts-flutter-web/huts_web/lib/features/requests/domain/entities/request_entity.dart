import '../../data/models/request_model.dart';

class Request {
  final String id;
  final RequestClientInfo clientInfo;
  final RequestDetails details;
  final RequestEmployeeInfo employeeInfo;
  final String eventId;
  final String eventName;
  final int month;
  final int year;
  final String startWeek;
  final String endWeek;
  bool isSelected;
  Request(
      {required this.id,
      required this.employeeInfo,
      required this.eventId,
      required this.eventName,
      required this.month,
      required this.year,
      required this.startWeek,
      required this.endWeek,
      required this.clientInfo,
      required this.details,
      this.isSelected = false});

  Request createCopy() {
    return RequestModel.fromMap(toMap());
  }

  Map<String, dynamic> toMap() {
    return Map<String, dynamic>.from({
      "client_info": Map<String, dynamic>.from({
        "country": "Costa Rica",
        "id": clientInfo.id,
        "image": clientInfo.imageUrl,
        "name": clientInfo.name,
      }),
      "details": Map<String, dynamic>.from({
        "arrived_date": details.arrivedDate,
        "departed_date": details.departedDate,
        "fare": Map<String, dynamic>.from({
          "fare_type": details.fare.type,
          "client_fare": Map<String, dynamic>.from({
            "dynamic": Map<String, dynamic>.from({
              "fare": details.fare.clientFare.dynamicFare.fare,
              "fare_name": details.fare.clientFare.dynamicFare.fareName,
              "hours": details.fare.clientFare.dynamicFare.hours,
              "total_to_pay": details.fare.clientFare.dynamicFare.totalToPay,
            }),
            "holiday": Map<String, dynamic>.from({
              "fare": details.fare.clientFare.holidayFare.fare,
              "fare_name": details.fare.clientFare.holidayFare.fareName,
              "hours": details.fare.clientFare.holidayFare.hours,
              "total_to_pay": details.fare.clientFare.holidayFare.totalToPay,
            }),
            "normal": Map<String, dynamic>.from({
              "fare": details.fare.clientFare.normalFare.fare,
              "fare_name": details.fare.clientFare.normalFare.fareName,
              "hours": details.fare.clientFare.normalFare.hours,
              "total_to_pay": details.fare.clientFare.normalFare.totalToPay,
            }),
          }),
          "employee_fare": Map<String, dynamic>.from({
            "dynamic": Map<String, dynamic>.from({
              "fare": details.fare.employeeFare.dynamicFare.fare,
              "fare_name": details.fare.employeeFare.dynamicFare.fareName,
              "hours": details.fare.employeeFare.dynamicFare.hours,
              "total_to_pay": details.fare.employeeFare.dynamicFare.totalToPay,
            }),
            "holiday": Map<String, dynamic>.from({
              "fare": details.fare.employeeFare.holidayFare.fare,
              "fare_name": details.fare.employeeFare.holidayFare.fareName,
              "hours": details.fare.employeeFare.holidayFare.hours,
              "total_to_pay": details.fare.employeeFare.holidayFare.totalToPay,
            }),
            "normal": Map<String, dynamic>.from({
              "fare": details.fare.employeeFare.normalFare.fare,
              "fare_name": details.fare.employeeFare.normalFare.fareName,
              "hours": details.fare.employeeFare.normalFare.hours,
              "total_to_pay": details.fare.employeeFare.normalFare.totalToPay,
            }),
          }),
          "total_client_pays": details.fare.totalClientPays,
          "total_to_pay_employee": details.fare.totalToPayEmployee,
          "total_client_night_surcharge":
              details.fare.totalClientNightSurcharge,
          "total_employee_night_surcharge":
              details.fare.totalEmployeeNightSurcharge,
        }),
        "job": details.job,
        "location": details.location,
        "indications": details.indications,
        "rate": details.rate,
        "start_date": details.startDate,
        "end_date": details.endDate,
        "status": details.status,
        "total_hours": details.totalHours,
      }),
      "employee_info": employeeInfo.id == ""
          ? Map<String, dynamic>.from({})
          : Map<String, dynamic>.from({
              "doc_type": employeeInfo.docType,
              "doc_number": employeeInfo.docNumber,
              "image": employeeInfo.imageUrl,
              "names": employeeInfo.names,
              "last_names": employeeInfo.lastNames,
              "phone": employeeInfo.phone,
              "id": employeeInfo.id,
            }),
      "event_id": eventId,
      "event_number": eventName,
      "id": id,
      "year": year,
      "month": month,
      "week_start": startWeek,
      "week_end": endWeek,
    });
  }
}

class RequestClientInfo {
  final String id;
  final String imageUrl;
  final String name;

  RequestClientInfo(
    this.id,
    this.imageUrl,
    this.name,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image': imageUrl,
      'name': name,
      // 'country': 'Costa Rica',
    };
  }
}

class Fare {
  final double fare;
  final String fareName;
  final double hours;
  final double totalToPay;
  final double totalNightSurcharge;

  Fare(
    this.fare,
    this.fareName,
    this.hours,
    this.totalToPay,
    this.totalNightSurcharge,
  );
}

class FareType {
  final Fare normalFare;
  final Fare holidayFare;
  final Fare dynamicFare;

  FareType(this.normalFare, this.holidayFare, this.dynamicFare);
}

class RequestFare {
  final String type;
  final FareType clientFare;
  final FareType employeeFare;
  final double totalToPayEmployee;
  final double totalClientPays;
  final double totalClientNightSurcharge;
  final double totalEmployeeNightSurcharge;

  RequestFare(
    this.type,
    this.clientFare,
    this.employeeFare,
    this.totalToPayEmployee,
    this.totalClientPays,
    this.totalClientNightSurcharge,
    this.totalEmployeeNightSurcharge,
  );
}

class RequestDetails {
  DateTime startDate;
  DateTime endDate;
  DateTime arrivedDate;
  DateTime departedDate;
  RequestFare fare;
  Map<String, dynamic> job;
  Map<String, dynamic> location;
  String indications;
  String references;

  Map<String, dynamic> rate;
  int status;
  double totalHours;

  RequestDetails({
    required this.startDate,
    required this.endDate,
    required this.arrivedDate,
    required this.departedDate,
    required this.fare,
    required this.job,
    required this.location,
    required this.indications,
    required this.references,
    required this.rate,
    required this.status,
    required this.totalHours,
  });
}

class RequestEmployeeInfo {
  final String docType;
  final String docNumber;
  final String imageUrl;
  final String names;
  final String lastNames;
  final String phone;
  final String id;

  RequestEmployeeInfo(
    this.docType,
    this.docNumber,
    this.imageUrl,
    this.names,
    this.lastNames,
    this.phone,
    this.id,
  );
}
