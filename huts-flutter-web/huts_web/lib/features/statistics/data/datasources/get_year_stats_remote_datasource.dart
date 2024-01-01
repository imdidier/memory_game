import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/use_cases_params/year_stats_params.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/statistics/data/models/employee_fav_model.dart';
import 'package:huts_web/features/statistics/data/models/job_percentage_model.dart';
import 'package:huts_web/features/statistics/data/models/year_stats_model.dart';
import 'package:huts_web/features/statistics/domain/entities/cut_of_week_totals.dart';
import 'package:huts_web/features/statistics/domain/entities/job_percentage.dart';
import 'package:huts_web/features/statistics/domain/entities/year_stats.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/firebase_config/firebase_services.dart';
import '../../../../core/services/navigation_service.dart';
import '../../domain/entities/employee_fav.dart';

abstract class GetYearStatsRemoteDataSource {
  Future<YearStats?> getYearStats(YearStatsParams yearStatsParams,
      [String? byClient]);
}

class GetYearStatsRemoteDataSourceImpl implements GetYearStatsRemoteDataSource {
  @override
  Future<YearStats?> getYearStats(YearStatsParams yearStatsParams,
      [String? byClient = '']) async {
    try {
      Map<String, dynamic>? cutOfWeekInfo;
      CutOfWeekTotals? cutOfWeekTotals;

      BuildContext? context = NavigationService.getGlobalContext();

      List<ClientEntity> allClients =
          context!.read<ClientsProvider>().allClients;
      if (yearStatsParams.isFirstTime) {
        cutOfWeekInfo = getCutOfWeekInfo(
            DateTime.now(), yearStatsParams.generalInfoProvider);
        cutOfWeekTotals = CutOfWeekTotals(
            totalClientsPay: 0,
            totalToPayEmployees: 0,
            totalRevenue: 0,
            cutOfWeekText: cutOfWeekInfo['datesString']);
      }

      YearStatsModel finalYearStatsModel = YearStatsModel(
          yearExpenses: [],
          yearJobs: [],
          favoriteEmployees: [],
          yearEvents: [],
          yearRequests: [],
          topEmployeesByHour: [],
          yearHours: [],
          companyId: '',
          totalRequests: 0,
          totalEvents: 0,
          totalExpenses: 0,
          totalIncome: 0,
          totalRevenues: 0,
          totalHours: 0,
          yearIncome: [],
          yearRevenues: [],
          cutOfWeekTotals: cutOfWeekTotals);

      List<JobPercentage> percentagesJobs = [];
      Map<String, dynamic> expensesCoords = {};
      Map<String, dynamic> expensesCoordsWeek = {};
      Map<String, dynamic> expensesCoordsDay = {};

      Map<String, dynamic> incomeCoords = {};
      Map<String, dynamic> incomeCoordsWeek = {};
      Map<String, dynamic> incomeCoordsDay = {};

      Map<String, dynamic> requestsCoords = {};
      Map<String, dynamic> requestsCoordsWeek = {};
      Map<String, dynamic> requestsCoordsDay = {};

      Map<String, dynamic> eventsMonthIds = {};
      Map<String, dynamic> eventsDayIds = {};
      Map<String, dynamic> eventsWeekIds = {};

      Map<String, dynamic> hoursMonth = {};
      Map<String, dynamic> hoursWeek = {};
      Map<String, dynamic> hoursDay = {};
      List<dynamic> listFavorites = [];

      int daysDifference = 0;
      if (yearStatsParams.endDate != null && yearStatsParams.endDate != null) {
        daysDifference = yearStatsParams.endDate!
            .difference(yearStatsParams.startDate!)
            .inDays;
      } else {
        daysDifference = 31;
      }

      String userType = yearStatsParams.authProvider.webUser.accountInfo.type;
      finalYearStatsModel.companyId = yearStatsParams.companyId;
      Query<Map<String, dynamic>> myQuery;
      if (yearStatsParams.isFirstTime) {
        myQuery = FirebaseServices.db
            .collection('requests')
            .where('year', isEqualTo: yearStatsParams.year);
      } else {
        myQuery = FirebaseServices.db
            .collection('requests')
            .where("details.start_date",
                isGreaterThanOrEqualTo: yearStatsParams.startDate)
            .where("details.start_date",
                isLessThanOrEqualTo: yearStatsParams.endDate);
      }
      if (userType == 'client') {
        myQuery = myQuery.where('client_info.id',
            isEqualTo: yearStatsParams.authProvider.webUser.company.id);
      }
      if (userType != 'client' &&
          yearStatsParams.adminDashboardType != 'general') {
        myQuery = myQuery.where('client_info.id',
            isEqualTo: yearStatsParams.companyId);
      }

      await myQuery.get().then((myQuery) {
        // finalYearStatsModel.totalRequests = myQuery.docs.length;
        if (byClient == 'by-client') {
          myQuery.docs.where((element) =>
              element.data()['client_info']['id'] == yearStatsParams.companyId);
        }
        for (var myDoc in myQuery.docs) {
          Map<String, dynamic> myData = myDoc.data();
          DateTime startDate = myData['details']['start_date'].toDate();

          DateFormat formatDate = DateFormat.EEEE('es');
          String nameDayOfWeek = formatDate.format(startDate);

          if (yearStatsParams.isFirstTime) {
            checkIfAppliesCutOfWeek(cutOfWeekInfo!['cutSearch'],
                finalYearStatsModel.cutOfWeekTotals!, myData);
          }
          if (myData['details']['status'] <= 4) {
            finalYearStatsModel.totalRequests++;

            //Requests - graph
            if (daysDifference >= 30) {
              validateIfCanBeAdded('${myData['month']}', requestsCoords, 1);
            }
            if (daysDifference < 30 && daysDifference >= 8) {
              if (startDate.day >= 1 && startDate.day < 8) {
                validateIfCanBeAdded('1', requestsCoordsWeek, 1);
              }
              if (startDate.day >= 8 && startDate.day < 15) {
                validateIfCanBeAdded('2', requestsCoordsWeek, 1);
              }
              if (startDate.day >= 15 && startDate.day < 22) {
                validateIfCanBeAdded('3', requestsCoordsWeek, 1);
              }
              if (startDate.day >= 22 && startDate.day < 29) {
                validateIfCanBeAdded('4', requestsCoordsWeek, 1);
              }
              if (startDate.day >= 29 && startDate.day <= 31) {
                validateIfCanBeAdded('5', requestsCoordsWeek, 1);
              }
            }

            if (daysDifference < 8) {
              switch (nameDayOfWeek) {
                case 'lunes':
                  validateIfCanBeAdded('1', requestsCoordsDay, 1);

                  break;
                case 'martes':
                  validateIfCanBeAdded('2', requestsCoordsDay, 1);

                  break;
                case 'miércoles':
                  validateIfCanBeAdded('3', requestsCoordsDay, 1);

                  break;
                case 'jueves':
                  validateIfCanBeAdded('4', requestsCoordsDay, 1);

                  break;
                case 'viernes':
                  validateIfCanBeAdded('5', requestsCoordsDay, 1);

                  break;
                case 'sábado':
                  validateIfCanBeAdded('6', requestsCoordsDay, 1);

                  break;
                case 'domingo':
                  validateIfCanBeAdded('7', requestsCoordsDay, 1);

                  break;
                default:
              }
            }

            //Hours - graph
            if (daysDifference >= 30) {
              validateIfCanBeAdded('${myData['month']}', hoursMonth,
                  myData['details']['total_hours']);
            }

            if (daysDifference < 30 && daysDifference >= 8) {
              if (startDate.day >= 1 && startDate.day < 8) {
                validateIfCanBeAdded(
                    '1', hoursWeek, myData['details']['total_hours']);
              }
              if (startDate.day >= 8 && startDate.day < 15) {
                validateIfCanBeAdded(
                    '2', hoursWeek, myData['details']['total_hours']);
              }
              if (startDate.day >= 15 && startDate.day < 22) {
                validateIfCanBeAdded(
                    '3', hoursWeek, myData['details']['total_hours']);
              }
              if (startDate.day >= 22 && startDate.day < 29) {
                validateIfCanBeAdded(
                    '4', hoursWeek, myData['details']['total_hours']);
              }
              if (startDate.day >= 29 && startDate.day <= 31) {
                validateIfCanBeAdded(
                    '5', hoursWeek, myData['details']['total_hours']);
              }
            }

            if (daysDifference < 8) {
              switch (nameDayOfWeek) {
                case 'lunes':
                  validateIfCanBeAdded(
                      '1', hoursDay, myData['details']['total_hours']);

                  break;
                case 'martes':
                  validateIfCanBeAdded(
                      '2', hoursDay, myData['details']['total_hours']);

                  break;
                case 'miércoles':
                  validateIfCanBeAdded(
                      '3', hoursDay, myData['details']['total_hours']);

                  break;
                case 'jueves':
                  validateIfCanBeAdded(
                      '4', hoursDay, myData['details']['total_hours']);

                  break;
                case 'viernes':
                  validateIfCanBeAdded(
                      '5', hoursDay, myData['details']['total_hours']);

                  break;
                case 'sábado':
                  validateIfCanBeAdded(
                      '6', hoursDay, myData['details']['total_hours']);

                  break;
                case 'domingo':
                  validateIfCanBeAdded(
                      '7', hoursDay, myData['details']['total_hours']);

                  break;
                default:
              }
            }

            //Expenses - graph
            if (daysDifference >= 30) {
              validateIfCanBeAdded(
                '${myData['month']}',
                expensesCoords,
                (userType == 'client')
                    ? myData['details']['fare']['total_client_pays']
                    : myData['details']['fare']['total_to_pay_employee'],
              );
            }

            if (daysDifference < 30 && daysDifference >= 8) {
              if (startDate.day >= 1 && startDate.day < 8) {
                validateIfCanBeAdded(
                    '1',
                    expensesCoordsWeek,
                    (userType == 'client')
                        ? myData['details']['fare']['total_client_pays']
                        : myData['details']['fare']['total_to_pay_employee']);
              }
              if (startDate.day >= 8 && startDate.day < 15) {
                validateIfCanBeAdded(
                    '2',
                    expensesCoordsWeek,
                    (userType == 'client')
                        ? myData['details']['fare']['total_client_pays']
                        : myData['details']['fare']['total_to_pay_employee']);
              }
              if (startDate.day >= 15 && startDate.day < 22) {
                validateIfCanBeAdded(
                    '3',
                    expensesCoordsWeek,
                    (userType == 'client')
                        ? myData['details']['fare']['total_client_pays']
                        : myData['details']['fare']['total_to_pay_employee']);
              }
              if (startDate.day >= 22 && startDate.day < 29) {
                validateIfCanBeAdded(
                    '4',
                    expensesCoordsWeek,
                    (userType == 'client')
                        ? myData['details']['fare']['total_client_pays']
                        : myData['details']['fare']['total_to_pay_employee']);
              }
              if (startDate.day >= 29 && startDate.day <= 31) {
                validateIfCanBeAdded(
                    '5',
                    expensesCoordsWeek,
                    (userType == 'client')
                        ? myData['details']['fare']['total_client_pays']
                        : myData['details']['fare']['total_to_pay_employee']);
              }
            }

            if (daysDifference < 8) {
              switch (nameDayOfWeek) {
                case 'lunes':
                  validateIfCanBeAdded(
                      '1',
                      expensesCoordsDay,
                      (userType == 'client')
                          ? myData['details']['fare']['total_client_pays']
                          : myData['details']['fare']['total_to_pay_employee']);
                  break;
                case 'martes':
                  validateIfCanBeAdded(
                      '2',
                      expensesCoordsDay,
                      (userType == 'client')
                          ? myData['details']['fare']['total_client_pays']
                          : myData['details']['fare']['total_to_pay_employee']);
                  break;
                case 'miércoles':
                  validateIfCanBeAdded(
                      '3',
                      expensesCoordsDay,
                      (userType == 'client')
                          ? myData['details']['fare']['total_client_pays']
                          : myData['details']['fare']['total_to_pay_employee']);
                  break;
                case 'jueves':
                  validateIfCanBeAdded(
                      '4',
                      expensesCoordsDay,
                      (userType == 'client')
                          ? myData['details']['fare']['total_client_pays']
                          : myData['details']['fare']['total_to_pay_employee']);
                  break;
                case 'viernes':
                  validateIfCanBeAdded(
                      '5',
                      expensesCoordsDay,
                      (userType == 'client')
                          ? myData['details']['fare']['total_client_pays']
                          : myData['details']['fare']['total_to_pay_employee']);
                  break;
                case 'sábado':
                  validateIfCanBeAdded(
                      '6',
                      expensesCoordsDay,
                      (userType == 'client')
                          ? myData['details']['fare']['total_client_pays']
                          : myData['details']['fare']['total_to_pay_employee']);
                  break;
                case 'domingo':
                  validateIfCanBeAdded(
                      '7',
                      expensesCoordsDay,
                      (userType == 'client')
                          ? myData['details']['fare']['total_client_pays']
                          : myData['details']['fare']['total_to_pay_employee']);
                  break;
                default:
              }
            }

            finalYearStatsModel.totalExpenses += (userType == 'client')
                ? myData['details']['fare']['total_client_pays']
                : myData['details']['fare']['total_to_pay_employee'];
            finalYearStatsModel.totalIncome +=
                myData['details']['fare']['total_client_pays'];

            //Income = graph
            if (daysDifference >= 30) {
              validateIfCanBeAdded('${myData['month']}', incomeCoords,
                  myData['details']['fare']['total_client_pays']);
            }

            if (daysDifference < 30 && daysDifference >= 8) {
              if (startDate.day >= 1 && startDate.day < 8) {
                validateIfCanBeAdded('1', incomeCoordsWeek,
                    myData['details']['fare']['total_client_pays']);
              }
              if (startDate.day >= 8 && startDate.day < 15) {
                validateIfCanBeAdded('2', incomeCoordsWeek,
                    myData['details']['fare']['total_client_pays']);
              }
              if (startDate.day >= 15 && startDate.day < 22) {
                validateIfCanBeAdded('3', incomeCoordsWeek,
                    myData['details']['fare']['total_client_pays']);
              }
              if (startDate.day >= 22 && startDate.day < 29) {
                validateIfCanBeAdded('4', incomeCoordsWeek,
                    myData['details']['fare']['total_client_pays']);
              }
              if (startDate.day >= 29 && startDate.day <= 31) {
                validateIfCanBeAdded('5', incomeCoordsWeek,
                    myData['details']['fare']['total_client_pays']);
              }
            }

            if (daysDifference < 8) {
              switch (nameDayOfWeek) {
                case 'lunes':
                  validateIfCanBeAdded('1', incomeCoordsDay,
                      myData['details']['fare']['total_client_pays']);
                  break;
                case 'martes':
                  validateIfCanBeAdded('2', incomeCoordsDay,
                      myData['details']['fare']['total_client_pays']);
                  break;
                case 'miércoles':
                  validateIfCanBeAdded('3', incomeCoordsDay,
                      myData['details']['fare']['total_client_pays']);
                  break;
                case 'jueves':
                  validateIfCanBeAdded('4', incomeCoordsDay,
                      myData['details']['fare']['total_client_pays']);
                  break;
                case 'viernes':
                  validateIfCanBeAdded('5', incomeCoordsDay,
                      myData['details']['fare']['total_client_pays']);
                  break;
                case 'sábado':
                  validateIfCanBeAdded('6', incomeCoordsDay,
                      myData['details']['fare']['total_client_pays']);
                  break;
                case 'domingo':
                  validateIfCanBeAdded('7', incomeCoordsDay,
                      myData['details']['fare']['total_client_pays']);
                  break;
                default:
              }
            }

            //Hours - graph
            int indexEmployeeHours = finalYearStatsModel.topEmployeesByHour
                .indexWhere((employee) =>
                    employee.uid == myData['employee_info']['id'] &&
                    myData['details']['status'] == 4);

            String idEmployee = '';
            for (var element in finalYearStatsModel.topEmployeesByHour) {
              if (element.uid == myData['employee_info']['id']) {
                idEmployee = myData['employee_info']['id'];
              }
            }
            if (indexEmployeeHours == -1) {
              if (idEmployee != myData['employee_info']['id']) {
                if (myData['employee_info'].containsKey('id') &&
                    myData['details']['status'] == 4) {
                  finalYearStatsModel.topEmployeesByHour
                      .add(ClientEmployeeModel.fromMap(myData));
                }
              }
            } else {
              finalYearStatsModel.topEmployeesByHour[indexEmployeeHours]
                  .hoursWorked += myData['details']['total_hours'];

              //int.parse('${myData['details']['total_hours']}');
            }

            // finalYearStatsModel.totalHours +=
            //     int.parse('${myData['details']['total_hours']}');

            finalYearStatsModel.totalHours +=
                (myData['details']['total_hours']);

            //Events - graph
            if (daysDifference >= 30) {
              if (eventsMonthIds.containsKey('${myData['month']}')) {
                if (!(eventsMonthIds['${myData['month']}']
                    .contains(myData['event_id']))) {
                  finalYearStatsModel.totalEvents += 1;
                  eventsMonthIds['${myData['month']}'].add(myData['event_id']);
                }
              } else {
                finalYearStatsModel.totalEvents += 1;
                eventsMonthIds['${myData['month']}'] = [myData['event_id']];
              }
            }

            if (daysDifference < 30 && daysDifference >= 8) {
              if (startDate.day >= 1 && startDate.day < 8) {
                if (eventsWeekIds.containsKey('1')) {
                  if (!(eventsWeekIds['1'].contains(myData['event_id']))) {
                    finalYearStatsModel.totalEvents += 1;
                    eventsWeekIds['1'].add(myData['event_id']);
                  }
                } else {
                  finalYearStatsModel.totalEvents += 1;
                  eventsWeekIds['1'] = [myData['event_id']];
                }
              }
              if (startDate.day >= 8 && startDate.day < 15) {
                if (eventsWeekIds.containsKey('2')) {
                  if (!(eventsWeekIds['2'].contains(myData['event_id']))) {
                    finalYearStatsModel.totalEvents += 1;
                    eventsWeekIds['2'].add(myData['event_id']);
                  }
                } else {
                  finalYearStatsModel.totalEvents += 1;
                  eventsWeekIds['2'] = [myData['event_id']];
                }
              }
              if (startDate.day >= 15 && startDate.day < 22) {
                if (eventsWeekIds.containsKey('3')) {
                  if (!(eventsWeekIds['3'].contains(myData['event_id']))) {
                    finalYearStatsModel.totalEvents += 1;
                    eventsWeekIds['3'].add(myData['event_id']);
                  }
                } else {
                  finalYearStatsModel.totalEvents += 1;
                  eventsWeekIds['3'] = [myData['event_id']];
                }
              }
              if (startDate.day >= 22 && startDate.day < 29) {
                if (eventsWeekIds.containsKey('4')) {
                  if (!(eventsWeekIds['4'].contains(myData['event_id']))) {
                    finalYearStatsModel.totalEvents += 1;
                    eventsWeekIds['4'].add(myData['event_id']);
                  }
                } else {
                  finalYearStatsModel.totalEvents += 1;
                  eventsWeekIds['4'] = [myData['event_id']];
                }
              }
              if (startDate.day >= 29 && startDate.day <= 31) {
                if (eventsWeekIds.containsKey('5')) {
                  if (!(eventsWeekIds['5'].contains(myData['event_id']))) {
                    finalYearStatsModel.totalEvents += 1;
                    eventsWeekIds['5'].add(myData['event_id']);
                  }
                } else {
                  finalYearStatsModel.totalEvents += 1;
                  eventsWeekIds['5'] = [myData['event_id']];
                }
              }
            }

            if (daysDifference < 8) {
              switch (nameDayOfWeek) {
                case 'lunes':
                  if (eventsDayIds.containsKey('1')) {
                    if (!(eventsDayIds['1'].contains(myData['event_id']))) {
                      finalYearStatsModel.totalEvents += 1;
                      eventsDayIds['1'].add(myData['event_id']);
                    }
                  } else {
                    finalYearStatsModel.totalEvents += 1;
                    eventsDayIds['1'] = [myData['event_id']];
                  }
                  break;
                case 'martes':
                  if (eventsDayIds.containsKey('2')) {
                    if (!(eventsDayIds['2'].contains(myData['event_id']))) {
                      finalYearStatsModel.totalEvents += 1;
                      eventsDayIds['2'].add(myData['event_id']);
                    }
                  } else {
                    finalYearStatsModel.totalEvents += 1;
                    eventsDayIds['2'] = [myData['event_id']];
                  }
                  break;
                case 'miércoles':
                  if (eventsDayIds.containsKey('3')) {
                    if (!(eventsDayIds['3'].contains(myData['event_id']))) {
                      finalYearStatsModel.totalEvents += 1;
                      eventsDayIds['3'].add(myData['event_id']);
                    }
                  } else {
                    finalYearStatsModel.totalEvents += 1;
                    eventsDayIds['3'] = [myData['event_id']];
                  }
                  break;
                case 'jueves':
                  if (eventsDayIds.containsKey('4')) {
                    if (!(eventsDayIds['4'].contains(myData['event_id']))) {
                      finalYearStatsModel.totalEvents += 1;
                      eventsDayIds['4'].add(myData['event_id']);
                    }
                  } else {
                    finalYearStatsModel.totalEvents += 1;
                    eventsDayIds['4'] = [myData['event_id']];
                  }
                  break;
                case 'viernes':
                  if (eventsDayIds.containsKey('5')) {
                    if (!(eventsDayIds['5'].contains(myData['event_id']))) {
                      finalYearStatsModel.totalEvents += 1;
                      eventsDayIds['5'].add(myData['event_id']);
                    }
                  } else {
                    finalYearStatsModel.totalEvents += 1;
                    eventsDayIds['5'] = [myData['event_id']];
                  }
                  break;
                case 'sábado':
                  if (eventsDayIds.containsKey('6')) {
                    if (!(eventsDayIds['6'].contains(myData['event_id']))) {
                      finalYearStatsModel.totalEvents += 1;
                      eventsDayIds['6'].add(myData['event_id']);
                    }
                  } else {
                    finalYearStatsModel.totalEvents += 1;
                    eventsDayIds['6'] = [myData['event_id']];
                  }
                  break;
                case 'domingo':
                  if (eventsDayIds.containsKey('7')) {
                    if (!(eventsDayIds['7'].contains(myData['event_id']))) {
                      finalYearStatsModel.totalEvents += 1;
                      eventsDayIds['7'].add(myData['event_id']);
                    }
                  } else {
                    finalYearStatsModel.totalEvents += 1;
                    eventsDayIds['7'] = [myData['event_id']];
                  }
                  break;
                default:
              }
            }

            //Jobs - graph
            int indexJob = percentagesJobs.indexWhere((currentPercentage) =>
                currentPercentage.jobValue ==
                myData['details']['job']['value']);

            if (indexJob == -1) {
              percentagesJobs.add(JobPercentageModel.fromMap(myData));
            } else {
              percentagesJobs[indexJob].count += 1;
            }
          }
        }
        finalYearStatsModel.totalRevenues = (finalYearStatsModel.totalIncome -
            finalYearStatsModel.totalExpenses);
      });

      if (userType == 'client') {
        finalYearStatsModel.favoriteEmployees.addAll(
            yearStatsParams.authProvider.webUser.company.favoriteEmployees);
      }

      if (userType != 'client' &&
          yearStatsParams.adminDashboardType != 'general') {
        List<ClientEmployee> listFavoritesPerClient = [];

        ClientEntity client = allClients.firstWhere(
          (element) => element.accountInfo.id == yearStatsParams.companyId,
        );
        listFavorites = client.favoriteEmployees.values.toList();
        finalYearStatsModel.favoriteEmployees.clear();
        for (Map<String, dynamic> favorite in listFavorites) {
          listFavoritesPerClient.add(ClientEmployeeModel.fromMap(favorite));
        }

        finalYearStatsModel.favoriteEmployees.addAll(listFavoritesPerClient);
      }

      getTopJobs(percentagesJobs, finalYearStatsModel);

      getTopEmployeesByHour(finalYearStatsModel);

      // yearStatsParams.endDate.difference(yearStatsParams.startDate).inDays;
      int numItems = daysDifference >= 30
          ? 12
          : daysDifference < 30 && daysDifference >= 8
              ? 5
              : 7;
      for (var i = 1; i <= numItems; i++) {
        finalYearStatsModel.yearExpenses.add(
          daysDifference >= 30
              ? FlSpot(
                  i.toDouble(),
                  (!expensesCoords.containsKey('$i'))
                      ? 0
                      : expensesCoords['$i'])
              : daysDifference < 30 && daysDifference >= 8
                  ? FlSpot(
                      i.toDouble(),
                      (!expensesCoordsWeek.containsKey('$i'))
                          ? 0
                          : expensesCoordsWeek['$i'],
                    )
                  : FlSpot(
                      i.toDouble(),
                      (!expensesCoordsDay.containsKey('$i'))
                          ? 0
                          : expensesCoordsDay['$i'],
                    ),
        );
        finalYearStatsModel.yearIncome.add(
          daysDifference >= 30
              ? FlSpot(i.toDouble(),
                  (!incomeCoords.containsKey('$i')) ? 0 : incomeCoords['$i'])
              : daysDifference < 30 && daysDifference >= 8
                  ? FlSpot(
                      i.toDouble(),
                      (!incomeCoordsWeek.containsKey('$i'))
                          ? 0
                          : incomeCoordsWeek['$i'])
                  : FlSpot(
                      i.toDouble(),
                      (!incomeCoordsDay.containsKey('$i'))
                          ? 0
                          : incomeCoordsDay['$i']),
        );

        finalYearStatsModel.yearRevenues.add(FlSpot(
            i.toDouble(),
            (finalYearStatsModel.yearIncome.last.y -
                finalYearStatsModel.yearExpenses.last.y)));

        finalYearStatsModel.yearEvents.add(
          BarChartGroupData(
            x: i,
            barRods: [
              daysDifference >= 30
                  ? BarChartRodData(
                      toY: (!eventsMonthIds.containsKey('$i'))
                          ? 0
                          : eventsMonthIds['$i'].length,
                      width: 10,
                    )
                  : daysDifference < 30 && daysDifference >= 8
                      ? BarChartRodData(
                          toY: (!eventsWeekIds.containsKey('$i'))
                              ? 0
                              : eventsWeekIds['$i'].length,
                          width: 10,
                        )
                      : BarChartRodData(
                          toY: (!eventsDayIds.containsKey('$i'))
                              ? 0
                              : eventsDayIds['$i'].length,
                          width: 10,
                        )
            ],
          ),
        );
        finalYearStatsModel.yearHours.add(BarChartGroupData(x: i, barRods: [
          daysDifference >= 30
              ? BarChartRodData(
                  toY: (!hoursMonth.containsKey('$i')) ? 0 : hoursMonth['$i'],
                  width: 10,
                )
              : daysDifference < 30 && daysDifference >= 8
                  ? BarChartRodData(
                      toY: (!hoursWeek.containsKey('$i')) ? 0 : hoursWeek['$i'],
                      width: 10,
                    )
                  : BarChartRodData(
                      toY: (!hoursDay.containsKey('$i')) ? 0 : hoursDay['$i'],
                      width: 10,
                    )
        ]));
        finalYearStatsModel.yearRequests.add(BarChartGroupData(x: i, barRods: [
          daysDifference >= 30
              ? BarChartRodData(
                  toY: (!requestsCoords.containsKey('$i'))
                      ? 0
                      : requestsCoords['$i'],
                  width: 10,
                )
              : daysDifference < 30 && daysDifference >= 8
                  ? BarChartRodData(
                      toY: (!requestsCoordsWeek.containsKey('$i'))
                          ? 0
                          : requestsCoordsWeek['$i'],
                      width: 10,
                    )
                  : BarChartRodData(
                      toY: (!requestsCoordsDay.containsKey('$i'))
                          ? 0
                          : requestsCoordsDay['$i'],
                      width: 10,
                    )
        ]));
      }

      if (yearStatsParams.isFirstTime) {
        finalYearStatsModel.cutOfWeekTotals!.totalRevenue =
            finalYearStatsModel.cutOfWeekTotals!.totalClientsPay -
                finalYearStatsModel.cutOfWeekTotals!.totalToPayEmployees;
      }

      YearStats? finalYearStats = finalYearStatsModel;

      return finalYearStats;
    } catch (e) {
      if (kDebugMode) {
        print('Error GetYearStatsRemoteDataSource, getYearStats $e');
      }
      throw ServerException("$e");
    }
  }

  validateIfCanBeAdded(String keyToValidate, Map<String, dynamic> mapToValidate,
      var valueToAdd) {
    if (mapToValidate.containsKey(keyToValidate)) {
      mapToValidate[keyToValidate] += valueToAdd;
    } else {
      mapToValidate[keyToValidate] = valueToAdd;
    }
  }

  getTopJobs(
      List<JobPercentage> percentagesJobs, YearStatsModel finalYearStatsModel) {
    percentagesJobs.sort(((a, b) => b.count - a.count));

    if (percentagesJobs.length >= 11) {
      JobPercentage lastJobPercentage =
          JobPercentageModel(count: 0, jobValue: 'other', jobName: 'Otro');

      for (var i = 10; i < percentagesJobs.length; i++) {
        lastJobPercentage.count += percentagesJobs[i].count;
      }
      percentagesJobs.removeRange(10, percentagesJobs.length);
      percentagesJobs.add(lastJobPercentage);
    }

    finalYearStatsModel.yearJobs.addAll(percentagesJobs);
  }

  getTopEmployeesByHour(YearStatsModel finalYearStatsModel) {
    finalYearStatsModel.topEmployeesByHour
        .sort(((a, b) => b.hoursWorked.compareTo(a.hoursWorked)));

    //TOP 20
    if (finalYearStatsModel.topEmployeesByHour.length >= 21) {
      finalYearStatsModel.topEmployeesByHour
          .removeRange(20, finalYearStatsModel.topEmployeesByHour.length);
    }
  }

  Map<String, dynamic> getCutOfWeekInfo(
      DateTime today, GeneralInfoProvider generalInfoProvider) {
    DateTime startDate;
    DateTime finalDate;

    if (generalInfoProvider.generalInfo.countryInfo.paymentsTimes['type'] ==
        'weekly') {
      startDate = today.subtract(Duration(
        days: (today.weekday -
                generalInfoProvider
                    .generalInfo.countryInfo.paymentsTimes['weekday_cut']) %
            DateTime.daysPerWeek as int,
      ));

      finalDate = today.add(Duration(
        days: ((generalInfoProvider
                        .generalInfo.countryInfo.paymentsTimes['weekday_cut'] -
                    1) -
                today.weekday) %
            DateTime.daysPerWeek,
      ));
    } else {
      //biweekly
      if (today.day < 15) {
        startDate = DateTime(today.year, today.month, 1, 0, 0);
        finalDate = DateTime(today.year, today.month, 15, 0, 0);
      } else {
        startDate = DateTime(today.year, today.month, 16, 0, 0);
        finalDate = DateTime(today.year, today.month + 1, 0, 0, 0);
      }
    }
    String cutOfWeekText =
        'Semana ${DateFormat('d MMMM', 'es_CO').format(startDate)} - ${DateFormat('d MMMM yyyy', 'es_CO').format(finalDate)}';
    List cutOfWeekSearch = [
      DateFormat('yyyy-MM-dd').format(startDate),
      DateFormat('yyyy-MM-dd').format(finalDate)
    ];

    return {
      'dates': [startDate, finalDate],
      'datesString': cutOfWeekText,
      'cutSearch': cutOfWeekSearch,
    };
  }

  checkIfAppliesCutOfWeek(
      List dates, CutOfWeekTotals cutOfWeekTotals, Map<String, dynamic> data) {
    try {
      DateTime dateWeekStart = DateTime.parse(data['week_start']);
      DateTime dateWeekEnd = DateTime.parse(data['week_end']);
      DateTime dateInitial = DateTime.parse(dates[0]);
      DateTime dateFinish = DateTime.parse(dates[1]);

      int compareDateWeekStart = dateWeekStart.compareTo(dateInitial);
      int compareDateWeekEnd = dateWeekEnd.compareTo(dateFinish);

      if (compareDateWeekStart >= 0 && compareDateWeekEnd <= 0) {
        cutOfWeekTotals.totalClientsPay +=
            data['details']['fare']['total_client_pays'];
        cutOfWeekTotals.totalToPayEmployees +=
            data['details']['fare']['total_to_pay_employee'];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error GetYearStatsRemoteDataSource, checkIfAppliesCutOfWeek $e');
      }
    }
  }
}
