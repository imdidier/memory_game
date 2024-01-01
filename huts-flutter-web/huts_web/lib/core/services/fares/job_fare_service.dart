import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/auth/domain/entities/company.dart';
import 'package:huts_web/features/general_info/domain/entities/country_info_entity.dart';
import 'package:huts_web/features/requests/display/providers/create_event_provider.dart';

class JobFareService {
  static late Job currentJob;
  static late JobRequest currentJobRequest;
  static late DateTime currentStartDate;
  static late DateTime currentEndDate;
  static late bool currentHasDynamicFare;
  static late String currentClientId;
  static late CountryInfo currentCountryInfo;
  static bool dynamicWithoutRange = false;

  static Future<JobRequest> get(
    Job job,
    JobRequest jobRequest,
    DateTime startDate,
    DateTime endDate,
    bool hasDynamicFare,
    String clientId,
    CountryInfo countryInfo,
  ) async {
    currentJob = job;
    currentJobRequest = jobRequest;
    currentStartDate = DateTime(startDate.year, startDate.month, startDate.day,
        startDate.hour, startDate.minute, 0, 0);
    currentEndDate = endDate;
    currentHasDynamicFare = hasDynamicFare;
    currentClientId = clientId;
    currentCountryInfo = countryInfo;

    Map<String, dynamic> holidayResp = validateHoliDay();

    //When the workshift contains a holiday//
    if (holidayResp.isNotEmpty) {
      //When the holiday is the start workshift day//
      if (holidayResp["date"] == "start") {
        //When the workshift starts and ends in the same day//
        if (startDate.day == endDate.day) {
          //All workshift hours has holiday fare//
          return getOnlyHolidayJobRequest();
        }
        return await getDayHolidayJobRequest(fromStart: true);
      }
      //When the holiday is the end workshift day//
      return await getDayHolidayJobRequest(fromStart: false);
    }

    if (currentHasDynamicFare) {
      return await getDynamicFareJobRequest();
    }

    //When is not holiday and doesn't have dynamic fare//
    return await getOnlyNormalJobRequest();
  }

  static Map<String, dynamic> validateHoliDay() {
    String startFormat =
        "${CodeUtils.getFormatStringNum(currentStartDate.day)}-${CodeUtils.getFormatStringNum(currentStartDate.month)}";
    String endFormat =
        "${CodeUtils.getFormatStringNum(currentEndDate.day)}-${CodeUtils.getFormatStringNum(currentEndDate.month)}";

    if (currentCountryInfo.holidays.containsKey(startFormat)) {
      return {
        "holiday_info": currentCountryInfo.holidays[startFormat],
        "date": "start",
      };
    }
    if (currentCountryInfo.holidays.containsKey(endFormat)) {
      return {
        "holiday_info": currentCountryInfo.holidays[endFormat],
        "date": "end",
      };
    }

    return {};
  }

  static Future<JobRequest> getDynamicFareJobRequest() async {
    //Get client dynamic fare//
    double jobWeekHours = await getJobWeekHours();
    Map<String, dynamic> selectedFare = await getJobDynamicFare(jobWeekHours);

    double clientFare = selectedFare["client_fare"];
    double employeeFare = selectedFare["employee_fare"];

    double clientNormalFare = currentJob.fares["normal"]["client_fare"];
    double employeeNormalFare = currentJob.fares["normal"]["employee_fare"];

    //Get client night surcharge values//
    DocumentSnapshot<Map<String, dynamic>> clientDoc = await FirebaseServices.db
        .collection("clients")
        .doc(currentClientId)
        .get();

    Map<String, dynamic> clientData = clientDoc.data()!;

    double surchargePercent =
        clientData["night_workshift"]["surcharge"].toDouble();

    //Set totals initial values//
    double totalToPayPerEmployee = 0;
    double totalToPayClientPerEmployee = 0;

    double employeeTotalNightSurcharge = 0;
    double clientTotalNightSurcharge = 0;

    double requestHours = currentJobRequest.employeeHours;

    //Get request hours with surcharge
    double hoursWithSurcharge = getHoursWithNightSurcharge(
      nightStartHour: clientData["night_workshift"]["start_hour"].toInt(),
      nightStartMinutes: clientData["night_workshift"]["start_minutes"].toInt(),
      nightEndHour: clientData["night_workshift"]["end_hour"].toInt(),
      nightEndtMinutes: clientData["night_workshift"]["end_minutes"].toInt(),
    );

    //calculate total values

    double normalHours = requestHours - hoursWithSurcharge;

    double clientSurcharge = clientNormalFare * surchargePercent;
    double employeeSurcharge = employeeNormalFare * surchargePercent;

    employeeTotalNightSurcharge = employeeSurcharge * hoursWithSurcharge;
    clientTotalNightSurcharge = clientSurcharge * hoursWithSurcharge;

    totalToPayClientPerEmployee = clientTotalNightSurcharge +
        (hoursWithSurcharge * clientFare) +
        (normalHours * clientFare);

    currentJobRequest.totalToPayClient =
        totalToPayClientPerEmployee * currentJobRequest.employeesNumber;

    currentJobRequest.totalToPayClientPerEmployee = totalToPayClientPerEmployee;

    totalToPayPerEmployee = employeeTotalNightSurcharge +
        (hoursWithSurcharge * employeeFare) +
        (normalHours * employeeFare);

    currentJobRequest.totalToPayEmployee = totalToPayPerEmployee;

    currentJobRequest.totalToPayAllEmployees =
        totalToPayPerEmployee * currentJobRequest.employeesNumber;

    currentJobRequest.totalClientNightSurcharge = clientTotalNightSurcharge;
    currentJobRequest.totalEmployeeNightSurcharge = employeeTotalNightSurcharge;

    currentJobRequest.fareType = dynamicWithoutRange ? "Normal" : "Dinámica";
    dynamicWithoutRange = false;

    currentJobRequest.employeeFare.dynamicFare = {
      "fare": employeeFare,
      "hours": currentJobRequest.employeeHours,
      "total_night_surcharge": employeeTotalNightSurcharge,
      "total_to_pay": totalToPayPerEmployee,
      "fare_name": selectedFare["name"],
    };

    currentJobRequest.clientFare.dynamicFare = {
      "fare": clientFare,
      "hours": currentJobRequest.employeeHours,
      "total_night_surcharge": clientTotalNightSurcharge,
      "total_to_pay": totalToPayClientPerEmployee,
      "fare_name": selectedFare["name"],
    };

    return currentJobRequest;
  }

  static JobRequest getOnlyHolidayJobRequest() {
    double clientFare = currentJob.fares["holiday"]["client_fare"];
    double employeeFare = currentJob.fares["holiday"]["employee_fare"];
    String fareName = currentJob.fares["holiday"]["name"];

    currentJobRequest.employeeFare.holidayFare = {
      "fare": employeeFare,
      "hours": currentJobRequest.employeeHours,
      "total_to_pay": employeeFare * currentJobRequest.employeeHours,
      "fare_name": fareName,
    };

    currentJobRequest.clientFare.holidayFare = {
      "fare": clientFare,
      "hours": currentJobRequest.employeeHours,
      "total_to_pay": clientFare * currentJobRequest.employeeHours,
      "fare_name": fareName,
    };

    currentJobRequest.totalToPayClient = clientFare *
        (currentJobRequest.employeesNumber * currentJobRequest.employeeHours);
    currentJobRequest.totalToPayClientPerEmployee =
        clientFare * currentJobRequest.employeeHours;

    currentJobRequest.totalToPayEmployee =
        employeeFare * currentJobRequest.employeeHours;

    currentJobRequest.totalToPayAllEmployees =
        (employeeFare * currentJobRequest.employeeHours) *
            currentJobRequest.employeesNumber;

    currentJobRequest.fareType = "Festiva";

    return currentJobRequest;
  }

  static Future<JobRequest> getOnlyNormalJobRequest() async {
    //Get general normal fare//
    double clientFare = currentJob.fares["normal"]["client_fare"];
    double employeeFare = currentJob.fares["normal"]["employee_fare"];
    String fareName = currentJob.fares["normal"]["name"];

    //Get general night surcharge values//
    DocumentSnapshot<Map<String, dynamic>> countryInfoDoc =
        await FirebaseServices.db
            .collection("countries_info")
            .doc("costa_rica")
            .get();

    Map<String, dynamic> countryInfoDocData = countryInfoDoc.data()!;

    double surchargePercent =
        countryInfoDocData["night_workshift"]["surcharge"].toDouble();

    //Set totals initial values//
    double totalToPayPerEmployee = 0;
    double totalToPayClientPerEmployee = 0;

    double employeeTotalNightSurcharge = 0;
    double clientTotalNightSurcharge = 0;

    double requestHours = currentJobRequest.employeeHours;

    //Get request hours with surcharge

    double hoursWithSurcharge = getHoursWithNightSurcharge(
        nightStartHour:
            countryInfoDocData["night_workshift"]["start_hour"].toInt(),
        nightStartMinutes:
            countryInfoDocData["night_workshift"]["start_minutes"].toInt(),
        nightEndHour: countryInfoDocData["night_workshift"]["end_hour"].toInt(),
        nightEndtMinutes:
            countryInfoDocData["night_workshift"]["end_minutes"].toInt());

    //calculate total values
    double normalHours = requestHours - hoursWithSurcharge;

    double clientSurcharge = clientFare * surchargePercent;
    double employeeSurcharge = employeeFare * surchargePercent;

    employeeTotalNightSurcharge = employeeSurcharge * hoursWithSurcharge;
    clientTotalNightSurcharge = clientSurcharge * hoursWithSurcharge;

    totalToPayClientPerEmployee = clientTotalNightSurcharge +
        (hoursWithSurcharge * clientFare) +
        (normalHours * clientFare);

    currentJobRequest.totalToPayClient =
        totalToPayClientPerEmployee * currentJobRequest.employeesNumber;

    currentJobRequest.totalToPayClientPerEmployee = totalToPayClientPerEmployee;

    totalToPayPerEmployee = employeeTotalNightSurcharge +
        (hoursWithSurcharge * employeeFare) +
        (normalHours * employeeFare);

    currentJobRequest.totalToPayEmployee = totalToPayPerEmployee;

    currentJobRequest.totalToPayAllEmployees =
        totalToPayPerEmployee * currentJobRequest.employeesNumber;

    currentJobRequest.fareType = "Normal";

    currentJobRequest.totalClientNightSurcharge = clientTotalNightSurcharge;
    currentJobRequest.totalEmployeeNightSurcharge = employeeTotalNightSurcharge;

    currentJobRequest.employeeFare.normalFare = {
      "fare": employeeFare,
      "hours": currentJobRequest.employeeHours,
      "total_night_surcharge": employeeTotalNightSurcharge,
      "total_to_pay": totalToPayPerEmployee,
      "fare_name": fareName,
    };
    currentJobRequest.clientFare.normalFare = {
      "fare": clientFare,
      "hours": currentJobRequest.employeeHours,
      "total_night_surcharge": clientTotalNightSurcharge,
      "total_to_pay": totalToPayClientPerEmployee,
      "fare_name": fareName,
    };

    return currentJobRequest;
  }

  static Future<JobRequest> getDayHolidayJobRequest({
    required bool fromStart,
  }) async {
    DateTime auxiliarStartDate = DateTime(currentStartDate.year,
        currentStartDate.month, currentStartDate.day, 23, 59);

    double startDayHours = CodeUtils.minutesToHours(
      auxiliarStartDate.difference(currentStartDate).inMinutes,
    );

    DateTime auxiliarEndDate = DateTime(
        currentEndDate.year, currentEndDate.month, currentEndDate.day, 0, 00);

    double endDayHours = CodeUtils.minutesToHours(
      currentEndDate.difference(auxiliarEndDate).inMinutes,
    );

    double clientHolidayFare = currentJob.fares["holiday"]["client_fare"];
    double employeeHolidayFare = currentJob.fares["holiday"]["employee_fare"];

    String holidayFareName = currentJob.fares["holiday"]["name"];

    bool isDynamic = false;

    double clientFare;
    double employeeFare;
    String fareName;

    if (!currentHasDynamicFare) {
      clientFare = currentJob.fares["normal"]["client_fare"];
      employeeFare = currentJob.fares["normal"]["employee_fare"];
      fareName = currentJob.fares["normal"]["name"];
    } else {
      double jobWeekHours = await getJobWeekHours();
      Map<String, dynamic> selectedFare = await getJobDynamicFare(jobWeekHours);
      clientFare = selectedFare["client_fare"];
      employeeFare = selectedFare["employee_fare"];
      fareName = selectedFare["name"];
      isDynamic = true;
    }

    currentJobRequest.employeeFare.holidayFare = {
      "fare": employeeHolidayFare,
      "hours": (fromStart) ? startDayHours : endDayHours,
      "total_to_pay": (fromStart)
          ? employeeHolidayFare * startDayHours
          : employeeHolidayFare * endDayHours,
      "fare_name": holidayFareName,
    };

    currentJobRequest.clientFare.holidayFare = {
      "fare": clientHolidayFare,
      "hours": (fromStart) ? startDayHours : endDayHours,
      "total_to_pay": (fromStart)
          ? clientHolidayFare * startDayHours
          : clientHolidayFare * endDayHours,
      "fare_name": holidayFareName,
    };

    if (isDynamic) {
      currentJobRequest.employeeFare.dynamicFare = {
        "fare": employeeFare,
        "hours": (fromStart) ? endDayHours : startDayHours,
        "total_to_pay": (fromStart)
            ? employeeFare * endDayHours
            : employeeFare * startDayHours,
        "fare_name": fareName,
      };

      currentJobRequest.clientFare.dynamicFare = {
        "fare": clientFare,
        "hours": (fromStart) ? endDayHours : startDayHours,
        "total_to_pay":
            (fromStart) ? clientFare * endDayHours : clientFare * startDayHours,
        "fare_name": fareName,
      };
    } else {
      currentJobRequest.employeeFare.normalFare = {
        "fare": employeeFare,
        "hours": (fromStart) ? endDayHours : startDayHours,
        "total_to_pay": (fromStart)
            ? employeeFare * endDayHours
            : employeeFare * startDayHours,
        "fare_name": fareName,
      };

      currentJobRequest.clientFare.normalFare = {
        "fare": clientFare,
        "hours": (fromStart) ? endDayHours : startDayHours,
        "total_to_pay":
            (fromStart) ? clientFare * endDayHours : clientFare * startDayHours,
        "fare_name": fareName,
      };
    }

    double parcialPayment = (isDynamic)
        ? currentJobRequest.clientFare.dynamicFare["total_to_pay"]
        : currentJobRequest.clientFare.normalFare["total_to_pay"];

    double parcialEmployeePayment = (isDynamic)
        ? currentJobRequest.employeeFare.dynamicFare["total_to_pay"]
        : currentJobRequest.employeeFare.normalFare["total_to_pay"];

    currentJobRequest.totalToPayClient = (parcialPayment +
            currentJobRequest.clientFare.holidayFare["total_to_pay"]) *
        currentJobRequest.employeesNumber;

    currentJobRequest.totalToPayClientPerEmployee = parcialPayment +
        currentJobRequest.clientFare.holidayFare["total_to_pay"];

    currentJobRequest.totalToPayEmployee = parcialEmployeePayment +
        currentJobRequest.employeeFare.holidayFare["total_to_pay"];

    currentJobRequest.totalToPayAllEmployees = (parcialEmployeePayment +
            currentJobRequest.employeeFare.holidayFare["total_to_pay"]) *
        currentJobRequest.employeesNumber;

    String secondFareType = (isDynamic) ? "Dinámica" : "Normal";

    currentJobRequest.fareType = "Festiva - $secondFareType";

    return currentJobRequest;
  }

  static Future<double> getJobWeekHours() async {
    String jobRequestWeekCut = CodeUtils().getCutOffWeek(currentStartDate);

    double jobWeekHours = 0;

    QuerySnapshot eventsQuery = await FirebaseServices.db
        .collection("events")
        .where("client_info.id", isEqualTo: currentClientId)
        .where("year", isEqualTo: currentStartDate.year)
        .where("month", isEqualTo: currentStartDate.month)
        .where("week_cut", isEqualTo: jobRequestWeekCut)
        .get();

    for (var i = 0; i < eventsQuery.docs.length; i++) {
      Map<String, dynamic> eventData =
          eventsQuery.docs[i].data() as Map<String, dynamic>;
      if (!eventData["employees_info"]["jobs_needed"]
          .containsKey(currentJob.value)) {
        continue;
      }
      jobWeekHours += eventData["employees_info"]["jobs_needed"]
          [currentJob.value]["total_hours"];
    }
    if (jobWeekHours == 0) jobWeekHours = 1;
    return jobWeekHours;
  }

  static Future<Map<String, dynamic>> getJobDynamicFare(
      double jobWeekHours) async {
    Map<String, dynamic> selectedFare = {};

    dynamicWithoutRange = false;

    for (String key in currentJob.fares["dynamic"].keys) {
      Map<String, dynamic> dynamicFare = currentJob.fares["dynamic"][key];
      if (key.contains("-")) {
        List<String> rangeArray = key.split("-");
        int fromValue = int.parse(rangeArray[0]);
        int toValue = int.parse(rangeArray[1]);
        if (jobWeekHours >= fromValue && jobWeekHours <= toValue) {
          selectedFare = dynamicFare;
          dynamicWithoutRange = false;
          break;
        } else {
          dynamicWithoutRange = true;
        }
      } else {
        int maxValue = int.parse(key);
        if (jobWeekHours >= maxValue) {
          selectedFare = dynamicFare;
          dynamicWithoutRange = false;
          break;
        } else {
          dynamicWithoutRange = true;
        }
      }
    }

    if (dynamicWithoutRange) selectedFare = currentJob.fares["normal"];
    if (currentJob.fares['dynamic'].keys.isEmpty) {
      selectedFare = currentJob.fares["normal"];
    }
    return selectedFare;
  }

  static double getHoursWithNightSurcharge({
    required int nightStartHour,
    required int nightStartMinutes,
    required int nightEndHour,
    required int nightEndtMinutes,
  }) {
    try {
      double resultHours = 0;

      bool requestStartsBeforeNightRange =
          currentStartDate.hour < nightStartHour &&
              currentStartDate.hour < nightEndHour;
      bool requestStartsInNightRange = currentStartDate.hour >= nightStartHour;
      bool nightRangeTakesOtherDay = nightEndHour < nightStartHour;

      double requestDuration = currentJobRequest.employeeHours;
      List<String> splitedRequestDuration =
          requestDuration.toString().split(".");

      int requestHours = int.parse(splitedRequestDuration[0]);
      double extraRequestHours = splitedRequestDuration.length > 1 ? 0.5 : 0;

      DateTime currentDate = currentStartDate;

      int splittedMinutes = 0;

      if (currentDate.minute > 0) {
        //&& currentDate.hour > nightEndHour) {
        splittedMinutes = 30;
        currentDate = currentDate.subtract(const Duration(minutes: 30));
      }
      if ((requestStartsInNightRange && nightRangeTakesOtherDay)) {
        DateTime firstStartNightDate = DateTime(
          currentStartDate.year,
          currentStartDate.month,
          currentStartDate.day,
          nightStartHour,
          nightStartMinutes,
        );

        DateTime firstEndNightDate = DateTime(
          currentStartDate.year,
          currentStartDate.month,
          currentStartDate.day + 1,
          nightEndHour,
          nightEndtMinutes,
        );

        DateTime secondStartNightDate = DateTime(
          currentEndDate.year,
          currentEndDate.month,
          currentEndDate.day,
          nightStartHour,
          nightStartMinutes,
        );

        DateTime secondEndNightDate = DateTime(
          currentEndDate.year,
          currentEndDate.month,
          currentEndDate.day + 1,
          nightEndHour,
          nightEndtMinutes,
        );

        for (var i = 0; i < requestHours; i++) {
          currentDate = currentDate.add(const Duration(hours: 1));

          bool isInFirstRange = currentDate.isAfter(firstStartNightDate) &&
              (currentDate.isBefore(firstEndNightDate) ||
                  currentDate.isAtSameMomentAs(firstEndNightDate));

          bool isInSecondRange = currentDate.isAfter(secondStartNightDate) &&
              (currentDate.isBefore(secondEndNightDate) ||
                  currentDate.isAtSameMomentAs(secondEndNightDate));

          if (isInFirstRange || isInSecondRange) {
            resultHours += 1;
          }
        }

        if (splittedMinutes > 0 && requestHours < 24) {
          currentDate = currentDate.add(const Duration(minutes: 30));

          bool isInFirstRange = currentDate.isAfter(firstStartNightDate) &&
              (currentDate.isBefore(firstEndNightDate) ||
                  currentDate.isAtSameMomentAs(firstEndNightDate));

          bool isInSecondRange = currentDate.isAfter(secondStartNightDate) &&
              (currentDate.isBefore(secondEndNightDate) ||
                  currentDate.isAtSameMomentAs(secondEndNightDate));

          if (isInFirstRange || isInSecondRange) {
            resultHours += 0.5;
          }
          if (currentDate.isAtSameMomentAs(currentEndDate)) {
            resultHours -= 0.5;
          }
        }

        if ((extraRequestHours > 0 && (currentDate.isBefore(currentEndDate)) ||
            splittedMinutes == 0)) {
          currentDate = currentDate.add(const Duration(minutes: 30));

          bool isInFirstRange = currentDate.isAfter(firstStartNightDate) &&
              (currentDate.isBefore(firstEndNightDate) ||
                  currentDate.isAtSameMomentAs(firstEndNightDate));

          bool isInSecondRange = currentDate.isAfter(secondStartNightDate) &&
              (currentDate.isBefore(secondEndNightDate) ||
                  currentDate.isAtSameMomentAs(secondEndNightDate));

          if (isInFirstRange || isInSecondRange) {
            resultHours += extraRequestHours;
          }
          if (currentDate.isAtSameMomentAs(currentEndDate) &&
              splittedMinutes != 0) {
            resultHours -= 0.5;
          }
        }
        return resultHours;
      } else if ((requestStartsBeforeNightRange && nightRangeTakesOtherDay)) {
        DateTime firstStartNightDate = DateTime(
          currentStartDate.year,
          currentStartDate.month,
          currentStartDate.day - 1,
          23,
          59,
        );

        DateTime firstEndNightDate = DateTime(
          currentStartDate.year,
          currentStartDate.month,
          currentStartDate.day,
          nightEndHour,
          nightEndtMinutes,
        );

        DateTime secondStartNightDate = DateTime(
          currentStartDate.year,
          currentStartDate.month,
          currentStartDate.day,
          nightStartHour,
          nightStartMinutes,
        );

        DateTime secondEndNightDate = DateTime(
          currentStartDate.year,
          currentStartDate.month,
          currentStartDate.day + 1,
          nightEndHour,
          nightEndtMinutes,
        );

        for (var i = 0; i < requestHours; i++) {
          currentDate = currentDate.add(const Duration(hours: 1));

          bool isInFirstRange = currentDate.isAfter(firstStartNightDate) &&
              (currentDate.isBefore(firstEndNightDate) ||
                  currentDate.isAtSameMomentAs(firstEndNightDate));

          bool isInSecondRange = currentDate.isAfter(secondStartNightDate) &&
              (currentDate.isBefore(secondEndNightDate) ||
                  currentDate.isAtSameMomentAs(secondEndNightDate));

          if (isInFirstRange || isInSecondRange) {
            resultHours += 1;
          }
        }
        if (splittedMinutes > 0) {
          currentDate = currentDate.add(const Duration(minutes: 30));

          bool isInFirstRange = currentDate.isAfter(firstStartNightDate) &&
              (currentDate.isBefore(firstEndNightDate) ||
                  currentDate.isAtSameMomentAs(firstEndNightDate));

          bool isInSecondRange = currentDate.isAfter(secondStartNightDate) &&
              (currentDate.isBefore(secondEndNightDate) ||
                  currentDate.isAtSameMomentAs(secondEndNightDate));

          if (isInFirstRange || isInSecondRange) {
            resultHours += 0.5;
          }
          if (!isInFirstRange || isInSecondRange) {
            resultHours -= 0.5;
          }
        }

        if (extraRequestHours > 0 && currentDate.isBefore(currentEndDate)) {
          currentDate = currentDate.add(const Duration(minutes: 30));

          bool isInFirstRange = currentDate.isAfter(firstStartNightDate) &&
              (currentDate.isBefore(firstEndNightDate) ||
                  currentDate.isAtSameMomentAs(firstEndNightDate));

          bool isInSecondRange = currentDate.isAfter(secondStartNightDate) &&
              (currentDate.isBefore(secondEndNightDate) ||
                  currentDate.isAtSameMomentAs(secondEndNightDate));

          if (isInFirstRange || isInSecondRange) {
            resultHours += extraRequestHours;
          }
          // if (!isInFirstRange || isInSecondRange) {
          //   resultHours -= 0.5;
          // }
        }

        return resultHours;
      }

      DateTime startNightDate = DateTime(
        currentStartDate.year,
        currentStartDate.month,
        currentStartDate.day,
        nightStartHour,
        nightStartMinutes,
      );

      DateTime endNightDate = startNightDate;

      if (nightEndHour > nightStartHour) {
        endNightDate = DateTime(
          currentStartDate.year,
          currentStartDate.month,
          currentStartDate.day,
          nightEndHour,
          nightEndtMinutes,
        );
      } else {
        endNightDate = DateTime(
          endNightDate.year,
          endNightDate.month,
          endNightDate.day + 1,
          nightEndHour,
          nightEndtMinutes,
        );
      }

      for (var i = 0; i < requestHours; i++) {
        currentDate = currentDate.add(const Duration(hours: 1));

        if (currentDate.isAfter(startNightDate) &&
            (currentDate.isBefore(endNightDate) ||
                currentDate.isAtSameMomentAs(endNightDate))) {
          resultHours += 1;
        }
      }

      if (splittedMinutes > 0) {
        currentDate = currentDate.add(const Duration(minutes: 30));

        if (currentDate.isAfter(startNightDate) &&
            (currentDate.isBefore(endNightDate) ||
                currentDate.isAtSameMomentAs(endNightDate))) {
          resultHours += 0.5;
        }
      }

      if (extraRequestHours > 0 && currentDate.isBefore(currentEndDate)) {
        currentDate = currentDate.add(const Duration(minutes: 30));
        if (currentDate.isAfter(startNightDate) &&
            (currentDate.isBefore(endNightDate) ||
                currentDate.isAtSameMomentAs(endNightDate))) {
          resultHours += extraRequestHours;
        }
      }

      return resultHours;

      // double requestHoursDuration = currentJobRequest.employeeHours;

      // double requestStartHours = CodeUtils.minutesToHours(
      //     (currentStartDate.hour * 60) + currentStartDate.minute);

      // //The following variables have those generic names just for make it easier to read//

      // //The A variable is the difference between nightStartHours and requestStartHours. To be used it should be grater than 0 //
      // double A = nightStartHours - requestStartHours;

      // if (A < 0) A = 0;

      // //The B variable is the difference between nightEndHours and requestStartHours. To be used it should be grater than 0 and requestStartHours should be less than nightStartHours //
      // double B = nightEndHours - requestStartHours;

      // if (!(B > 0 && requestStartHours < nightStartHours)) {
      //   B = 0;
      // }
      // double resultHours = requestHoursDuration - A + B;

      // return (resultHours < 0)
      //     ? 0
      //     : resultHours <= requestHoursDuration
      //         ? resultHours
      //         : 0;
    } catch (e) {
      if (kDebugMode) {
        print("JobFareService, getHoursWithNightSurcharge error: $e ");
      }

      return 0;
    }
  }
}
