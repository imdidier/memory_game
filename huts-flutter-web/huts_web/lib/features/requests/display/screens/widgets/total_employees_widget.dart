import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';

class TotalEmployeesWidget extends StatelessWidget {
  final ScreenSize screenSize;
  final int plusValue;

  const TotalEmployeesWidget(
      {required this.screenSize, Key? key, required this.plusValue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("Colaboradores solicitados"),
        const SizedBox(height: 20),
        // (plusValue > 3)
        // ? Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     crossAxisAlignment: CrossAxisAlignment.center,
        //     children: [
        //       SizedBox(width: screenSize.width * 0.01),
        //        buildAvatar(
        //          xOffset: 0,
        //          assetPath: "images/people/chef.jpg",
        //        ),
        //        buildAvatar(
        //          xOffset: -12,
        //          assetPath: "images/people/waiter.jpg",
        //        ),
        //        buildAvatar(
        //          xOffset: -24,
        //          assetPath: "images/people/barista.jpg",
        //        ),
        //       buildPlusItem(),
        //     ],
        //   )
        // :
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // SizedBox(width: screenSize.width * 0.08),
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 26,
              child: Text(
                "$plusValue",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // SizedBox(width: screenSize.width * 0.08),
          ],
        ),
      ],
    );
  }

  Transform buildPlusItem() {
    return Transform.translate(
      offset: const Offset(-40, 0),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        radius: 26,
        child: Text(
          "+${plusValue - 3}",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Transform buildAvatar({required double xOffset, required String assetPath}) {
    return Transform.translate(
      offset: Offset(xOffset, 0),
      child: CircleAvatar(
        radius: 28,
        backgroundImage: AssetImage(
          assetPath,
        ),
      ),
    );
  }
}
