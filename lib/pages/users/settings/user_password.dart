import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/pages/users/settings/password_change.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:provider/provider.dart';

import 'package:flareline_uikit/components/modal/modal_dialog.dart';

class PasswordChangeCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isMobile;

  const PasswordChangeCard(
      {super.key, required this.user, this.isMobile = false});

  @override
  State<PasswordChangeCard> createState() => _PasswordChangeCardState();
}

class _PasswordChangeCardState extends State<PasswordChangeCard> {
  final _formKey = GlobalKey<FormState>();
  final _passwordService = FirebasePasswordService();

  late TextEditingController _passwordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
      _generalError = null;
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Validate and set field-specific errors
  bool _validateFields() {
    bool isValid = true;
    final hasPassword = widget.user['hasPassword'] == true;

    // Clear previous errors
    _clearErrors();

    // Validate current password (if user has password)
    if (hasPassword && _passwordController.text.isEmpty) {
      setState(() {
        _currentPasswordError = 'Current password is required';
      });
      isValid = false;
    }

    // Validate new password
    if (_newPasswordController.text.isEmpty) {
      setState(() {
        _newPasswordError = 'New password is required';
      });
      isValid = false;
    } else if (_newPasswordController.text.length < 6) {
      setState(() {
        _newPasswordError = 'Password must be at least 6 characters';
      });
      isValid = false;
    }

    // Validate confirm password
    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _confirmPasswordError = 'Please confirm your password';
      });
      isValid = false;
    } else if (_confirmPasswordController.text != _newPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _saveChanges() async {
    // Validate fields first
    if (!_validateFields()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hasPassword = widget.user['hasPassword'] == true;
      PasswordChangeResult result;

      if (hasPassword) {
        // User has existing password - change it
        result = await _passwordService.changePassword(
          currentPassword: _passwordController.text,
          newPassword: _newPasswordController.text,
        );
      } else {
        // OAuth user setting password for first time
        result = await _passwordService.setPasswordForOAuthUser(
          newPassword: _newPasswordController.text,
        );
      }

      if (!mounted) return;

      if (result.isSuccess) {
        // Show success dialog before signing out
        await ModalDialog.show(
          context: context,
          title: context.translate('Success'),
          showTitle: true,
          showTitleDivider: true,
          modalType: ModalType.medium,
          onCancelTap: () => Navigator.of(context).pop(),
          onSaveTap: () {
            Navigator.of(context).pop();
          },
          child: Center(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.translate(
                      'Password changed successfully. You will be signed out and need to sign in again with your new password.',
                    ),
                  ),
                ),
              ],
            ),
          ),
          footer: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    child: ButtonWidget(
                      btnText: context.translate('OK'),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      type: ButtonType.primary.type,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (!mounted) return;

        // Sign out and redirect to login
        Provider.of<UserProvider>(context, listen: false).signOut();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      } else {
        // Handle specific errors with field-level or dialog display
        _handlePasswordChangeError(
            result.errorMessage ?? 'Failed to change password');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generalError = 'An unexpected error occurred. Please try again.';
        });
        ToastHelper.showErrorToast(_generalError!, context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handlePasswordChangeError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    // Map errors to specific fields or show general error
    if (lowerError.contains('current password') ||
        lowerError.contains('wrong-password') ||
        lowerError.contains('incorrect')) {
      setState(() {
        _currentPasswordError = errorMessage;
      });
      ToastHelper.showErrorToast(errorMessage, context);
    } else if (lowerError.contains('weak') ||
        lowerError.contains('too short') ||
        lowerError.contains('6 characters')) {
      setState(() {
        _newPasswordError = errorMessage;
      });
      ToastHelper.showErrorToast(errorMessage, context);
    } else if (lowerError.contains('recent login') ||
        lowerError.contains('sign in again')) {
      _showErrorDialog(
        context.translate('Session Expired'),
        context.translate(
            'For security reasons, please sign out and sign in again before changing your password.'),
      );
    } else if (lowerError.contains('already in use') ||
        lowerError.contains('already linked')) {
      _showErrorDialog(
        context.translate('Error'),
        errorMessage,
      );
    } else {
      // General error
      setState(() {
        _generalError = errorMessage;
      });
      _showErrorDialog(
        context.translate('Password Change Failed'),
        errorMessage,
      );
    }
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required Widget value,
    IconData? icon,
    String? errorText,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasError = errorText != null;

    // Use explicit red color for errors
    final errorColor = Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color:
                      hasError ? errorColor : colors.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      hasError ? errorColor : colors.onSurface.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasError
                    ? errorColor
                    : Theme.of(context).cardTheme.surfaceTintColor!,
                width: hasError ? 2.0 : 1.0,
              ),
            ),
            child: value,
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: errorColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    String? errorText,
  }) {
    return _buildInfoRow(
      context,
      label: label,
      icon: icon,
      errorText: errorText,
      value: TextField(
        controller: controller,
        obscureText: true,
        enabled: !_isLoading,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
        onChanged: (_) {
          // Clear field-specific error when user types
          if (errorText != null) {
            setState(() {
              if (controller == _passwordController) {
                _currentPasswordError = null;
              } else if (controller == _newPasswordController) {
                _newPasswordError = null;
              } else if (controller == _confirmPasswordController) {
                _confirmPasswordError = null;
              }
              _generalError = null;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPassword = widget.user['hasPassword'] == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline),
                const SizedBox(width: 12),
                Text(
                  context.translate(
                      hasPassword ? 'Change Password' : 'Set Password'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (_generalError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.shade400,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _generalError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          size: 18, color: Colors.red.shade400),
                      onPressed: () => setState(() => _generalError = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (hasPassword)
              _buildPasswordField(
                label: context.translate('Current Password'),
                controller: _passwordController,
                icon: Icons.lock_outline,
                errorText: _currentPasswordError,
              ),
            _buildPasswordField(
              label: context.translate('New Password'),
              controller: _newPasswordController,
              icon: Icons.lock_reset_outlined,
              errorText: _newPasswordError,
            ),
            _buildPasswordField(
              label: context.translate('Confirm New Password'),
              controller: _confirmPasswordController,
              icon: Icons.lock_reset_outlined,
              errorText: _confirmPasswordError,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        context.translate(
                          hasPassword ? 'Change Password' : 'Set Password',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
