import 'package:flutter/material.dart';

import '../../ui_variables.dart';

class CustomTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const CustomTooltip({required this.message, required this.child, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: UiVariables.primaryColor.withOpacity(0.7),
      ),
      message: message,
      child: child,
    );
  }
}
