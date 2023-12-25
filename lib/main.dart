import 'package:flutter/material.dart';
import 'package:memory_game/config/helpers/helpers.dart';
import 'package:memory_game/ui/providers/memory_game_provider.dart';
import 'package:memory_game/ui/screens/splash.dart';
import 'package:provider/provider.dart';

import 'config/themes/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MemoryGameProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    ScreenSize.init();
    return SafeArea(
      child: MaterialApp(
        title: 'Memory Game',
        home: const SplashScreen(),
        navigatorKey: CurrentContext.navigationKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme().getTheme(),
      ),
    );
  }
}
