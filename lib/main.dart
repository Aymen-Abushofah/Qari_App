import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/common/firebase_error_screen.dart';
import 'firebase_options.dart';

/// The entry point of the application.
///
/// This file handles:
/// 1. Firebase Initialization
/// 2. Firestore Persistence configuration
/// 3. Root Widget (MaterialApp) setup with Arabic RTL support
void main() async {
  // Ensures Flutter engine is ready before any asynchronous work starts
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Initialize Firebase with platform-specific options (Android/iOS/Web)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Configure Firestore immediately before any other usage
    // We disable persistence on Web to avoid cache size issues,
    // but enable it on Mobile for offline support.
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } else {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    }

    // Launch the main app
    runApp(const QariApp());
  } catch (e) {
    debugPrint('FATAL FIREBASE ERROR: $e');
    // Show a specific error screen if Firebase fails to launch
    runApp(FirebaseErrorScreen(error: e));
  }
}

/// The root widget of the Qari Application.
///
/// This widget uses [ValueListenableBuilder] to listen for theme changes (Light/Dark mode)
/// and applies them globally to the [MaterialApp].
class QariApp extends StatelessWidget {
  const QariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager().themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'قارئ', // App name in Arabic
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,

          // Localization configuration for full RTL (Right-To-Left) support
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', ''), // Arabic (Primary)
            Locale('en', ''), // English (Fallback)
          ],
          locale: const Locale('ar', ''), // Force Arabic locale
          // Start with the animated SplashScreen
          home: const SplashScreen(),
        );
      },
    );
  }
}
