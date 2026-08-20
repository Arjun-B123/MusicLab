import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'theme_mode_override';

/// Follows the system light/dark setting by default, with a manual
/// light/dark override persisted across launches — per the design
/// handoff's "following system setting, with manual override in Profile".
class ThemeModeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == 'light') {
      _mode = ThemeMode.light;
    } else if (stored == 'dark') {
      _mode = ThemeMode.dark;
    }
    notifyListeners();
  }

  /// Toggles between explicit light and dark, overriding system. Starting
  /// point when currently following the system is the opposite of whatever
  /// is currently displayed, i.e. the toggle always flips what's on screen.
  Future<void> toggle(Brightness currentlyDisplayed) async {
    _mode = currentlyDisplayed == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
