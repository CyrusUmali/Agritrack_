// Create a new file: lib/extensions/context_extensions.dart
import 'package:flutter/material.dart';
import 'package:flareline/providers/language_provider.dart';
import 'package:provider/provider.dart';

extension LanguageExtension on BuildContext {
  String translate(String key) {
    final languageProvider = read<LanguageProvider>();
    return languageProvider.translate(key);
  }
}