// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:memory_game/ui/providers/memory_game_provider.dart';
import 'package:provider/provider.dart';

import '../../config/helpers/custom_dialog.dart';
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
    double deviceHeight = MediaQuery.of(context).size.height;
    double height = deviceHeight;
    double width = MediaQuery.of(context).size.width;
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();
    if (memoryGameProvider.isFirstEntry) {
      memoryGameProvider.cards.shuffle();
      memoryGameProvider.isFirstEntry = false;
    }

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
              fontSize: width * 0.07,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () async {
                LoadingDialog.show('Reiniciando juego', context, width);
                await memoryGameProvider.resetGame(false);
                LoadingDialog.hide(context);
              },
              child: Padding(
                padding: EdgeInsets.only(right: width * 0.03),
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
          width: width,
          padding: EdgeInsets.symmetric(horizontal: width * 0.03),
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
              SizedBox(height: width * 0.25),
              _NumberAttemp(width: width),
              SizedBox(height: width * 0.1),
              _buildCards(width, memoryGameProvider, height),
              SizedBox(height: width * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _buildCards(
      double width, MemoryGameProvider memoryGameProvider, double height) {
    return Expanded(
      child: Wrap(
        spacing: width * 0.03,
        runSpacing: width * 0.03,
        children: List.generate(
          memoryGameProvider.cards.length,
          (index) {
            Map<String, dynamic> card = memoryGameProvider.cards[index];
            return _CardItem(
              height: height,
              card: card,
            );
          },
        ),
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  const _CardItem({required this.height, required this.card});

  final double height;
  final Map<String, dynamic> card;
  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();

    return GestureDetector(
      onTap: card['is_selected'] || memoryGameProvider.showingCardsNumber == 2
          ? null
          : () => memoryGameProvider.showCard(card['value']),
      child: Container(
        height: height * 0.11,
        width: height * 0.11,
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
  const _NumberAttemp({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    MemoryGameProvider memoryGameProvider = context.watch<MemoryGameProvider>();

    return RichText(
      text: TextSpan(
        text: 'Número de intentos: ',
        style: TextStyle(fontSize: width * 0.05, color: Colors.black),
        children: [
          TextSpan(
            text: '${memoryGameProvider.numberAttemps}',
            style: TextStyle(
              fontSize: width * 0.05,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}
