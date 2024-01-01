import 'package:flutter/material.dart';
import 'package:huts_web/features/statistics/display/providers/dashboard_provider.dart';

import 'graph_indicator.dart';

class ListIndicatorsPieGraph extends StatelessWidget {
  const ListIndicatorsPieGraph({Key? key, required this.dashboardProvider})
      : super(key: key);

  final DashboardProvider dashboardProvider;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: dashboardProvider.pieIndicators.length,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: GraphIndicator(
            color: dashboardProvider.pieIndicators[index].color,
            title: dashboardProvider.pieIndicators[index].jobName,
          ),
        ),
      ),
    );
  }
}
