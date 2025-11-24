import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._internal();
  AppSettings._internal();

  static const _keyThemeMode = 'theme_mode'; // 'light' | 'dark' | 'system'
  static const _keyLanguage = 'language'; // 'en' | 'ms'

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_keyThemeMode);
    final lang = prefs.getString(_keyLanguage);

    if (themeStr != null) {
      switch (themeStr) {
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        default:
          _themeMode = ThemeMode.light;
      }
    }

    if (lang == 'ms' || lang == 'en') {
      _locale = Locale(lang!);
    }
    notifyListeners();
  }

  Future<void> setDarkMode(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, dark ? 'dark' : 'light');
  }

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'ms') return;
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, code);
  }
}
