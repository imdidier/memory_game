// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:memory_game/config/helpers/screensize.dart';
import 'package:memory_game/ui/providers/memory_game_provider.dart';
import 'package:provider/provider.dart';

import '../../config/helpers/finish_game_dialog.dart';
import '../../config/helpers/loading_dialog.dart';
import '../widgets/card_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void showDialog(BuildContext context, int numberAttemps) async {
    await Future.delayed(
      const Duration(milliseconds: 300),
      () => FinishGameDialog.show(
        title: 'Felicidades',
        context: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();

    if (memoryGameProvider.isShowingDialog) {
      showDialog(context, memoryGameProvider.numberAttemps);
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(
                'Memory Game',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: ScreenSize.width * 0.07,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Nivel ${memoryGameProvider.currentLevel}/${memoryGameProvider.numberOfLevels}',
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: ScreenSize.width * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: const _BuildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            LoadingDialog.show('Reiniciando juego', context, ScreenSize.width);
            memoryGameProvider.loadCardsToShow(2);
            await memoryGameProvider.resetGame(false, true);
            LoadingDialog.hide(context);
          },
          backgroundColor: Colors.blueAccent,
          child: Icon(
            Icons.restart_alt,
            color: Colors.white,
            size: ScreenSize.width * 0.08,
          ),
        ),
      ),
    );
  }
}

class _BuildBody extends StatelessWidget {
  const _BuildBody();

  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();
    return Container(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LabelByLevel(),
              SizedBox(height: ScreenSize.width * 0.02),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    memoryGameProvider.icons.length,
                    (index) {
                      IconData icon = memoryGameProvider.icons[index];
                      return Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.lightBlueAccent,
                        ),
                        padding: const EdgeInsets.all(10),
                        margin: EdgeInsets.only(right: ScreenSize.width * 0.02),
                        child: Icon(
                          icon,
                          size: ScreenSize.width * 0.06,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: _NumberAttemp(),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.width * 0.02),
          const _BuildCard(),
        ],
      ),
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard();

  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();
    return Expanded(
      child: Wrap(
        children: List.generate(
          memoryGameProvider.cards.length,
          (index) {
            Map<String, dynamic> card = memoryGameProvider.cards[index];
            return CardItem(card: card);
          },
        ),
      ),
    );
  }
}

class _NumberAttemp extends StatelessWidget {
  const _NumberAttemp();

  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();

    return Text(
      'Intentos: ${memoryGameProvider.numberAttemps}',
      style: TextStyle(
        fontSize: ScreenSize.width * 0.05,
        color: Colors.black45,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _LabelByLevel extends StatelessWidget {
  const _LabelByLevel();

  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();

    return Text(
      'Encuentra  ${memoryGameProvider.numberOfCardsToMatchPerLevel} de cada uno de estos íconos',
      style: TextStyle(
        fontSize: ScreenSize.width * 0.05,
        color: Colors.black45,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
