import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingDialog {
  static Future<void> show(
      String text, BuildContext context, double width) async {
    return await showDialog(
      useSafeArea: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4,
            sigmaY: 4,
          ),
          child: AlertDialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titlePadding: const EdgeInsets.all(0),
            title: Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  height: width * 0.4,
                  width: width * 0.4,
                  child: Lottie.asset(
                    'assets/jsons/loading.json',
                    frameRate: FrameRate.max,
                  ),
                ),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: width * 0.05,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ),
        onWillPop: () {
          return Future.value(false);
        },
      ),
    );
  }

  static void hide(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).pop();
}
