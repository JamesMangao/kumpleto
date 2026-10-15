import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys persisted in SharedPreferences.
abstract final class PrefsKeys {
  static const String firstRunDone = 'first_run_done';
  static const String language = 'language'; // 'system' | 'en' | 'fil'
  static const String themeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const String lastDataCheck = 'last_data_check'; // ms since epoch
  static const String lastDataETag = 'last_data_etag';
}

/// App-level user settings. Also acts as a [ChangeNotifier] so the router
/// can refresh when the first-run acknowledgement flips.
class AppSettings extends ChangeNotifier {
  AppSettings._({
    required this.firstRunDone,
    required this.language,
    required this.themeModeIndex,
  });

  /// Loads persisted settings (safe on first launch: all defaults).
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(
      firstRunDone: prefs.getBool(PrefsKeys.firstRunDone) ?? false,
      language: prefs.getString(PrefsKeys.language) ?? 'system',
      themeModeIndex: prefs.getInt(PrefsKeys.themeMode) ?? 0,
    );
  }

  bool firstRunDone;
  String language;
  int themeModeIndex;

  /// Locale for MaterialApp: null = follow system.
  Locale? get locale => switch (language) {
    'en' => const Locale('en'),
    'fil' => const Locale('fil'),
    _ => null,
  };

  ThemeMode get themeMode => ThemeMode.values[themeModeIndex];

  Future<void> setFirstRunDone() async {
    firstRunDone = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.firstRunDone, true);
  }

  Future<void> setLanguage(String value) async {
    language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.language, value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeIndex = mode.index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefsKeys.themeMode, mode.index);
  }
}
