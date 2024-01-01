import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../auth/domain/entities/screen_size_entity.dart';
import '../providers/dashboard_provider.dart';
import 'bottom_titles_months.dart';

class BarGraphCard extends StatelessWidget {
  const BarGraphCard({
    Key? key,
    required this.screenSize,
    required this.dashboardProvider,
    required this.barGroups,
    required this.barTitle,
    required this.totalToShow,
    required this.daysDifference,
  }) : super(key: key);

  final ScreenSize screenSize;
  final DashboardProvider dashboardProvider;
  final List<BarChartGroupData>? barGroups;
  final String barTitle;
  final String totalToShow;
  final int daysDifference;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, left: 20),
                  child: Text(
                    barTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )),
            Container(
              margin: const EdgeInsets.only(right: 20, top: 15),
              child: Column(
                children: [
                  Text(
                    totalToShow,
                    style: const TextStyle(fontSize: 17),
                  ),
                  Text(
                    '${barTitle.split(' ')[0]} totales',
                    style: const TextStyle(fontSize: 11),
                  )
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: screenSize.height * 0.03,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.01),
          height: screenSize.height * 0.3,
          child: BarChart(
            BarChartData(
              // baselineY: daysDifference >= 30
              //     ? 400
              //     : daysDifference < 30 && daysDifference >= 8
              //         ? 100
              //         : 100,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => BottomTitlesMonths(
                      dashboardProvider: dashboardProvider,
                      value: value,
                      meta: meta,
                      totalDays: daysDifference,
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    interval:
                        daysDifference >= 30 && barTitle != 'Horas solicitadas'
                            ? 300
                            : daysDifference >= 30 &&
                                    barTitle == 'Horas solicitadas'
                                ? 1000
                                : daysDifference < 30 &&
                                        daysDifference >= 8 &&
                                        barTitle != 'Horas solicitadas'
                                    ? 100
                                    : daysDifference < 30 &&
                                            daysDifference >= 8 &&
                                            barTitle == 'Horas solicitadas'
                                        ? 500
                                        : daysDifference < 8 &&
                                                barTitle != 'Horas solicitadas'
                                            ? 50
                                            : 250,
                    reservedSize: 35,
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        topTitleWidgets(value, meta),
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              gridData: FlGridData(show: false),
              alignment: BarChartAlignment.spaceAround,
            ),
          ),
        ),
      ],
    );
  }

  Widget topTitleWidgets(double value, TitleMeta meta) {
    const TextStyle style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.bold,
      fontSize: 11,
    );

    Text text = Text(
      (value < 1 && value != 0) ? '' : value.toStringAsFixed(0),
      style: style,
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 1.0,
      child: text,
    );
  }
}
