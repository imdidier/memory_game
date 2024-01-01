import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/statistics/display/widgets/list_indicator_pie_graph.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../providers/dashboard_provider.dart';

class PieGraphJobs extends StatelessWidget {
  const PieGraphJobs({
    Key? key,
    required this.uiVariables,
    required this.screenSize,
    required this.dashboardProvider,
  }) : super(key: key);

  final UiVariables uiVariables;
  final ScreenSize screenSize;
  final DashboardProvider dashboardProvider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: UiVariables.boxDecoration,
          height: screenSize.height * 0.44,
          child: (dashboardProvider.yearStats == null ||
                  dashboardProvider.jobSections.isEmpty)
              ? Center(
                  child: Column(
                    children: [
                      Container(
                        child: Lottie.asset(
                          'gifs/no_data.json',
                          height: screenSize.absoluteHeight * 0.35,
                        ),
                      ),
                      const Text(
                        'No existen datos',
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    OverflowBar(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: EdgeInsets.only(
                                left: screenSize.width * 0.02,
                                top: screenSize.height * 0.02),
                            child: const Text(
                              'Top cargos solicitados',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: EdgeInsets.only(
                                top: screenSize.height * 0.02,
                                right: screenSize.width * 0.02),
                            child: Text(
                              'Total: ${dashboardProvider.yearStats!.totalRequests}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: SizedBox(
                            height: screenSize.height * 0.3,
                            width: screenSize.width * 0.21,
                            child: PieChart(
                              PieChartData(
                                borderData: FlBorderData(
                                  show: false,
                                ),
                                sectionsSpace: 0,
                                centerSpaceRadius: 60,
                                sections: dashboardProvider.jobSections,
                              ),
                            ),
                          ),
                        ),
                        ListIndicatorsPieGraph(
                          dashboardProvider: dashboardProvider,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
