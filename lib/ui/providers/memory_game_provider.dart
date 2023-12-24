import 'package:flutter/material.dart';

class MemoryGameProvider with ChangeNotifier {
  int numberAttemps = 0;
  bool isFirstEntry = true;
  int showingCardsNumber = 0;
  bool showDialog = false;

  void updateNumberAttemps() {
    numberAttemps++;
    notifyListeners();
  }

  Map<String, dynamic> previusCard = {};
  Map<String, dynamic> currentCard = {};

  List<int> valuesSelected = [];

  List<Map<String, dynamic>> cards = [
    {
      'icon': Icons.abc_outlined,
      'is_selected': false,
      'value': 0,
    },
    {
      'icon': Icons.baby_changing_station,
      'is_selected': false,
      'value': 1,
    },
    {
      'icon': Icons.cabin,
      'is_selected': false,
      'value': 2,
    },
    {
      'icon': Icons.dangerous,
      'is_selected': false,
      'value': 3,
    },
    {
      'icon': Icons.e_mobiledata,
      'is_selected': false,
      'value': 4,
    },
    {
      'icon': Icons.face,
      'is_selected': false,
      'value': 5,
    },
    {
      'icon': Icons.abc_outlined,
      'is_selected': false,
      'value': 6,
    },
    {
      'icon': Icons.baby_changing_station,
      'is_selected': false,
      'value': 7,
    },
    {
      'icon': Icons.cabin,
      'is_selected': false,
      'value': 8,
    },
    {
      'icon': Icons.dangerous,
      'is_selected': false,
      'value': 9,
    },
    {
      'icon': Icons.e_mobiledata,
      'is_selected': false,
      'value': 10,
    },
    {
      'icon': Icons.face,
      'is_selected': false,
      'value': 11,
    },
  ];

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
          () => changeStatusCard(null),
        );
      } else {
        valuesSelected.add(currentCard['value']);
        valuesSelected.add(previusCard['value']);
      }
      numberAttemps++;
      showingCardsNumber = 0;
    }
    notifyListeners();
  }

  void changeStatusCard(int? value) {
    //Sin nulos
    if (value != null) {
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
    changeStatusCard(null);
    cards.shuffle();
    notifyListeners();
  }
}
