import 'dart:math';

import 'package:flutter/material.dart';
import 'package:memory_game/config/utils/code_util.dart';

class MemoryGameProvider with ChangeNotifier {
  int level = 1;
  int numberAttemps = 0;
  bool isFirstEntry = true;
  int showingCardsNumber = 0;
  bool showDialog = false;
  int numberOfCardsToMatchPerLevel = 2;

  void updateNumberAttemps() {
    numberAttemps++;
    notifyListeners();
  }

  Map<String, dynamic> previusCard = {};
  Map<String, dynamic> currentCard = {};

  List<int> valuesSelected = [];

  List<Map<String, dynamic>> cards = [];

  void nextLevel() {
    level++;
    switch (level) {
      case > 1 && <= 5:
        loadCardsToShow(8);
        break;
      case > 5 && <= 10:
        loadCardsToShow(12);
        break;
      case > 10 && <= 20:
        numberOfCardsToMatchPerLevel = 3;
        loadCardsToShow(15);
        break;
      case > 20 && <= 50:
        numberOfCardsToMatchPerLevel = 4;
        loadCardsToShow(28);
        break;
      case > 50 && <= 100:
        numberOfCardsToMatchPerLevel = 5;
        loadCardsToShow(50);
        break;
      case > 100:
        numberOfCardsToMatchPerLevel = 6;
        loadCardsToShow(72);
        break;
      default:
    }
  }

  void loadCardsToShow(int numberOfCards) {
    int value = 0;
    if (numberOfCards == -1) {
      for (int i = 0; i < 2; i++) {
        IconData icon = CodeUtil.icons[Random().nextInt(CodeUtil.icons.length)];
        cards.add({
          'icon': icon,
          'is_selected': false,
          'value': value,
          'keep_showing': false,
        });
        cards.add({
          'icon': icon,
          'is_selected': false,
          'value': value + numberOfCardsToMatchPerLevel,
          'keep_showing': false,
        });
        value++;
      }
    } else {
      for (int i = 0; i < numberOfCards / numberOfCardsToMatchPerLevel; i++) {
        IconData icon = CodeUtil.icons[Random().nextInt(CodeUtil.icons.length)];
        if (cards.every((element) => element['icon'] != icon)) {
          cards.add({
            'icon': icon,
            'is_selected': false,
            'value': value,
            'keep_showing': false,
          });
          cards.add({
            'icon': icon,
            'is_selected': false,
            'value': (value + (numberOfCards / numberOfCardsToMatchPerLevel))
                .toInt(),
            'keep_showing': false,
          });
          value++;
        }
      }
      cards.shuffle();
    }
  }

  void showCard(int value) async {
    changeStatusCard(value);

    if (cards.every((element) => element['is_selected'])) showDialog = true;
    if (showingCardsNumber == 2) {
      bool resp = previusCard['icon'] == currentCard['icon'];
      if (!resp) {
        currentCard = {};
        previusCard = {};
        await Future.delayed(
          const Duration(milliseconds: 600),
          () => changeStatusCard(-1),
        );
      } else {
        valuesSelected.add(currentCard['value']);
        valuesSelected.add(previusCard['value']);
        cards.firstWhere((element) => element['value'] == currentCard['value'])[
            'keep_showing'] = true;
        cards.firstWhere((element) => element['value'] == previusCard['value'])[
            'keep_showing'] = true;
      }
      numberAttemps++;
      showingCardsNumber = 0;
    }
    notifyListeners();
  }

  void changeStatusCard(int value) {
    if (value != -1) {
      for (Map<String, dynamic> element in cards) {
        if (element['value'] == value) {
          element['is_selected'] = true;
          if (currentCard.isEmpty) {
            currentCard = element;
            showingCardsNumber++;
          } else {
            previusCard = currentCard;
            currentCard = element;
            showingCardsNumber++;
          }
        }
      }
    } else {
      for (Map<String, dynamic> element in cards) {
        if (!valuesSelected.contains(element['value'])) {
          element['is_selected'] = false;
          element['keep_showing'] = false;
        }
      }
    }
    notifyListeners();
  }

  Future<void> resetGame([bool finishGame = true]) async {
    if (!finishGame) await Future.delayed(const Duration(seconds: 3));
    currentCard = {};
    previusCard = {};
    showingCardsNumber = 0;
    numberAttemps = 0;
    showDialog = false;
    valuesSelected = [];
    changeStatusCard(-1);
    cards.shuffle();
    notifyListeners();
  }
}
