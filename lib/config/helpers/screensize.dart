import 'package:flutter/material.dart';
import 'package:memory_game/config/helpers/context.dart';

class ScreenSize {
  static double width = 0;
  static double height = 0;
  static double absoluteHeight = 0;
  static double top = 0;

  static void init() {
    BuildContext? context = CurrentContext.getGlobalContext();
    if (context == null) return;
    double deviceHeight = MediaQuery.of(context).size.height;
    height = deviceHeight;
    width = MediaQuery.of(context).size.width;
    absoluteHeight = deviceHeight - top;
  }
}
