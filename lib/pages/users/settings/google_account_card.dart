import 'dart:async';

import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/users/settings/sync_service.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flareline/services/api_service.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleAccountCard extends StatefulWidget {
  final Map<String, dynamic> user;

  const GoogleAccountCard({super.key, required this.user});

  @override
  State<GoogleAccountCard> createState() => _GoogleAccountCardState();
}

class _GoogleAccountCardState extends State<GoogleAccountCard> {
  bool _isLoading = false;

  Future<void> _migrateToGoogle(BuildContext context) async {
    try {
      setState(() => _isLoading = true);

      final apiService = Provider.of<ApiService>(context, listen: false);
      final googleUserData = await SyncService.getGoogleUserIsolated();

      if (googleUserData == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await apiService.post(
        '/auth/migrate-to-google',
        data: {'accessToken': googleUserData['accessToken']},
      ).timeout(const Duration(seconds: 30));

      if (response.data['success'] == false) {
        final errorMessage = response.data['message'] ?? 'Migration failed';
        throw Exception(errorMessage);
      }

      // Success handling
      await FirebaseAuth.instance.signOut();

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.clearUser();

      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Success'),
        description:
            const Text('Successfully migrated to Google authentication'),
        autoCloseDuration: const Duration(seconds: 5),
      );

      // Navigate to sign-in screen and clear all routes
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/signIn',
          (Route<dynamic> route) => false,
        );
      }
    } on TimeoutException {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Error'),
        description: const Text('Request timed out. Please try again.'),
        autoCloseDuration: const Duration(seconds: 5),
      );
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        print('Migration error: $e. Error message: $errorMessage');
      }

      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(
          errorMessage,
          overflow: TextOverflow.visible,
          maxLines: 3,
        ),
        autoCloseDuration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.user['authProvider'] == 'google';
    final email = widget.user['email'] ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (isConnected)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connected as $email',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can sign in with Google to this account',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.translate('MTG-text'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ButtonWidget(
                color: isConnected
                    ? Theme.of(context).cardTheme.color
                    : Theme.of(context).cardTheme.color,
                borderColor: Theme.of(context).cardTheme.surfaceTintColor,
                iconWidget: SvgPicture.asset(
                  'assets/brand/brand-01.svg',
                  width: 25,
                  height: 25,
                ),
                btnText: isConnected
                    ? context.translate('Disconnect Google')
                    : context.translate('Migrate to Google'),
                textColor: isConnected ? Colors.red : null,
                onTap: _isLoading
                    ? null
                    : () {
                        if (isConnected) {
                          // Handle disconnect if needed
                        } else {
                          _migrateToGoogle(context);
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
