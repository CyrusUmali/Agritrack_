import 'package:flareline/pages/users/settings/google_account_card.dart';
import 'package:flareline/pages/users/settings/language_selection_card.dart';
import 'package:flareline/pages/users/settings/user_password.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';
import 'package:provider/provider.dart';
import 'package:flareline/providers/language_provider.dart';

class SettingsPage extends LayoutWidget {
  final Map<String, dynamic> daUser;

  const SettingsPage({super.key, required this.daUser});

  @override
  String breakTabTitle(BuildContext context) {
    return context.translate('Settings');
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return DAProfileDesktop(daUser: daUser);
  }

  @override
  Widget contentMobileWidget(BuildContext context) {
    return DAProfileMobile(daUser: daUser);
  }
}

class DAProfileDesktop extends StatelessWidget {
  final Map<String, dynamic> daUser;

  const DAProfileDesktop({super.key, required this.daUser});

  @override
  Widget build(BuildContext context) {
    final showPasswordCard = daUser['hasPassword'] == true ||
        (daUser['authProvider'] != null && daUser['authProvider'] != 'google');

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showPasswordCard) ...[
                    GoogleAccountCard(user: daUser),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Password card takes 70% of width
                        Expanded(
                          flex: 7,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: PasswordChangeCard(user: daUser),
                          ),
                        ),
                        // Language card takes 30% of width
                        Expanded(
                          flex: 3,
                          child: LanguageSelectionCard(),
                        ),
                      ],
                    ),
                  ] else ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: LanguageSelectionCard(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DAProfileMobile extends StatelessWidget {
  final Map<String, dynamic> daUser;

  const DAProfileMobile({super.key, required this.daUser});

  @override
  Widget build(BuildContext context) {
    final showPasswordCard = daUser['hasPassword'] == true ||
        (daUser['authProvider'] != null && daUser['authProvider'] != 'google');

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                if (showPasswordCard) ...[
                  GoogleAccountCard(user: daUser),
                  PasswordChangeCard(user: daUser, isMobile: true),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                LanguageSelectionCard(isMobile: true),
              ],
            ),
          ),
        );
      },
    );
  }
}
