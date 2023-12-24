import 'package:flutter/material.dart';
import 'package:memory_game/ui/providers/memory_game_provider.dart';
import 'package:provider/provider.dart';

class FinishGameDialog {
  static Future<bool> show({
    required String title,
    required String content,
    required BuildContext context,
  }) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(5),
          title: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 20,
              ),
            ),
          ),
          actions: <Widget>[
            GestureDetector(
              onTap: () {
                context.read<MemoryGameProvider>().resetGame();
                Navigator.of(context).pop(true);
              },
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                margin: const EdgeInsets.only(top: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(15)),
                child: const Text(
                  'Volver a jugar',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
