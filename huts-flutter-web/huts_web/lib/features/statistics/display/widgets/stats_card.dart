import 'package:flutter/material.dart';

import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({
    Key? key,
    required this.screenSize,
    required this.uiVariables,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.isDesktop,
  }) : super(key: key);

  final ScreenSize screenSize;
  final UiVariables uiVariables;
  final String title;
  final String value;
  final String subtitle;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: !isDesktop ? screenSize.width : screenSize.width * 0.26,
        height: isDesktop ? screenSize.height * 0.14 : screenSize.height * 0.09,
        decoration: UiVariables.boxDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: isDesktop ? 24 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: isDesktop ? 18 : 10),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: isDesktop ? 14 : 9),
            ),
          ],
        ));
  }
}
