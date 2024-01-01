import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';

import '../../../../features/employees/domain/entities/employee_entity.dart';
import 'employe_availability.dart';

class AvaliabilityScreen extends StatelessWidget {
  final ScreenSize screenSize;
  final EmployeesProvider employeesProvider;
  final Employee employee;
  const AvaliabilityScreen({
    Key? key,
    required this.screenSize,
    required this.employeesProvider,
    required this.employee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 20,
        crossAxisAlignment: WrapCrossAlignment.start,
        direction: Axis.horizontal,
        children: List.generate(
          employeesProvider.availabilityDays.length,
          (index) => AvaliabilityDayWidget(
            availabilityDay: employeesProvider.availabilityDays[index],
            screenSize: screenSize,
            index: index,
            onChange: (value, shift) {
              employeesProvider.updateDayValue(
                newValue: value,
                dayIndex: index,
                shift: shift,
                context: context,
                employee: employee,
              );
            },
          ),
        ),
      ),
    );
  }
}
