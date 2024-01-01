import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:memory_game/ui/providers/memory_game_provider.dart';
import 'package:provider/provider.dart';

import '../../config/helpers/helpers.dart';

class CardItem extends StatelessWidget {
  const CardItem({super.key, required this.card});

  final Map<String, dynamic> card;
  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();
    bool canChangeStatusOfCards = memoryGameProvider.showingCardsNumber !=
            memoryGameProvider.numberOfCardsToMatchPerLevel &&
        !card['is_selected'];
    return FlipCard(
      key: card['key'],
      speed: 250,
      side: CardSide.BACK,
      flipOnTouch: canChangeStatusOfCards,
      onFlip: () async {
        await Future.delayed(
          const Duration(milliseconds: 300),
          () async => await memoryGameProvider.showCard(card['value']),
        );
        memoryGameProvider.updateDataProvider();
      },
      front: _FrontContent(
        card['icon'],
        memoryGameProvider.getWidth(),
        memoryGameProvider.getHeight(),
        card['keep_showing'],
      ),
      back: _BackContent(
        memoryGameProvider.getWidth(),
        memoryGameProvider.getHeight(),
      ),
    );
  }
}

class _FrontContent extends StatelessWidget {
  const _FrontContent(this.icon, this.width, this.height, this.keepShowing);
  final IconData icon;
  final double width;
  final double height;
  final bool keepShowing;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: height,
      width: width,
      margin: EdgeInsets.all(ScreenSize.width * 0.02),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        boxShadow: const [
          BoxShadow(
            color: Colors.greenAccent,
            offset: Offset(0, 3),
            blurRadius: 5,
          ),
        ],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(width: keepShowing ? 5 : 0),
      ),
      child: Icon(
        icon,
        size: 40,
        color: Colors.white,
      ),
    );
  }
}

class _BackContent extends StatelessWidget {
  const _BackContent(this.width, this.height);
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.brown,
        boxShadow: const [
          BoxShadow(
            color: Colors.greenAccent,
            offset: Offset(0, 3),
            blurRadius: 5,
          ),
        ],
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}
