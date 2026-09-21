import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'views/home/main_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GameSetApp());
}

class GameSetApp extends StatelessWidget {
  const GameSetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GameSet',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainView(),
    );
  }
}
