// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:memory_game/config/helpers/screensize.dart';
import 'package:memory_game/ui/providers/memory_game_provider.dart';
import 'package:provider/provider.dart';

import '../../config/helpers/finish_game_dialog.dart';
import '../../config/helpers/loading_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void showDialog(BuildContext context, int numberAttemps) async {
    await Future.delayed(
      const Duration(milliseconds: 300),
      () => FinishGameDialog.show(
        title: 'Felicidades',
        content: 'Completaste el juego en $numberAttemps intentos',
        context: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();

    if (memoryGameProvider.showDialog) {
      showDialog(context, memoryGameProvider.numberAttemps);
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: const SizedBox(),
          title: Text(
            'Memory Game',
            style: TextStyle(
              color: Colors.black54,
              fontSize: ScreenSize.width * 0.07,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () async {
                LoadingDialog.show(
                    'Reiniciando juego', context, ScreenSize.width);
                await memoryGameProvider.resetGame(false);
                LoadingDialog.hide(context);
              },
              child: Padding(
                padding: EdgeInsets.only(right: ScreenSize.width * 0.03),
                child: const Icon(
                  Icons.restart_alt,
                  color: Colors.lightBlueAccent,
                ),
              ),
            ),
          ],
          centerTitle: true,
        ),
        body: Container(
          width: ScreenSize.width,
          padding: EdgeInsets.symmetric(horizontal: ScreenSize.width * 0.05),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.fill,
              opacity: 0.08,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: ScreenSize.width * 0.05),
              const _CurrentLevel(),
              SizedBox(height: ScreenSize.width * 0.05),
              const _NumberAttemp(),
              SizedBox(height: ScreenSize.width * 0.1),
              const _BuildCard(),
              SizedBox(height: ScreenSize.width * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard();

  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();
    memoryGameProvider.level = 7;
    return Expanded(
      child: GridView(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: memoryGameProvider.level == 1
              ? 2
              : memoryGameProvider.level > 1 && memoryGameProvider.level < 5
                  ? 4
                  : 3,
          crossAxisSpacing: ScreenSize.width * 0.06,
          mainAxisSpacing: ScreenSize.width * 0.06,
        ),
        children: List.generate(
          memoryGameProvider.cards.length,
          (index) {
            Map<String, dynamic> card = memoryGameProvider.cards[index];
            return _CardItem(card: card);
          },
        ),
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  const _CardItem({required this.card});

  final Map<String, dynamic> card;
  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();
    bool canChangeStatusOfCards = memoryGameProvider.showingCardsNumber ==
        memoryGameProvider.numberOfCardsToMatchPerLevel;
    return GestureDetector(
      onTap: card['is_selected'] || canChangeStatusOfCards
          ? null
          : () => memoryGameProvider.showCard(card['value']),
      child: Container(
        height: ScreenSize.height * 0.11,
        width: ScreenSize.height * 0.11,
        decoration: BoxDecoration(
          color: card['is_selected'] ? Colors.blueAccent : Colors.brown,
          boxShadow: const [
            BoxShadow(
              color: Colors.greenAccent,
              offset: Offset(0, 3),
              blurRadius: 5,
            ),
          ],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(width: card['keep_showing'] ? 5 : 0),
        ),
        child: card['is_selected']
            ? Icon(
                card['icon'],
                size: 40,
                color: Colors.white,
              )
            : const SizedBox(),
      ),
    );
  }
}

class _NumberAttemp extends StatelessWidget {
  const _NumberAttemp();

  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();

    return Container(
      width: ScreenSize.width,
      height: ScreenSize.height * 0.055,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.black45,
      ),
      alignment: Alignment.center,
      child: RichText(
        text: TextSpan(
          text: 'Número de intentos: ',
          style: TextStyle(
            fontSize: ScreenSize.width * 0.05,
            color: Colors.white,
          ),
          children: [
            TextSpan(
              text: '${memoryGameProvider.numberAttemps}',
              style: TextStyle(
                fontSize: ScreenSize.width * 0.05,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _CurrentLevel extends StatelessWidget {
  const _CurrentLevel();

  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();

    return Container(
      width: ScreenSize.width,
      height: ScreenSize.height * 0.055,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.black45,
      ),
      alignment: Alignment.center,
      child: Text(
        'Nivel: ${memoryGameProvider.level}',
        style: TextStyle(
          fontSize: ScreenSize.width * 0.1,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
