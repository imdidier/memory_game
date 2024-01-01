import 'package:fl_chart/fl_chart.dart';
import 'package:huts_web/features/statistics/domain/entities/job_percentage.dart';

import 'cut_of_week_totals.dart';
import 'employee_fav.dart';

class YearStats {
  final List<FlSpot> yearExpenses;
  final List<FlSpot> yearIncome;
  final List<FlSpot> yearRevenues;
  final List<ClientEmployee> favoriteEmployees;
  final List<JobPercentage> yearJobs;
  final List<BarChartGroupData> yearRequests;
  final List<BarChartGroupData> yearEvents;
  final List<BarChartGroupData> yearHours;
  final List<ClientEmployee> topEmployeesByHour;
  String companyId;
  int totalRequests;
  int totalEvents;
  double totalHours;
  double totalExpenses;
  double totalIncome;
  double totalRevenues;

  CutOfWeekTotals? cutOfWeekTotals;

  YearStats({
    required this.companyId,
    required this.yearExpenses,
    required this.favoriteEmployees,
    required this.yearJobs,
    required this.yearEvents,
    required this.yearRequests,
    required this.yearHours,
    required this.topEmployeesByHour,
    required this.totalRequests,
    required this.totalEvents,
    required this.totalExpenses,
    required this.totalIncome,
    required this.totalRevenues,
    required this.totalHours,
    required this.yearIncome,
    required this.yearRevenues,
    required this.cutOfWeekTotals,
  });
}
