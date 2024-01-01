import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';

class HeaderTable extends StatelessWidget {
  final String title;
  final bool isDesktop;
  final ScreenSize screenSize;
  const HeaderTable(
      {Key? key,
      required this.isDesktop,
      required this.screenSize,
      required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
            fontSize: (isDesktop || screenSize.blockWidth >= 580) ? 20 : 16,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
