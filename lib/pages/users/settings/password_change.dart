import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebasePasswordService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Changes the password for the current user
  /// Requires re-authentication with current password first
  Future<PasswordChangeResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return PasswordChangeResult.error('No user is currently signed in');
      }

      // Check if user has email/password provider
      final hasPasswordProvider = user.providerData.any(
        (info) => info.providerId == 'password',
      );

      if (!hasPasswordProvider) {
        return PasswordChangeResult.error(
          'User signed in with OAuth. Cannot change password.',
        );
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return PasswordChangeResult.success();
    } on FirebaseAuthException catch (e) {
      return PasswordChangeResult.error(_getErrorMessage(e));
    } catch (e) {
      debugPrint('Password change error: $e');
      return PasswordChangeResult.error('An unexpected error occurred');
    }
  }

  /// Sets a password for users who signed in with OAuth
  /// (Google, Facebook, etc.) and want to add email/password
  Future<PasswordChangeResult> setPasswordForOAuthUser({
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return PasswordChangeResult.error('No user is currently signed in');
      }

      // Check if user already has password provider
      final hasPasswordProvider = user.providerData.any(
        (info) => info.providerId == 'password',
      );

      if (hasPasswordProvider) {
        return PasswordChangeResult.error(
          'User already has a password. Use changePassword instead.',
        );
      }

      // Link email/password credential
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: newPassword,
      );

      await user.linkWithCredential(credential);

      return PasswordChangeResult.success();
    } on FirebaseAuthException catch (e) {
      return PasswordChangeResult.error(_getErrorMessage(e));
    } catch (e) {
      debugPrint('Set password error: $e');
      return PasswordChangeResult.error('An unexpected error occurred');
    }
  }

  /// Check if current user has password authentication
  bool hasPasswordAuth() {
    final user = _auth.currentUser;
    if (user == null) return false;

    return user.providerData.any((info) => info.providerId == 'password');
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Current password is incorrect';
      case 'weak-password':
        return 'New password is too weak';
      case 'requires-recent-login':
        return 'Please sign in again to change your password';
      case 'user-not-found':
        return 'User not found';
      case 'provider-already-linked':
        return 'Email/password authentication already exists';
      case 'credential-already-in-use':
        return 'This email is already in use';
      case 'email-already-in-use':
        return 'This email is already in use';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}

/// Result class for password change operations
class PasswordChangeResult {
  final bool isSuccess;
  final String? errorMessage;

  PasswordChangeResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  factory PasswordChangeResult.success() {
    return PasswordChangeResult._(isSuccess: true);
  }

  factory PasswordChangeResult.error(String message) {
    return PasswordChangeResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}
