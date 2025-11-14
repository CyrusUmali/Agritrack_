// lib/providers/language_provider.dart
import 'package:flareline/services/language_service.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en'); // default to English ('en')
  final GetStorage _storage = GetStorage(); // Create storage instance

  Locale get locale => _locale;
  String get currentLanguageCode => _locale.languageCode;

  // Key for storing the language code in GetStorage
  static const String _languageCodeKey = 'languageCode';

  LanguageProvider() {
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() {
    // GetStorage is synchronous, so no async/await needed
    final languageCode = _storage.read(_languageCodeKey);
    if (languageCode != null &&
        LanguageService.supportedLocales.contains(Locale(languageCode))) {
      _locale = Locale(languageCode);
    }
  }

  void setLocale(Locale locale) {
    if (!LanguageService.supportedLocales.contains(locale)) return;

    _locale = locale;
    // Save to storage synchronously
    _storage.write(_languageCodeKey, locale.languageCode);
    notifyListeners();
  }

  // String translate(String key) {
  //   return LanguageService.t(key, );
  // }


  // lib/providers/language_provider.dart
String translate(String key) {
  return LanguageService.t(key, languageCode: currentLanguageCode);
}
}
