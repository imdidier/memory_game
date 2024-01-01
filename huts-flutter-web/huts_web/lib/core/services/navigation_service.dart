import 'package:flutter/material.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

  static void navigateTo({required String routeName}) =>
      navigationKey.currentState!.pushNamed(routeName);

  static void replaceTo({required String routeName}) =>
      navigationKey.currentState!.pushReplacementNamed(routeName);

  static void goback() => navigationKey.currentState!.pop();

  static BuildContext? getGlobalContext() => navigationKey.currentContext;
}
