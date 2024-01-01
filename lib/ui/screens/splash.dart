import 'package:flutter/material.dart';
import 'package:memory_game/config/services/navigation_service.dart';
import 'package:memory_game/ui/screens/home_screen.dart';
import 'package:provider/provider.dart';

import '../../config/helpers/helpers.dart';
import '../providers/memory_game_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isScreenLoaded = false;

  @override
  void didChangeDependencies() async {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    MemoryGameProvider memoryGameProvider = context.read<MemoryGameProvider>();
    memoryGameProvider.loadCardsToShow(2);
    Future.delayed(
      const Duration(seconds: 3),
      () => NavigationServices.replaceTo(screen: const HomeScreen()),
    );
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init();
    return Scaffold(
      body: Container(
        width: ScreenSize.width,
        height: ScreenSize.height,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.fill,
            opacity: 0.1,
          ),
        ),
        child: Text(
          'Memory Game',
          style: TextStyle(
            fontSize: ScreenSize.width * 0.1,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }
}
