import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/firebase_status.dart';
import 'core/theme/app_theme.dart';
import 'views/home/splash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      const String apiKey = String.fromEnvironment(
        'FIREBASE_API_KEY',
        defaultValue: 'AIzaSyC3sfkQgnFmGX_okbN45DJR8GvvfaWCLDA',
      );
      const String appId = String.fromEnvironment('FIREBASE_APP_ID');
      const String messagingSenderId = String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: '7237385895',
      );
      const String projectId = String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: 'gameset-c135b',
      );
      if (appId.isEmpty) {
        throw StateError(
          'Register a Web app in Firebase project gameset-c135b and run Chrome '
          'with --dart-define=FIREBASE_APP_ID=<web app ID>.',
        );
      }
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          authDomain: const String.fromEnvironment(
            'FIREBASE_AUTH_DOMAIN',
            defaultValue: 'gameset-c135b.firebaseapp.com',
          ),
          storageBucket: const String.fromEnvironment(
            'FIREBASE_STORAGE_BUCKET',
            defaultValue: 'gameset-c135b.firebasestorage.app',
          ),
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (error) {
    FirebaseStatus.initializationError = error.toString();
    debugPrint('Firebase initialization failed: $error');
  }
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
      home: const SplashView(),
    );
  }
}
