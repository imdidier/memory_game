import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';

class RequestModel extends Request {
  RequestModel({
    required super.id,
    required super.employeeInfo,
    required super.eventId,
    required super.eventName,
    required super.month,
    required super.year,
    required super.startWeek,
    required super.endWeek,
    required super.clientInfo,
    required super.details,
  });

  factory RequestModel.fromMap(Map<dynamic, dynamic> map) {
    Map<String, dynamic> employeeMap = map["employee_info"];
    Map<String, dynamic> clientMap = map["client_info"];
    Map<String, dynamic> detailsMap = map["details"];
    Map<String, dynamic> fareMap = detailsMap["fare"];
    return RequestModel(
      id: map["id"],
      employeeInfo: RequestEmployeeInfo(
        employeeMap["doc_type"] ?? "",
        employeeMap["doc_number"] ?? "",
        employeeMap["image"] ?? "",
        employeeMap["names"] ?? "",
        employeeMap["last_names"] ?? "",
        employeeMap["phone"] ?? "",
        employeeMap["id"] ?? "",
      ),
      eventId: map["event_id"],
      eventName: map["event_number"],
      month: map["month"],
      year: map["year"],
      startWeek: map["week_start"],
      endWeek: map["week_end"],
      clientInfo: RequestClientInfo(
        clientMap["id"],
        clientMap["image"],
        clientMap["name"],
      ),
      details: RequestDetails(
        startDate: (detailsMap["start_date"].runtimeType == Timestamp)
            ? detailsMap["start_date"].toDate()
            : detailsMap["start_date"],
        endDate: (detailsMap["end_date"].runtimeType == Timestamp)
            ? detailsMap["end_date"].toDate()
            : detailsMap["end_date"],
        arrivedDate: (detailsMap["status"] >= 3 &&
                detailsMap["arrived_date"].runtimeType != String)
            ? detailsMap['arrived_date'].runtimeType == Timestamp
                ? detailsMap["arrived_date"].toDate()
                : detailsMap["arrived_date"]
            : DateTime.now(),
        departedDate: (detailsMap["status"] == 4 &&
                detailsMap["departed_date"].runtimeType != String)
            ? detailsMap['departed_date'].runtimeType == Timestamp
                ? detailsMap["departed_date"].toDate()
                : detailsMap["departed_date"]
            : DateTime.now(),
        fare: RequestFare(
          fareMap["fare_type"],
          FareType(
            Fare(
              fareMap["client_fare"]["normal"]["fare"] ?? 0,
              fareMap["client_fare"]["normal"]["fare_name"] ?? "",
              fareMap["client_fare"]["normal"]["hours"] ?? 0,
              fareMap["client_fare"]["normal"]["total_to_pay"] ?? 0,
              fareMap["client_fare"]["normal"]['total_night_surcharge'] ?? 0,
            ),
            Fare(
              fareMap["client_fare"]["holiday"]["fare"] ?? 0,
              fareMap["client_fare"]["holiday"]["fare_name"] ?? "",
              fareMap["client_fare"]["holiday"]["hours"] ?? 0,
              fareMap["client_fare"]["holiday"]["total_to_pay"] ?? 0,
              fareMap["client_fare"]["holiday"]['total_night_surcharge'] ?? 0,
            ),
            Fare(
              fareMap["client_fare"]["dynamic"]["fare"] ?? 0,
              fareMap["client_fare"]["dynamic"]["fare_name"] ?? "",
              fareMap["client_fare"]["dynamic"]["hours"] ?? 0,
              fareMap["client_fare"]["dynamic"]["total_to_pay"] ?? 0,
              fareMap["client_fare"]["dynamic"]['total_night_surcharge'] ?? 0,
            ),
          ),
          FareType(
            Fare(
              fareMap["employee_fare"]["normal"]["fare"] ?? 0,
              fareMap["employee_fare"]["normal"]["fare_name"] ?? "",
              fareMap["employee_fare"]["normal"]["hours"] ?? 0,
              fareMap["employee_fare"]["normal"]["total_to_pay"] ?? 0,
              fareMap["employee_fare"]["normal"]['total_night_surcharge'] ?? 0,
            ),
            Fare(
              fareMap["employee_fare"]["holiday"]["fare"] ?? 0,
              fareMap["employee_fare"]["holiday"]["fare_name"] ?? "",
              fareMap["employee_fare"]["holiday"]["hours"] ?? 0,
              fareMap["employee_fare"]["holiday"]["total_to_pay"] ?? 0,
              fareMap["employee_fare"]["holiday"]['total_night_surcharge'] ?? 0,
            ),
            Fare(
              fareMap["employee_fare"]["dynamic"]["fare"] ?? 0,
              fareMap["employee_fare"]["dynamic"]["fare_name"] ?? "",
              fareMap["employee_fare"]["dynamic"]["hours"] ?? 0,
              fareMap["employee_fare"]["dynamic"]["total_to_pay"] ?? 0,
              fareMap["employee_fare"]["dynamic"]['total_night_surcharge'] ?? 0,
            ),
          ),
          fareMap["total_to_pay_employee"],
          fareMap["total_client_pays"],
          fareMap["total_client_night_surcharge"] ?? 0,
          fareMap["total_employee_night_surcharge"] ?? 0,
        ),
        job: detailsMap["job"],
        location: detailsMap["location"],
        indications: detailsMap["indications"] ?? 'Sin indicaciones',
        references: detailsMap["references"] ?? 'Sin referencias',
        rate: detailsMap["rate"],
        status: detailsMap["status"],
        totalHours: detailsMap["total_hours"],
      ),
    );
  }

  factory RequestModel.fromRequest(Request request) {
    return RequestModel(
      id: request.id,
      employeeInfo: request.employeeInfo,
      eventId: request.eventId,
      eventName: request.eventName,
      month: request.month,
      year: request.year,
      startWeek: request.startWeek,
      endWeek: request.endWeek,
      clientInfo: request.clientInfo,
      details: request.details,
    );
  }

  // Map<String, dynamic> toMap(Request request) {
  //   return <String, dynamic>{
  //     "client_info": {
  //       "country": "Costa Rica",
  //       "id": request.clientInfo.id,
  //       "image": request.clientInfo.imageUrl,
  //       "name": request.clientInfo.name,
  //     },
  //     "details": {
  //       "arrived_date": request.details.arrivedDate,
  //       "departed_date": request.details.departedDate,
  //       "fare": {
  //         "fare_type": request.details.fare.type,
  //         "client_fare": {
  //           "dynamic": {
  //             "fare": request.details.fare.clientFare.dynamicFare.fare,
  //             "fare_name": request.details.fare.clientFare.dynamicFare.fareName,
  //             "hours": request.details.fare.clientFare.dynamicFare.hours,
  //             "total_to_pay":
  //                 request.details.fare.clientFare.dynamicFare.totalToPay,
  //           },
  //           "holiday": {
  //             "fare": request.details.fare.clientFare.holidayFare.fare,
  //             "fare_name": request.details.fare.clientFare.holidayFare.fareName,
  //             "hours": request.details.fare.clientFare.holidayFare.hours,
  //             "total_to_pay":
  //                 request.details.fare.clientFare.holidayFare.totalToPay,
  //           },
  //           "normal": {
  //             "fare": request.details.fare.clientFare.normalFare.fare,
  //             "fare_name": request.details.fare.clientFare.normalFare.fareName,
  //             "hours": request.details.fare.clientFare.normalFare.hours,
  //             "total_to_pay":
  //                 request.details.fare.clientFare.normalFare.totalToPay,
  //           },
  //         },
  //         "employee_fare": {
  //           "dynamic": {
  //             "fare": request.details.fare.employeeFare.dynamicFare.fare,
  //             "fare_name":
  //                 request.details.fare.employeeFare.dynamicFare.fareName,
  //             "hours": request.details.fare.employeeFare.dynamicFare.hours,
  //             "total_to_pay":
  //                 request.details.fare.employeeFare.dynamicFare.totalToPay,
  //           },
  //           "holiday": {
  //             "fare": request.details.fare.employeeFare.holidayFare.fare,
  //             "fare_name":
  //                 request.details.fare.employeeFare.holidayFare.fareName,
  //             "hours": request.details.fare.employeeFare.holidayFare.hours,
  //             "total_to_pay":
  //                 request.details.fare.employeeFare.holidayFare.totalToPay,
  //           },
  //           "normal": {
  //             "fare": request.details.fare.employeeFare.normalFare.fare,
  //             "fare_name":
  //                 request.details.fare.employeeFare.normalFare.fareName,
  //             "hours": request.details.fare.employeeFare.normalFare.hours,
  //             "total_to_pay":
  //                 request.details.fare.employeeFare.normalFare.totalToPay,
  //           },
  //         },
  //         "total_client_pays": request.details.fare.totalClientPays,
  //         "total_to_pay_employee": request.details.fare.totalToPayEmployee,
  //       },
  //       "job": request.details.job,
  //       "location": request.details.location,
  //       "indications": request.details.indications,
  //       "rate": request.details.rate,
  //       "start_date": request.details.startDate,
  //       "end_date": request.details.endDate,
  //       "status": request.details.status,
  //       "total_hours": request.details.totalHours,
  //     },
  //     "employee_info": request.employeeInfo.id == ""
  //         ? {}
  //         : {
  //             "doc_type": request.employeeInfo.docType,
  //             "doc_number": request.employeeInfo.docNumber,
  //             "image": request.employeeInfo.imageUrl,
  //             "names": request.employeeInfo.names,
  //             "last_names": request.employeeInfo.lastNames,
  //             "phone": request.employeeInfo.phone,
  //             "id": request.employeeInfo.id,
  //           },
  //     "event_id": request.eventId,
  //     "event_number": request.eventName,
  //     "id": request.id,
  //     "year": request.year,
  //     "month": request.month,
  //     "week_start": request.startWeek,
  //     "week_end": request.endWeek,
  //   };
  // }
}
