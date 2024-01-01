import 'package:flutter/material.dart';

import '../../ui_variables.dart';

class ButtonProgressIndicator extends StatelessWidget {
  final Color? color;
  const ButtonProgressIndicator({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      width: 25,
      child: CircularProgressIndicator(
        color: (color != null) ? color : UiVariables.primaryColor,
        strokeWidth: 2,
      ),
    );
  }
}
