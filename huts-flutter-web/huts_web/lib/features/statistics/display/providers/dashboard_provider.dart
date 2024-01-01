import 'dart:developer';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/use_cases_params/year_stats_params.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/statistics/data/repositories/get_year_stats_repository_impl.dart';
import 'package:huts_web/features/statistics/domain/entities/cut_of_week_totals.dart';
import 'package:huts_web/features/statistics/domain/entities/year_stats.dart';
import 'package:huts_web/features/statistics/domain/use_cases/get_year_stats.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/code/code_utils.dart';
import '../../data/datasources/get_year_stats_remote_datasource.dart';
import '../../domain/entities/employee_fav.dart';
import '../../domain/entities/pie_indicator.dart';
import 'package:intl/src/intl/date_format.dart';

class DashboardProvider with ChangeNotifier {
  YearStats? yearStats;

  List<String> monthsNames = [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC'
  ];
  List<String> daysNames = [
    'LUNES',
    'MARTES',
    'MIÉRCOLES',
    'JUEVES',
    'VIERNES',
    'SÁBADO',
    'DOMINGO',
  ];
  List<String> weeksNames = [
    'SEM 1: 1-7',
    'SEM 2: 8-14',
    'SEM 3: 15-21',
    'SEM 4: 22-28',
    'SEM 5: 29-31',
  ];

  DateTime? startDate;
  DateTime? endDate;
  bool isFirsTime = true;
  int daysDifference = 0;
  List<String> dates = [];

  DateTime? startDateForDayName;
  DateTime? endDateForDayName;

  String? yearPicked;
  List<String> yearsToPick = [];
  List<PieChartSectionData> jobSections = [];
  List<Color> colorsPieGraph = [
    const Color(0xFFCC8B86),
    const Color(0xFFFFBF69),
    const Color(0xFF88AB75),
    const Color(0xFFF48498),
    const Color(0xFF2EC4B6),
    const Color(0xFF967AA1),
    const Color(0xFFFF6542),
    const Color(0xFF7DD181),
    const Color(0xFFF28123),
    const Color(0xFFC6D4FF),
    const Color(0xFFE1CE7A)
  ];

  List<Color> colorsLineChart = [
    const Color(0xFFBCB6FF),
    const Color(0xFFD7263D),
    const Color(0xffCAFF8A)
  ];
  List<PieIndicator> pieIndicators = [];
  List<LineChartBarData> lineChartBars = [];
  List<BarChartGroupData> barChartGroup = [];

  List<ClientEmployee> filteredEmployees = [];

  CutOfWeekTotals? cutOfWeekTotals;

  String adminDashboardType = "general";
  // String byClient = 'by-client';

  String companyId = '';

  Future<void> eitherFailOrGetYearStats(
      AuthProvider authProvider, GeneralInfoProvider generalInfoProvider,
      {bool isFirstTime = false, adminDasboardType = 'general'}) async {
    try {
      jobSections.clear();
      GetYearStatsRepositoryImpl repository =
          GetYearStatsRepositoryImpl(GetYearStatsRemoteDataSourceImpl());
      YearStatsParams yearStatsParams = YearStatsParams(
        startDate: !isFirstTime ? startDate : null,
        endDate: !isFirstTime ? endDate : null,
        year: int.parse(yearPicked!),
        authProvider: authProvider,
        generalInfoProvider: generalInfoProvider,
        isFirstTime: isFirstTime,
        companyId: companyId,
        adminDashboardType: adminDashboardType,
      );

      if (startDate != null && endDate != null) {
        await getNameDaysWeek(startDate!, endDate!);
      }

      if (adminDashboardType == "general") {
        final result = await GetYearStats(repository).getYearStats(
          yearStatsParams,
        );
        result.fold((Failure failure) => log(failure.errorMessage ?? ""),
            (YearStats? resultYearStats) async {
          if (resultYearStats == null) return;
          yearStats = resultYearStats;

          if (isFirstTime) {
            cutOfWeekTotals = yearStats!.cutOfWeekTotals;
          }
          filteredEmployees.clear();
          filteredEmployees = [...resultYearStats.topEmployeesByHour];

          getJobSections();
          getBarChartBars(authProvider, daysDifference);
          notifyListeners();
        });
      } else {
        final result = await GetYearStats(repository)
            .getYearStats(yearStatsParams, adminDashboardType);
        result.fold((Failure failure) => log(failure.errorMessage ?? ""),
            (YearStats? resultYearStats) async {
          if (resultYearStats == null) return;
          yearStats!.companyId = companyId;

          yearStats = resultYearStats;
          filteredEmployees.clear();
          filteredEmployees = [
            ...yearStats!.topEmployeesByHour
                .where((element) => element.fullname != 'null null')
          ];
          if (isFirstTime) {
            cutOfWeekTotals = yearStats!.cutOfWeekTotals;
          }

          getJobSections();
          getBarChartBars(authProvider, daysDifference);
          notifyListeners();
        });
      }
    } catch (e) {
      log('Error DashboardProvider, eitherFailOrGetYearStats $e');
    }
  }

  Future<void> getNameDaysWeek(DateTime startDate, DateTime endDate) async {
    startDateForDayName = startDate;
    endDateForDayName = endDate;
    DateFormat formatDate = DateFormat.EEEE('es');
    List<int> listInt = List.generate(daysDifference, (index) => index);
    dates = List.generate(7, (index) => ' -- / -- / ---- ');
    await Future.forEach(listInt, (element) {
      String nameDayOfWeek = formatDate.format(startDateForDayName!);

      switch (nameDayOfWeek) {
        case 'lunes':
          dates[0] = CodeUtils.formatDateWithoutHour(startDateForDayName!);
          break;
        case 'martes':
          dates[1] = CodeUtils.formatDateWithoutHour(startDateForDayName!);

          break;
        case 'miércoles':
          dates[2] = CodeUtils.formatDateWithoutHour(startDateForDayName!);

          break;
        case 'jueves':
          dates[3] = CodeUtils.formatDateWithoutHour(startDateForDayName!);

          break;
        case 'viernes':
          dates[4] = CodeUtils.formatDateWithoutHour(startDateForDayName!);

          break;
        case 'sábado':
          dates[5] = CodeUtils.formatDateWithoutHour(startDateForDayName!);

          break;
        case 'domingo':
          dates[6] = CodeUtils.formatDateWithoutHour(startDateForDayName!);

          break;

        default:
      }

      startDateForDayName = DateTime(
        startDateForDayName!.year,
        startDateForDayName!.month,
        startDateForDayName!.day + 1,
      );
    });
  }

  getJobSections() {
    try {
      pieIndicators.clear();
      int indexColor = 0;
      jobSections.clear();
      for (var jobPercentage in yearStats!.yearJobs) {
        jobSections.add(
          PieChartSectionData(
            value: (jobPercentage.count * 100) / yearStats!.totalRequests,
            showTitle: false,
            badgePositionPercentageOffset: 1.6,
            badgeWidget: Container(
              padding: const EdgeInsets.only(right: 5),
              width: 45,
              height: 60,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.transparent),
              child: Center(
                child: CustomTooltip(
                  message:
                      '${((jobPercentage.count * 100) / yearStats!.totalRequests).toStringAsFixed(1)}% - ${(((yearStats!.totalRequests * ((jobPercentage.count * 100) / yearStats!.totalRequests))) / 100).toStringAsFixed(1)}',
                  child: Text(
                    '${((jobPercentage.count * 100) / yearStats!.totalRequests).toStringAsFixed(1)}% - ${(((yearStats!.totalRequests * ((jobPercentage.count * 100) / yearStats!.totalRequests))) / 100).toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            color: colorsPieGraph[indexColor],
          ),
        );
        pieIndicators.add(PieIndicator(
            color: colorsPieGraph[indexColor], jobName: jobPercentage.jobName));
        indexColor++;
      }
    } catch (e) {
      log('Error DashboardProvider, getJobSections $e');
    }
  }

  BarChartGroupData makeGroupData(
      {required int x,
      required double yearIncome,
      double yearExpenses = 0,
      double yearRevenues = 0,
      AuthProvider? authProvider}) {
    return BarChartGroupData(
      barsSpace: 5,
      x: x,
      barRods: [
        BarChartRodData(
          toY: yearIncome,
          color: colorsLineChart[0],
          width: 10,
        ),
        if (authProvider!.webUser.accountInfo.type != 'client')
          BarChartRodData(
            toY: yearExpenses,
            color: colorsLineChart[1],
            width: 10,
          ),
        if (authProvider.webUser.accountInfo.type != 'client')
          BarChartRodData(
            toY: yearRevenues,
            color: colorsLineChart[2],
            width: 10,
          ),
      ],
    );
  }

  getBarChartBars(AuthProvider authProvider, int daysDifference) {
    try {
      List totalBars = [
        yearStats!.yearIncome,
        yearStats!.yearExpenses,
        yearStats!.yearRevenues
      ];
      // lineChartBars.clear();
      barChartGroup.clear();

      if (authProvider.webUser.accountInfo.type == 'client') {
        totalBars = [yearStats!.yearExpenses];
      }
      int numbersIteration = daysDifference >= 30
          ? 12
          : daysDifference < 30 && daysDifference >= 8
              ? 5
              : 7;
      for (var i = 0; i < numbersIteration; i++) {
        if (authProvider.webUser.accountInfo.type != 'client') {
          barChartGroup.add(
            makeGroupData(
              x: i + 1,
              yearIncome: totalBars[0][i].y,
              yearExpenses: totalBars[1][i].y,
              yearRevenues: totalBars[2][i].y,
              authProvider: authProvider,
            ),
          );
        } else {
          barChartGroup.add(
            makeGroupData(
              x: i + 1,
              yearIncome: totalBars[0][i].y,
              authProvider: authProvider,
            ),
          );
        }
      }
      // for (var i = 0; i < totalBars.length; i++) {
      // lineChartBars.add(LineChartBarData(
      //   spots: totalBars[i],
      //   isCurved: false,
      //   gradient: (authProvider.webUser.accountInfo.type == 'client')
      //       ? LinearGradient(
      //           colors: colorsLineChart,
      //           begin: Alignment.centerLeft,
      //           end: Alignment.centerRight,
      //         )
      //       : null,
      //   color: (authProvider.webUser.accountInfo.type == 'client')
      //       ? null
      //       : colorsLineChart[i],
      //   barWidth: 3,
      //   isStrokeCapRound: true,
      //   dotData: FlDotData(
      //     show: true,
      //   ),
      //   belowBarData: (authProvider.webUser.accountInfo.type == 'client')
      //       ? BarAreaData(
      //           show: true,
      //           gradient: LinearGradient(
      //             colors: colorsLineChart
      //                 .map((color) => color.withOpacity(0.3))
      //                 .toList(),
      //             begin: Alignment.centerLeft,
      //             end: Alignment.centerRight,
      //           ),
      //         )
      //       : null,
      // ));
      //}
    } catch (e) {
      log('Error DashboardProvider, getBarChartBars $e');
    }
  }

  getYearsToPick() {
    try {
      yearsToPick.clear();
      for (var i = 2020; i <= DateTime.now().year; i++) {
        yearsToPick.add('$i');
      }
    } catch (e) {
      log('Error dashboardProvider, getYearsToPick $e');
    }
  }

  void updateYearPicked(String newYear, AuthProvider authProvider,
      GeneralInfoProvider generalInfoProvider) async {
    yearPicked = newYear;
    await eitherFailOrGetYearStats(authProvider, generalInfoProvider);
  }
}
