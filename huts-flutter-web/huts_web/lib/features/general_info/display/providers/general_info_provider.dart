// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/ui/providers/sidebar_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/data/datasources/general_info_remote_datasource.dart';
import 'package:huts_web/features/general_info/data/models/country_info_model.dart';
import 'package:huts_web/features/general_info/data/repositories/general_info_repository_impl.dart';
import 'package:huts_web/features/general_info/domain/entities/general_info_entity.dart';
import 'package:huts_web/features/general_info/domain/entities/other_info_entity.dart';
import 'package:huts_web/features/general_info/domain/use_cases/get_general_info.dart';
import 'package:huts_web/features/messages/data/models/message_job.dart';
import 'package:huts_web/features/messages/display/provider/messages_provider.dart';
import 'package:provider/provider.dart';

class GeneralInfoProvider with ChangeNotifier {
  late GeneralInfo generalInfo;
  late OtherInfo otherInfo;
  ScreenSize screenSize = ScreenSize(
    absoluteHeight: 0,
    notchHeight: 0,
    height: 0,
    width: 0,
    blockWidth: 0,
  );
  bool isFirstTime = false;
  bool isDesktop = true;

  List<Map<String, dynamic>> jobsFares = [];
  Map<String, dynamic> listHolidays = {};

  bool showWebSideBar = true;

  late AnimationController webSideBarAnimationController;

  Future<void> showHideWebSideBar() async {
    if (showWebSideBar) {
      await webSideBarAnimationController.reverse();
      showWebSideBar = false;
    } else {
      showWebSideBar = true;
    }

    BuildContext? context = NavigationService.getGlobalContext();

    if (context != null) {
      context.read<SidebarProvider>().showing = showWebSideBar;
    }

    notifyListeners();
  }

  Future<void> getGeneralInfoOrFail(BuildContext context) async {
    GeneralInfoRepositoryImpl repository =
        GeneralInfoRepositoryImpl(GeneralInfoRemoteDataSourceImpl());
    final generalInfoResp =
        await GetGeneralInfo(repository).getGeneralInfo(context);
    generalInfoResp.fold((Failure failure) => log(failure.errorMessage ?? ""),
        (GeneralInfo? info) async {
      if (info == null) return;
      generalInfo = info;
      listHolidays = generalInfo.countryInfo.holidays;
      MessagesProvider messagesProvider =
          Provider.of<MessagesProvider>(context, listen: false);
      messagesProvider.jobsList.clear();
      generalInfo.countryInfo.jobsFares.forEach(
        (key, value) {
          messagesProvider.jobsList.add(
            MessageJob(
                isSelected: false, name: value["name"], value: value["value"]),
          );
        },
      );

      messagesProvider.jobsList[0].isSelected = true;

      // generalInfo.countryInfo.employeesStatus.forEach((key, value) {
      //   MessageEmployeeStatus employeeStatus = MessageEmployeeStatus(
      //       number: value["number"], name: value["name"], isSelected: false);
      // });

      jobsFares = List<Map<String, dynamic>>.from(
        [
          ...generalInfo.countryInfo.jobsFares.values.toList().map((e) {
            e["is_expanded"] = false;
            return e;
          })
        ],
      );

      final otherInfoResp =
          await GetGeneralInfo(repository).getOtherInfo(context);

      otherInfoResp.fold((Failure failure) => failure.errorMessage ?? "",
          (OtherInfo? info2) {
        if (info2 == null) return;
        otherInfo = info2;

        notifyListeners();
      });
    });
  }

  void removeLocalJob(String jobKey) {
    jobsFares.removeWhere((element) => element["value"] == jobKey);
    notifyListeners();
  }

  void addLocalJob(Map<String, dynamic> job) {
    job["is_expanded"] = false;
    jobsFares.add(job);
    generalInfo.countryInfo.jobsFares[job["value"]] = job;
    notifyListeners();
  }

  void getScreenSize({required BuildContext context}) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    screenSize.blockWidth = screenWidth;
    screenSize.notchHeight = MediaQuery.of(context).viewPadding.top;
    screenSize.width = screenWidth + getWidthBreakpoint(screenWidth);
    screenSize.height = screenHeight; //- getHeightBreakpoint(screenHeight);
    screenSize.absoluteHeight = screenSize.height - screenSize.notchHeight;
    if (isFirstTime) return;
    isFirstTime = true;
    otherInfo = OtherInfo(
      webRoutes: {},
      webUserTypes: {},
      webUserSubtypes: {},
      employeesActivityCategories: {},
      systemRoles: {},
    );
    initGeneralInfoEmpty();
  }

  void initGeneralInfoEmpty() {
    generalInfo = GeneralInfo(
      statusBannerInfo: {},
      distanceFilterUpdatesMeters: 0,
      distanceFilterUpdatesMilliseconds: 0,
      locationTimeOutSeconds: 0,
      helpUrl: '',
      termsUrl: '',
      minMinutesToArrive: 0,
      minMetersToArrive: 0,
      minMinutesToListenRequest: 0,
      unabledHours: [],
      ratingOptions: [],
      updatesInfo: {},
      countryInfo: CountryInfoModel.fromMap({}),
      nightWorkshift: {},
    );
  }

  void updateScreenSize(Size newSize) {
    screenSize.blockWidth = newSize.width;
    screenSize.width = newSize.width + getWidthBreakpoint(newSize.width);
    screenSize.height = newSize.height; //- getHeightBreakpoint(newSize.height);
    screenSize.absoluteHeight = screenSize.height - screenSize.notchHeight;
    isDesktop = screenSize.blockWidth >= 1300;
    notifyListeners();
  }

  double getWidthBreakpoint(double width) {
    if (width >= 992 && width < 2000) return 0;
    if (width >= 2000) return -580;
    return 580;
  }

  // double getHeightBreakpoint(double height) {
  //   if (height > 600) return 0;
  //   return 100;
  // }
}
