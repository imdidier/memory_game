import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/statistics/display/widgets/bottom_titles_months.dart';
import 'package:huts_web/features/statistics/display/widgets/graph_indicator.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../providers/dashboard_provider.dart';

class GraphExpensesCard extends StatelessWidget {
  const GraphExpensesCard({
    Key? key,
    required this.uiVariables,
    required this.screenSize,
    required this.dashboardProvider,
    required this.tapSelected,
    required this.daysDifference,
  }) : super(key: key);

  final UiVariables uiVariables;
  final ScreenSize screenSize;
  final DashboardProvider dashboardProvider;
  final String tapSelected;
  final int daysDifference;
  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);

    return Column(
      children: [
        Container(
          decoration: UiVariables.boxDecoration,
          width: screenSize.width,
          height: screenSize.height * 0.44,
          child: (dashboardProvider.yearStats == null)
              ? const Center(
                  child: Text('Sin estadísticas'),
                )
              : Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: OverflowBar(
                        alignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: screenSize.width * 0.2,
                              margin: EdgeInsets.symmetric(
                                  vertical: screenSize.height * 0.025,
                                  horizontal: screenSize.width * 0.01),
                              child: Text(
                                (authProvider.webUser.accountInfo.type ==
                                        'client')
                                    ? 'Gastos realizados'
                                    : daysDifference >= 30
                                        ? 'Balance del año'
                                        : 'Balance del rango seleccionado',
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold),
                              )),
                          (authProvider.webUser.accountInfo.type != 'client')
                              ? Container(
                                  width: screenSize.width * 0.18,
                                  padding: const EdgeInsets.only(
                                    right: 15,
                                    top: 10,
                                  ),
                                  child: tapSelected == 'general'
                                      ? OverflowBar(
                                          spacing: 8,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                GraphIndicator(
                                                    color: dashboardProvider
                                                        .colorsLineChart[0],
                                                    title: 'Ingresos'),
                                                Text(
                                                  CodeUtils.formatMoney(
                                                      dashboardProvider
                                                          .yearStats!
                                                          .totalIncome),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                // Text(data)
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                GraphIndicator(
                                                    color: dashboardProvider
                                                        .colorsLineChart[1],
                                                    title: 'Gastos'),
                                                Text(
                                                  CodeUtils.formatMoney(
                                                      dashboardProvider
                                                          .yearStats!
                                                          .totalExpenses),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                GraphIndicator(
                                                    color: dashboardProvider
                                                        .colorsLineChart[2],
                                                    title: 'Ganancias'),
                                                Text(
                                                  CodeUtils.formatMoney(
                                                    dashboardProvider.yearStats!
                                                        .totalRevenues,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      : OverflowBar(
                                          spacing: 8,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                GraphIndicator(
                                                    color: dashboardProvider
                                                        .colorsLineChart[0],
                                                    title: 'Ingresos'),
                                                Text(
                                                  CodeUtils.formatMoney(
                                                      dashboardProvider
                                                          .yearStats!
                                                          .totalIncome),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                // Text(data)
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                GraphIndicator(
                                                    color: dashboardProvider
                                                        .colorsLineChart[1],
                                                    title: 'Gastos'),
                                                Text(
                                                  CodeUtils.formatMoney(
                                                      dashboardProvider
                                                          .yearStats!
                                                          .totalExpenses),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                GraphIndicator(
                                                    color: dashboardProvider
                                                        .colorsLineChart[2],
                                                    title: 'Ganancias'),
                                                Text(
                                                  CodeUtils.formatMoney(
                                                    dashboardProvider.yearStats!
                                                        .totalRevenues,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Column(
                                    children: [
                                      Text(
                                        CodeUtils.formatMoney((dashboardProvider
                                            .yearStats!.totalIncome)),
                                        style: const TextStyle(fontSize: 17),
                                      ),
                                      const Text(
                                        'Gastos totales',
                                        style: TextStyle(fontSize: 11),
                                      )
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: screenSize.width,
                      height: screenSize.height * 0.33,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 15, right: 40, top: 6, bottom: 6),
                        child: BarChart(
                          mainData(),
                        ),
                      ),
                    ),
                  ],
                ),
        )
      ],
    );
  }

  BarChartData mainData() {
    tapSelected == 'by_client'
        ? dashboardProvider.barChartGroup.length
        : dashboardProvider.barChartGroup;
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          maxContentWidth: 100,
          tooltipBgColor: Colors.black54,
          getTooltipItem: (
            BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,
          ) {
            return BarTooltipItem(
              CodeUtils.formatMoney(rod.toY),
              TextStyle(
                fontWeight: FontWeight.bold,
                color: rod.color,
                fontSize: 14,
              ),
            );
          },

          //  (touchedSpots) {
          //   return touchedSpots.map((LineBarSpot touchedSpot) {
          //     final textStyle = TextStyle(
          //       color: touchedSpot.bar.gradient?.colors[0] ??
          //           touchedSpot.bar.color,
          //       fontWeight: FontWeight.bold,
          //       fontSize: 14,
          //     );
          //     return LineTooltipItem(
          //       CodeUtils.formatMoney(touchedSpot.y),
          //       textStyle,
          //     );
          //   }).toList();
          // },
        ),
        handleBuiltInTouches: true,
        //  getTouchLineStart: (data, index) => 0,
      ),
      // baselineY: 15,

      gridData: FlGridData(
        show: false,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 1,
            getTitlesWidget: ((value, meta) => BottomTitlesMonths(
                  dashboardProvider: dashboardProvider,
                  meta: meta,
                  value: value,
                  totalDays: daysDifference,
                )),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 90,
            interval: daysDifference >= 30
                ? 6000000
                : daysDifference < 30 && daysDifference >= 8
                    ? 2000000
                    : 500000,
            getTitlesWidget: (value, meta) {
              return Text(
                CodeUtils.formatMoney(value),
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),

      borderData: FlBorderData(
        show: false,
      ),
      barGroups: dashboardProvider.barChartGroup,
      alignment: BarChartAlignment.spaceAround,
      // minX: 1,
      // maxX: 12,
      minY: 0,
      // lineBarsData: dashboardProvider.lineChartBars,
    );
  }
}
