import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../providers/dashboard_provider.dart';

class BottomTitlesMonths extends StatelessWidget {
  const BottomTitlesMonths({
    Key? key,
    required this.dashboardProvider,
    required this.value,
    required this.meta,
    required this.totalDays,
  }) : super(key: key);

  final DashboardProvider dashboardProvider;
  final double value;
  final TitleMeta meta;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    Text text = Text(
      _getTitle(
        totalDays,
        value,
      ),
      style: style,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8.0,
      child: text,
    );
  }

  String _getTitle(
    int totalDays,
    double value,
  ) {
    String title = "";

    int index = value.toInt() - 1;

    if (totalDays >= 30) {
      if (index < dashboardProvider.monthsNames.length) {
        title = dashboardProvider.monthsNames[index];
      }
    } else if (totalDays >= 8 && totalDays < 30) {
      if (index < dashboardProvider.weeksNames.length) {
        title = dashboardProvider.weeksNames[index];
      }
    } else {
      if (index < dashboardProvider.daysNames.length) {
        title =
            '${dashboardProvider.daysNames[index]}\n${dashboardProvider.dates[index]}';
      }
    }

    return title;
  }
}
