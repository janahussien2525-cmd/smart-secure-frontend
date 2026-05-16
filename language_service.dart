import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active locale and notifies listeners when it changes.
/// Call [init] once on app start, then use [setLanguage] to change.
class LanguageService {
  static final ValueNotifier<Locale> notifier = ValueNotifier(const Locale('en'));

  static String get current => notifier.value.languageCode;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code  = prefs.getString('app_language') ?? 'en';
    notifier.value = Locale(code);
  }

  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
    notifier.value = Locale(code);
  }
}
