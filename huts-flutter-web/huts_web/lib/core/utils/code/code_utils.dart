import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/requests/domain/entities/request_entity.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CodeUtils {
  CodeUtils._privateConstructor();

  static final CodeUtils _intance = CodeUtils._privateConstructor();

  factory CodeUtils() {
    return _intance;
  }

  static Map<int, dynamic> employeeStatus = {
    0: {"name": "Por aprobar", "color": Colors.yellow, "value": 0},
    1: {"name": "Disponible", "color": Colors.green, "value": 1},
    2: {"name": "En turno", "color": Colors.blue, "value": 2},
    3: {"name": "Bloqueado", "color": Colors.red, "value": 3},
    4: {"name": "Perfil rechazado", "color": Colors.orange, "value": 4},
    5: {"name": "Deshabilitado por admin", "color": Colors.grey, "value": 5},
    6: {"name": "Deshabilitado por horas", "color": Colors.orange, "value": 6},
    7: {"name": "Documento vencido", "color": Colors.orange, "value": 7},
  };

  static final NumberFormat formater = NumberFormat("#,##0", "es_CR");

  static String formatMoney(double value) => "₡${formater.format(value)}";

  static bool checkValidEmail(String email) {
    email = email.toLowerCase().trim();
    return RegExp(
            r"^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
        .hasMatch(email);
  }

  static String formatDate(DateTime date) =>
      DateFormat("dd/MM/yyyy HH:mm").format(date);

  static String formatDateWithoutHour(DateTime date) =>
      DateFormat("dd/MM/yyyy").format(date);

  static String getFormatedName(String names, String lastNames) => (names
          .isNotEmpty)
      ? "$names $lastNames" //"${names.split(" ")[0]} ${lastNames.split(" ")[0]}"
      : "Sin asignar";

  static String getMessageTypeName(String type) {
    return (type == "admin-jobs")
        ? "Admin - cargos"
        : type == "admin-employees"
            ? "Admin - colaboradores"
            : "cliente - evento";
  }

  static String getEmployeeStatusName(int status) =>
      employeeStatus.containsKey(status)
          ? employeeStatus[status]["name"]
          : "Desconocido";

  static Color getEmployeeStatusColor(int status) =>
      employeeStatus.containsKey(status)
          ? employeeStatus[status]["color"]
          : Colors.purple;

  static String getStatusName(int status) {
    switch (status) {
      case 0:
        return "Pendiente";

      case 1:
        return "Asignada";

      case 2:
        return "Aceptada";

      case 3:
        return "Activa";

      case 4:
        return "Finalizada";

      case 5:
        return "Cancelada";

      case 6:
        return "Rechazada";

      default:
        return "Desconocido";
    }
  }

  static String getWebUserSubtypeName(String subtypeKey,
      {String type = "admin"}) {
    BuildContext? context = NavigationService.getGlobalContext();

    if (context == null) return subtypeKey;

    GeneralInfoProvider generalInfoProvider =
        Provider.of<GeneralInfoProvider>(context, listen: false);

    if (!generalInfoProvider.otherInfo.systemRoles.containsKey(type)) {
      return subtypeKey;
    }

    return Provider.of<GeneralInfoProvider>(context, listen: false)
        .otherInfo
        .systemRoles[type][subtypeKey]["name"];
  }

  static String getWebUserTypeName(String typeKey) {
    if (typeKey == "admin") {
      return "Administrador";
    }
    if (typeKey == "client") {
      return "Cliente";
    } else {
      return "Super administrador";
    }
  }

  static String getEventStatusName(int status) {
    switch (status) {
      case 1:
        return "Pendiente";

      case 2:
        return "Aceptado";

      case 3:
        return "Activo";

      case 4:
        return "Finalizado";

      case 5:
        return "Cancelado";

      default:
        return "Desconocido";
    }
  }

  static Color getStatusColor(int status, bool fromRequest) {
    switch (status) {
      case 0: //pending
        return Colors.yellow;

      case 1: //pending
        return Colors.yellow;

      case 2: // accepted
        return Colors.blue;

      case 3: // active
        return Colors.green;

      case 4: //finished
        return Colors.red;

      case 5: //finished
        return Colors.red;

      case 6: // rejected or canceled
        return Colors.red;

      default:
        return Colors.white;
    }
  }

  static getDatesByWeek(String week, DateTime selectedDate) {
    if (kDebugMode) {
      print("getDatesByWeek");
      print("selectedDate: $selectedDate");
      print("week: $week");
    }

    DateTime date = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
    List weekDays = week.split("-");
    int startDay = int.parse(weekDays[0]);
    int endDay = int.parse(weekDays[1]);
    DateTime finalStartDate = DateTime.now();
    DateTime finalEndDate = DateTime.now();
    DateTime finalStartDateMonth = DateTime.now();
    DateTime finalEndDateMonth = DateTime.now();
    if (startDay > endDay) {
      //Puede ser del mes anterior o finalizando el actual
      if (selectedDate.day < 15) {
        finalStartDate = DateTime(date.year, date.month - 1, startDay, 0, 0, 0);
        finalEndDate = DateTime(date.month, date.month, endDay, 23, 59, 59);
      } else {
        finalStartDate = DateTime(date.year, date.month, startDay, 0, 0, 0);
        finalEndDate = DateTime(date.year, date.month + 1, endDay, 23, 59, 59);
      }
    } else {
      finalStartDate = DateTime(date.year, date.month, startDay, 0, 0, 0);
      finalEndDate = DateTime(date.year, date.month, endDay, 23, 59, 59);
    }
    //Mes
    finalStartDateMonth = DateTime(date.year, date.month, 1, 0, 0, 0);
    finalEndDateMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

    if (kDebugMode) {
      print("finalStartDate: $finalStartDate");
      print("finalEndDate: $finalEndDate");
      print("finalStartDateMonth: $finalStartDateMonth");
      print("finalEndDateMonth: $finalEndDateMonth");
    }
    return [
      finalStartDate,
      finalEndDate,
      finalStartDateMonth,
      finalEndDateMonth
    ];
  }

  String getCutOffWeek(DateTime date) {
    String startDay = DateFormat('EEEE').format(date);

    DateTime finalStartDate = DateTime.now();
    DateTime finalEndDate = DateTime.now();
    if (startDay == "Monday") {
      finalStartDate = date.subtract(const Duration(days: 3));
      finalEndDate = date.add(const Duration(days: 3));
    } else if (startDay == "Tuesday") {
      finalStartDate = date.subtract(const Duration(days: 4));
      finalEndDate = date.add(const Duration(days: 2));
    } else if (startDay == "Wednesday") {
      finalStartDate = date.subtract(const Duration(days: 5));
      finalEndDate = date.add(const Duration(days: 1));
    } else if (startDay == "Thursday") {
      finalStartDate = date.subtract(const Duration(days: 6));
      finalEndDate = date.add(const Duration(days: 0));
    } else if (startDay == "Friday") {
      finalStartDate = date.subtract(const Duration(days: 0));
      finalEndDate = date.add(const Duration(days: 6));
    } else if (startDay == "Saturday") {
      finalStartDate = date.subtract(const Duration(days: 1));
      finalEndDate = date.add(const Duration(days: 5));
    } else if (startDay == "Sunday") {
      finalStartDate = date.subtract(const Duration(days: 2));
      finalEndDate = date.add(const Duration(days: 4));
    }
    int start = finalStartDate.day;
    int end = finalEndDate.day;
    if (kDebugMode) {
      print("Fecha final: $end");
      print("WEEK CUTOFF: $start - $end");
    }

    return "$start-$end";
  }

  String formatYearMonthDate(DateTime date) {
    int monthIndex = date.month;
    String year = date.year.toString();
    String month = (monthIndex + 1 < 10)
        ? "0${monthIndex + 1}"
        : (monthIndex + 1).toString();
    return "$year-$month";
  }

  static double minutesToHours(int minutes) {
    double hours = double.parse((minutes / 60).toStringAsFixed(2));

    List<String> stringArrayHours = hours.toString().split(".");

    if (stringArrayHours.length > 1) {
      if (double.parse(stringArrayHours[1]) > 50) {
        hours = double.parse(stringArrayHours[0]) + 1;
      } else if (double.parse(stringArrayHours[1]) < 50) {
        hours = double.parse("${stringArrayHours[0]}.5");
      }
    }

    return hours;
  }

  static String getFormatStringNum(int num) => (num >= 10) ? "$num" : "0$num";

  static Future<void> launchURL(String url) async {
    try {
      if (!await canLaunchUrl(Uri.parse(url))) throw 'Could not launch $url';
      await launchUrl(
        Uri.parse(url),
      );
    } catch (e) {
      if (kDebugMode) print("CodeUtils, launchUrl error: $e");
    }
  }

  static String getFileTypeFromUrl(String url) {
    if (url.contains("image-")) return "image";
    if (url.contains("pdf-")) return "pdf";
    if (url.contains("excel-")) return "excel";
    if (url.contains("excelx-")) return "excel";
    return "word";
  }

  static double getRequestFarePerHour({
    required Request request,
    required bool isClient,
    double? hours,
  }) {
    if (isClient) {
      return double.parse(((request.details.fare.totalClientPays -
                  request.details.fare.totalClientNightSurcharge) /
              (hours ?? request.details.totalHours))
          .toStringAsFixed(0));
    }
    return double.parse(((request.details.fare.totalToPayEmployee -
                request.details.fare.totalEmployeeNightSurcharge) /
            (hours ?? request.details.totalHours))
        .toStringAsFixed(0));
  }

  static double getRequestNightSurcharge({
    required Request request,
    required bool isClient,
  }) {
    if (isClient) {
      return request.details.fare.totalClientNightSurcharge;
    }
    return request.details.fare.totalEmployeeNightSurcharge;
  }
}
