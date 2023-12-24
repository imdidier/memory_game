import 'package:flutter/material.dart';

class AppTheme {
  ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: Colors.purpleAccent,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      brightness: Brightness.light,
    );
  }
}
