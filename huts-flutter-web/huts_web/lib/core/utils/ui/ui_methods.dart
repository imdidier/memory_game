import 'package:flutter/material.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class UiMethods {
  UiMethods._privateConstructor();

  static final UiMethods _instance = UiMethods._privateConstructor();

  factory UiMethods() {
    return _instance;
  }

  // static void getDeviceSize({required BuildContext context}) {
  //   UiVariables.screenWidth = MediaQuery.of(context).size.width;
  //   UiVariables.screenHeight = MediaQuery.of(context).size.height;
  //   UiVariables.absoluteHeight = MediaQuery.of(context).size.height -
  //       MediaQuery.of(context).viewPadding.top;
  // }

  showLoadingDialog({required BuildContext context}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
            title: Container(
              width: 200,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  const Text('Cargando'),
                  SizedBox(
                    height: 100,
                    width: 170,
                    child: OverflowBox(
                      minHeight: 100,
                      maxHeight: 150,
                      child: Lottie.asset(
                        'assets/gifs/loading_huts.json',
                        repeat: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  hideLoadingDialog({required BuildContext context}) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static String getJobsNamesBykeys(List<String> keys) {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return keys.join(", ");

    String jobs = "";

    GeneralInfoProvider generalInfoProvider =
        Provider.of<GeneralInfoProvider>(globalContext, listen: false);

    for (var i = 0; i < keys.length; i++) {
      String key = keys[i];

      if (!generalInfoProvider.generalInfo.countryInfo.jobsFares
          .containsKey(key)) {
        key += "_";

        if (!generalInfoProvider.generalInfo.countryInfo.jobsFares
            .containsKey(key)) {
          jobs += (i < keys.length - 1) ? "$key, " : key;
          continue;
        }
      }

      jobs += (i < keys.length - 1)
          ? "${generalInfoProvider.generalInfo.countryInfo.jobsFares[key]["name"].trim()}, "
          : generalInfoProvider.generalInfo.countryInfo.jobsFares[key]["name"]
              .trim();
    }

    return jobs;
  }
}
