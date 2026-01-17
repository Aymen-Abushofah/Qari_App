import 'package:flutter/material.dart';

/// ThemeManager: A specialized singleton class that manages the application's visual theme state.
///
/// It provides:
/// 1. A [ValueNotifier] to broadcast theme changes (Light/Dark) across the app without a full rebuild.
/// 2. Simple toggle logic for switching themes.
/// 3. Persistence of the singleton instance to ensure consistency.
class ThemeManager {
  // --- Singleton Pattern implementation ---
  // Ensures only one instance of ThemeManager exists during the app lifecycle.
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  /// Holds the current [ThemeMode]. UI widgets can listen to this notifier.
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.light,
  );

  /// Toggles the application between Light and Dark modes.
  /// Called usually from a Switch widget in the Settings screen.
  void toggleTheme(bool isDark) {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Helper getter to quickly check if the app is currently in Dark Mode.
  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;
}
