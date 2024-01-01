import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';

import '../../../auth/display/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isLoaded = false;
  UiVariables uiVariables = UiVariables();
  late AuthProvider authProvider;

  @override
  Widget build(BuildContext context) {
   // UiMethods.getDeviceSize(context: context);
    return Container();
  }
}
