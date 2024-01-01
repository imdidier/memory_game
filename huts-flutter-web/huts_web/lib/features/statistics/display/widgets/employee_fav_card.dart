import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';

import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../domain/entities/employee_fav.dart';

class EmployeeFavCard extends StatelessWidget {
  const EmployeeFavCard({
    Key? key,
    required this.screenSize,
    required this.uiVariables,
    required this.index,
    required this.employeesToShow,
    required this.showHoursWorked,
  }) : super(key: key);

  final ScreenSize screenSize;
  final UiVariables uiVariables;
  final int index;
  final List<ClientEmployee> employeesToShow;
  final bool showHoursWorked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: screenSize.height * 0.02, horizontal: 10),
      decoration: UiVariables.boxDecoration,
      child: Row(
        children: [
          Flexible(
            flex: 6,
            child: Row(
              children: [
                Flexible(
                  flex: 1,
                  child: employeesToShow[index].photo.isNotEmpty &&
                          employeesToShow[index].photo != 'null'
                      ? CircleAvatar(
                          radius: screenSize.width * 0.02,
                          backgroundImage: NetworkImage(
                            employeesToShow[index].photo,
                          ),
                        )
                      : CircleAvatar(
                          radius: screenSize.width * 0.02,
                          child: const Icon(
                            Icons.hide_image_outlined,
                            size: 28,
                          ),
                        ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Flexible(
                  flex: 2,
                  child: SizedBox(
                    height: screenSize.height * 0.05,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 1,
                          child: CustomTooltip(
                            message: employeesToShow[index].fullname,
                            child: Text(
                              employeesToShow[index].fullname,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Flexible(
                          flex: 1,
                          child: Text(
                            employeesToShow[index].phone,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
              flex: 1,
              child: (showHoursWorked)
                  ? Text('${employeesToShow[index].hoursWorked} h')
                  : Icon(
                      Icons.star_rate_rounded,
                      color: Colors.amber[700],
                    ))
        ],
      ),
    );
  }
}
