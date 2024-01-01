// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:memory_game/ui/providers/memory_game_provider.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';

class FinishGameDialog {
  static Future<bool> show({
    required String title,
    required BuildContext context,
  }) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        MemoryGameProvider memoryGameProvider =
            context.read<MemoryGameProvider>();
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
              memoryGameProvider.finishedTheGame
                  ? 'Completaste el juego en ${memoryGameProvider.numberAttemps} intentos'
                  : 'Completaste el nivel ${memoryGameProvider.currentLevel}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 20,
              ),
            ),
          ),
          actions: <Widget>[
            GestureDetector(
              onTap: () async {
                if (!memoryGameProvider.finishedTheGame) {
                  LoadingDialog.show(
                    'Cargando siguiente nivel',
                    context,
                    ScreenSize.width,
                  );
                  await memoryGameProvider.nextLevel();
                  LoadingDialog.hide(context);
                } else {
                  memoryGameProvider.currentLevel = 1;
                  memoryGameProvider.loadCardsToShow(2);
                  memoryGameProvider.resetGame();
                }
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
                child: Text(
                  memoryGameProvider.finishedTheGame
                      ? 'Volver a jugar'
                      : 'Siguiente nivel',
                  style: const TextStyle(
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
