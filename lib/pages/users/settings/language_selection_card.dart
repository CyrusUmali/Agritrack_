import 'package:flareline/services/language_service.dart';
import 'package:flareline/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LanguageSelectionCard extends StatelessWidget {
  final bool isMobile;

  const LanguageSelectionCard({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language_outlined),
                const SizedBox(width: 12),
                Consumer<LanguageProvider>(
                  builder: (context, languageProvider, child) {
                    return Text(
                      languageProvider
                          .translate('language'), // Simple translation
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Locale>(
              value: languageProvider.locale,
              dropdownColor: Theme.of(context).cardTheme.color,
              items: LanguageService.supportedLocales.map((locale) {
                return DropdownMenuItem(
                  value: locale,
                  child: Text(
                      locale.languageCode == 'en' ? 'English' : 'Filipino'),
                );
              }).toList(),
              onChanged: (Locale? value) {
                if (value != null) {
                  languageProvider.setLocale(value);
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).cardTheme.surfaceTintColor ??
                        Colors.grey, // Use surfaceTintColor
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).cardTheme.surfaceTintColor ??
                        Colors.grey, // Use surfaceTintColor
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).cardTheme.surfaceTintColor ??
                        Colors.blue, // Use surfaceTintColor
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
