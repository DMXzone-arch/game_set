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
      const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
      const String appId = String.fromEnvironment('FIREBASE_APP_ID');
      const String messagingSenderId = String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      );
      const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
      const String authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
      const String storageBucket = String.fromEnvironment(
        'FIREBASE_STORAGE_BUCKET',
      );
      if ([
        apiKey,
        appId,
        messagingSenderId,
        projectId,
        authDomain,
        storageBucket,
      ].any((value) => value.isEmpty)) {
        throw StateError(
          'Set all Firebase Web values in .env and run with '
          '--dart-define-from-file=.env.',
        );
      }
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          authDomain: authDomain,
          storageBucket: storageBucket,
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
