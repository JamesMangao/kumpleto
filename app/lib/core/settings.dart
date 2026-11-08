import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys persisted in SharedPreferences.
abstract final class PrefsKeys {
  static const String firstRunDone = 'first_run_done';
  static const String language = 'language'; // 'system' | 'en' | 'fil'
  static const String themeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const String lastDataCheck = 'last_data_check'; // ms since epoch
  static const String lastDataETag = 'last_data_etag';
  static const String isFirstTimeJobseeker = 'is_first_time_jobseeker';
  static const String remindersEnabled = 'reminders_enabled';
}

/// App-level user settings. Also acts as a [ChangeNotifier] so the router
/// can refresh when the first-run acknowledgement flips.
class AppSettings extends ChangeNotifier {
  AppSettings._({
    required this.firstRunDone,
    required this.language,
    required this.themeModeIndex,
    required this.isFirstTimeJobseeker,
    required this.remindersEnabled,
  });

  /// Loads persisted settings (safe on first launch: all defaults).
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(
      firstRunDone: prefs.getBool(PrefsKeys.firstRunDone) ?? false,
      language: prefs.getString(PrefsKeys.language) ?? 'system',
      themeModeIndex: prefs.getInt(PrefsKeys.themeMode) ?? 0,
      isFirstTimeJobseeker:
          prefs.getBool(PrefsKeys.isFirstTimeJobseeker) ?? false,
      remindersEnabled: prefs.getBool(PrefsKeys.remindersEnabled) ?? false,
    );
  }

  bool firstRunDone;
  String language;
  int themeModeIndex;
  bool isFirstTimeJobseeker;

  /// Expiry reminders are opt-in: turning the switch on is what asks the OS
  /// for the notification permission.
  bool remindersEnabled;

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

  Future<void> resetFirstRun() async {
    firstRunDone = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.firstRunDone, false);
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

  Future<void> setFirstTimeJobseeker(bool value) async {
    isFirstTimeJobseeker = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isFirstTimeJobseeker, value);
  }

  Future<void> setRemindersEnabled(bool value) async {
    remindersEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.remindersEnabled, value);
  }
}
