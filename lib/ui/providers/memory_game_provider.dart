import 'dart:math';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:memory_game/config/utils/code_util.dart';

import '../../config/helpers/helpers.dart';

class MemoryGameProvider with ChangeNotifier {
  int currentLevel = 1;
  int numberAttemps = 0;
  bool isFirstEntry = true;
  int showingCardsNumber = 0;
  bool isShowingDialog = false;
  int numberOfCardsToMatchPerLevel = 2;
  int numberOfLevels = 6;
  bool finishedTheGame = false;
  List<IconData> icons = [];

  void updateNumberAttemps() {
    numberAttemps++;
    notifyListeners();
  }

  void updateDataProvider() => notifyListeners();

  List<Map<String, dynamic>> showingCards = [];

  List<int> valuesSelected = [];

  List<Map<String, dynamic>> cards = [];

  Future<void> nextLevel() async {
    await resetGame(false);
    currentLevel++;
    switch (currentLevel) {
      case > 1 && <= 5:
        loadCardsToShow(4);
        break;
      case > 5 && <= 10:
        loadCardsToShow(6);
        break;
      case > 10 && <= 20:
        numberOfCardsToMatchPerLevel = 3;
        loadCardsToShow(5);
        break;
      case > 20 && <= 50:
        numberOfCardsToMatchPerLevel = 4;
        loadCardsToShow(5);
        break;
      case > 50 && <= 100:
        numberOfCardsToMatchPerLevel = 5;
        loadCardsToShow(6);
        break;
      case > 100:
        numberOfCardsToMatchPerLevel = 6;
        loadCardsToShow(6);
        break;
      default:
    }
    notifyListeners();
  }

  double getWidth() {
    double resp = ScreenSize.height * 0.11;
    switch (currentLevel) {
      case >= 1 && <= 5:
        resp = ScreenSize.width * 0.35;
        break;
      case > 5 && <= 10:
        resp = ScreenSize.width * 0.25;
        break;
      case > 10 && <= 20:
        break;
      case > 20 && <= 50:
        break;
      case > 50 && <= 100:
        resp = ScreenSize.width * 0.2;

        break;
      case > 100:
        break;
      default:
        resp = ScreenSize.width * 0.4;
    }
    return resp;
  }

  double getHeight() {
    double resp = ScreenSize.height * 0.11;
    switch (currentLevel) {
      case >= 1 && <= 5:
        resp = ScreenSize.height * 0.15;
        break;
      case > 5 && <= 10:
        resp = ScreenSize.height * 0.14;
        break;
      case > 10 && <= 20:
        break;
      case > 20 && <= 50:
        break;
      case > 50 && <= 100:
        resp = ScreenSize.height * 0.2;

        break;
      case > 100:
        resp = ScreenSize.height * 0.6;
        break;
      default:
        resp = ScreenSize.height * 0.2;
    }
    return resp;
  }

  void loadCardsToShow(int numberOfCards) {
    cards = [];
    int valueIcon = 0;
    icons = [];
    for (int i = 0; i < numberOfCards; i++) {
      IconData icon = CodeUtil.icons[Random().nextInt(CodeUtil.icons.length)];
      if (cards.every((element) => element['icon'] != icon)) {
        icons.add(icon);
        for (int j = 0; j < numberOfCardsToMatchPerLevel; j++) {
          cards.add({
            'icon': icon,
            'is_selected': false,
            'value': valueIcon,
            'keep_showing': false,
            'key': GlobalKey<FlipCardState>(),
          });
          valueIcon += numberOfCards;
        }
        valueIcon = i + 1;
      } else {
        i--;
      }
    }
    cards.shuffle();
  }

  Future<void> showCard(int value) async {
    changeStatusCard(value);
    if (showingCardsNumber == numberOfCardsToMatchPerLevel) {
      showingCardsNumber = 0;
      IconData icon = showingCards.first['icon'];
      bool resp = showingCards.every((element) => element['icon'] == icon);
      if (!resp) {
        await Future.delayed(
          const Duration(milliseconds: 500),
          () async => await changeStatusCard(-1),
        );
        List<Map<String, dynamic>> showingCardsCopy = [...showingCards];
        int index = 0;
        await Future.forEach(showingCardsCopy, (element) async {
          if (showingCards[index]['key'].currentState!.isFront) {
            await showingCards[index]['key'].currentState!.toggleCard();
          }
          index++;
        });
      } else {
        await Future.forEach(showingCards, (element) {
          valuesSelected.add(element['value']);
          cards[element['value']]['keep_showing'] = true;
        });
      }
      showingCards.clear();
      numberAttemps++;
    }

    if (cards.every((element) => element['is_selected'])) {
      isShowingDialog = true;
      if (currentLevel == numberOfLevels) finishedTheGame = true;
    }
    notifyListeners();
  }

  Future<void> changeStatusCard(int value) async {
    if (value != -1) {
      for (Map<String, dynamic> element in cards) {
        if (element['value'] == value) {
          showingCards.add(element);
          element['is_selected'] = true;
          showingCardsNumber++;
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

  Future<void> resetGame(
      [bool finishGame = true, bool restoreGame = false]) async {
    // if (!finishGame) await Future.delayed(const Duration(seconds: 1));
    isShowingDialog = false;
    showingCards.clear();
    valuesSelected.clear();
    showingCardsNumber = 0;
    if (finishGame || restoreGame) {
      currentLevel = 1;
      finishedTheGame = false;
      numberAttemps = 0;
      numberOfCardsToMatchPerLevel = 2;
    }
    changeStatusCard(-1);
    cards.shuffle();
    notifyListeners();
  }
}
