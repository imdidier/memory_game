import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:provider/provider.dart';

import '../../../../features/employees/domain/entities/available_day.dart';

class AvaliabilityDayWidget extends StatelessWidget {
  final AvailableDay availabilityDay;
  final ScreenSize screenSize;
  final int index;
  final Function(bool, int) onChange;
  const AvaliabilityDayWidget(
      {Key? key,
      required this.availabilityDay,
      required this.screenSize,
      required this.index,
      required this.onChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    EmployeesProvider employeesProvider =
        Provider.of<EmployeesProvider>(context);
    return Container(
      padding: const EdgeInsets.all(15),
      margin: EdgeInsets.only(
        top: screenSize.absoluteHeight * 0.012,
        bottom: screenSize.absoluteHeight * 0.03,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            blurRadius: 2,
            color: Colors.black12,
            offset: Offset(0, 2),
          )
        ],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            availabilityDay.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        color: Colors.red,
                        size: screenSize.width * 0.02,
                      ),
                      const SizedBox(width: 5),
                      Transform.scale(
                        scale: 0.75,
                        child: CupertinoSwitch(
                          value: availabilityDay.morningShiftEnabled,
                          activeColor: Colors.red,
                          onChanged: (newValue) {
                            UiMethods().showLoadingDialog(context: context);
                            if (!employeesProvider.isUpdating) {
                              onChange(newValue, 0);
                            }
                            employeesProvider.showEmployeeDetails(
                                employee: employeesProvider.selectedEmployee!);
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Jornada de\nmañana",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.cloud_queue_sharp,
                        color: Colors.red,
                        size: screenSize.width * 0.02,
                      ),
                      const SizedBox(width: 5),
                      Transform.scale(
                        scale: 0.75,
                        child: CupertinoSwitch(
                          value: availabilityDay.afternoonShiftEnabled,
                          activeColor: Colors.red,
                          onChanged: (newValue) {
                            UiMethods().showLoadingDialog(context: context);
                            if (!employeesProvider.isUpdating) {
                              onChange(newValue, 1);
                            }
                            employeesProvider.showEmployeeDetails(
                                employee: employeesProvider.selectedEmployee!);
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Jornada de\ntarde",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.nightlight_outlined,
                        color: Colors.red,
                        size: screenSize.width * 0.02,
                      ),
                      const SizedBox(width: 5),
                      Transform.scale(
                        scale: 0.75,
                        child: CupertinoSwitch(
                          value: availabilityDay.nightShiftEnabled,
                          activeColor: Colors.red,
                          onChanged: (newValue) {
                            UiMethods().showLoadingDialog(context: context);
                            if (!employeesProvider.isUpdating) {
                              onChange(newValue, 2);
                            }
                            employeesProvider.showEmployeeDetails(
                                employee: employeesProvider.selectedEmployee!);
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Jornada de\nnoche",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
