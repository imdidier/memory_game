import 'package:flutter/material.dart';
import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';
import 'package:huts_web/features/general_info/domain/entities/country_info_entity.dart';

class DocsServices {
  static EmployeeDocsStatus getStatus(
      Employee employee, CountryInfo countryInfo) {
    //Get platform required docs//
    Map<String, dynamic> platformRequiredDocs = Map.fromEntries(
      countryInfo.requiredDocs.entries.expand(
        (element) => [
          if (element.value["required"]) MapEntry(element.key, element.value)
        ],
      ),
    );

    //Get required docs by employee jobs//
    List<Map<String, dynamic>> employeeRequiredDocs = [];

    for (String employeeJobValue in employee.jobs) {
      platformRequiredDocs.forEach((key, value) {
        if (value["jobs"].contains(employeeJobValue) &&
            !employeeRequiredDocs.any(
                (Map<String, dynamic> element) => element.keys.first == key)) {
          employeeRequiredDocs.add({key: value});
        }
      });
    }

    //Get employee added required docs//
    Map<String, dynamic> employeeAddedDocs = Map.fromEntries(
      employee.documents.entries.expand(
        (element) => [
          if (element.value["file_url"] != null &&
              element.value["file_url"] != "" &&
              element.value["required"] != null &&
              element.value["required"])
            MapEntry(element.key, element.value)
        ],
      ),
    );

    ///Compare employee required docs with added docs
    int value = 0;
    String text = "Sin documentos";
    Color color = Colors.red;

    if (employeeAddedDocs.isNotEmpty) {
      if (employeeAddedDocs.length < employeeRequiredDocs.length) {
        double percentage = double.parse(
            ((employeeAddedDocs.length * 100) / platformRequiredDocs.length)
                .toStringAsFixed(1));

        ///  employeeRequiredDocs.length -> 100%
        ///  employeeAddedDocs.length -> ?

        value = 1;
        text = "Incompleto: $percentage%";
        color = Colors.yellow;
      }

      if (employeeAddedDocs.length >= employeeRequiredDocs.length) {
        value = 2;
        text = "Completo";
        color = Colors.green;
      }
    }

    return EmployeeDocsStatus(
      value: value,
      text: text,
      widget: Chip(
        backgroundColor: color,
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
