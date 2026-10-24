import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/firebase_status.dart';
import 'core/theme/app_theme.dart';
import 'services/app_update_service.dart';
import 'services/notification_service.dart';
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
  try {
    await NotificationService().initialize();
  } catch (error) {
    debugPrint('Notification init failed: $error');
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    // Fire and forget: publishing the installed build keeps the admin app
    // aware of what users actually run, without delaying startup.
    unawaited(
      AppUpdateService().reportInstalledBuild().catchError((Object error) {
        debugPrint('Installed build report failed: $error');
        return null;
      }),
    );
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
      home: FirebaseStatus.initializationError == null
          ? const SplashView()
          : FirebaseSetupError(message: FirebaseStatus.initializationError!),
    );
  }
}

class FirebaseSetupError extends StatelessWidget {
  const FirebaseSetupError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            'Firebase could not start. Check the platform setup and restart.\n\n'
            '$message',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
