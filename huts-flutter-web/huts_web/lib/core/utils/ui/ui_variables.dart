import 'package:flutter/material.dart';

class UiVariables {
  UiVariables._privateConstructor();

  static final UiVariables _instance = UiVariables._privateConstructor();

  factory UiVariables() {
    return _instance;
  }

  // static double absoluteHeight = 0;
  // static double screenHeight = 0;
  // static double screenWidth = 0;

  static Color primaryColor = const Color(0XFFFF1736);
  static Color lightRedColor = const Color(0XFFF4C0C7);
  static Color ultraLightRedColor = const Color.fromARGB(168, 243, 208, 212);
  static Color lightBlueColor = const Color(0XFFF6F9FE);

  static bool isShowingFlushbar = false;

  static BoxDecoration boxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: const BorderRadius.all(Radius.circular(15)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        offset: const Offset(3, 3),
        blurRadius: 13,
      )
    ],
  );

  InputDecoration customInputDecoration(String hint, {bool isSearch = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black),
      labelStyle: const TextStyle(color: Colors.black),
      prefixStyle: const TextStyle(color: Colors.black),
      prefixIcon: isSearch
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Icon(
                Icons.search,
                color: primaryColor,
              ),
            )
          : const SizedBox(),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );
  }

  static Tab customTab(String title) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: UiVariables.primaryColor, width: 2)),
        child: Align(
          alignment: Alignment.center,
          child: Text(title),
        ),
      ),
    );
  }
}
