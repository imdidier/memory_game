import 'package:huts_web/features/statistics/domain/entities/year_stats.dart';

class YearStatsModel extends YearStats {
  YearStatsModel({
    required super.yearExpenses,
    required super.yearJobs,
    required super.favoriteEmployees,
    required super.yearEvents,
    required super.yearRequests,
    required super.topEmployeesByHour,
    required super.yearHours,
    required super.totalRequests,
    required super.totalEvents,
    required super.totalExpenses,
    required super.totalIncome,
    required super.totalRevenues,
    required super.companyId,
    required super.totalHours,
    required super.yearIncome,
    required super.yearRevenues,
    required super.cutOfWeekTotals,
  });
}
