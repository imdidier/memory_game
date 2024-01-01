import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';

class TotalEventsWidget extends StatelessWidget {
  final String title;
  final int value;
  final Icon icon;
  final Color cardColor;
  final ScreenSize screenSize;

  const TotalEventsWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.cardColor,
    required this.screenSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildCard();
  }

  Container buildCard() {
    return Container(
      width: screenSize.blockWidth >= 920
          ? screenSize.width * 0.084
          : screenSize.blockWidth * 0.22,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: cardColor,
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 2,
            color: Colors.black12,
          ),
        ],
      ),
      child: buildContent(),
    );
  }

  Widget buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        const SizedBox(height: 15),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: screenSize.blockWidth >= 920 ? 16 : 12),
        ),
        const SizedBox(height: 15),
        Text(
          "$value",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenSize.blockWidth >= 920 ? 16 : 12),
        ),
      ],
    );
  }
}
