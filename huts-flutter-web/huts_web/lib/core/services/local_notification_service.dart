import 'package:flutter/material.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

class LocalNotificationService {
  static GlobalKey<ScaffoldMessengerState> localNotificationKey =
      GlobalKey<ScaffoldMessengerState>();

  static showSnackBar({
    required String type,
    required String message,
    required IconData icon,
    int duration = 4,
  }) {
    BuildContext? globalContext = localNotificationKey.currentContext;

    final SnackBar snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: type == "success" ? Colors.green[400] : Colors.orange,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      elevation: 2,
      width: globalContext == null
          ? 400
          : Provider.of<GeneralInfoProvider>(globalContext, listen: false)
                  .screenSize
                  .width *
              0.3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      duration: Duration(seconds: duration),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == "success" ? "¡Listo!" : "¡Ups!",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    localNotificationKey.currentState!.showSnackBar(snackBar);
  }
}
