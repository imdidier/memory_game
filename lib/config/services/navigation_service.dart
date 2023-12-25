import 'package:flutter/material.dart';

import '../helpers/helpers.dart';

class NavigationServices {
  static void goback() => CurrentContext.navigationKey.currentState!.pop();

  static void navigateTo({required Widget screen}) =>
      CurrentContext.navigationKey.currentState!
          .push(MaterialPageRoute(builder: (_) => screen));

  static void replaceTo({required Widget screen}) =>
      CurrentContext.navigationKey.currentState!
          .pushReplacement(MaterialPageRoute(builder: (_) => screen));
}
