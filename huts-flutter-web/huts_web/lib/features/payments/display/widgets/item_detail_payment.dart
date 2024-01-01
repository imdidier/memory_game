import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';

class ItemDetailPayment extends StatelessWidget {
  final ScreenSize screenSize;
  final String title;
  final String value;
  final bool isDesktop;
  const ItemDetailPayment(
      {Key? key,
      required this.screenSize,
      required this.title,
      required this.value,
      required this.isDesktop})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          text: "$title: ",
          style: TextStyle(
            fontSize: (isDesktop || screenSize.blockWidth >= 580) ? 18 : 15,
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                  fontSize:
                      (isDesktop || screenSize.blockWidth >= 580) ? 18 : 15,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
