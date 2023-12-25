import 'package:flutter/material.dart';

class CurrentContext {
  static GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

  static BuildContext? getGlobalContext() => navigationKey.currentContext;
}
