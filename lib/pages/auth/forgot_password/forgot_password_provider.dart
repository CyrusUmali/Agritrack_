import 'package:flareline/services/api_service.dart';
import 'package:flareline_uikit/core/mvvm/base_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class ForgotPasswordProvider extends BaseViewModel {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool otpSent = false;
  bool otpVerified = false;
  String? resetToken;

  ForgotPasswordProvider(BuildContext context) : super(context);

  Future<void> sendResetOTP(BuildContext context) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      if (emailController.text.isEmpty) {
        throw Exception('Email is required');
      }

      isLoading = true;
      notifyListeners();

      final response = await apiService.post(
        '/auth/forgot-password',
        data: {'email': emailController.text.trim()},
      );

      if (response.statusCode == 200) {
        otpSent = true;
        showSuccessToast('OTP sent to ${emailController.text}', context);
        print('emailController.text');
        print(emailController.text);
      } else {
        throw Exception(
            'Failed to send OTP: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      showErrorToast(e.toString(), context);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOTP(BuildContext context) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      if (otpController.text.isEmpty) {
        throw Exception('OTP is required');
      }

      isLoading = true;
      notifyListeners();

      final response = await apiService.post(
        '/auth/verify-reset-otp',
        data: {
          'email': emailController.text.trim(),
          'otp': otpController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        otpVerified = true;
        resetToken = response.data['data']['resetToken'];
        showSuccessToast('OTP verified successfully', context);
      } else {
        throw Exception(
            'Failed to verify OTP: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      showErrorToast(e.toString(), context);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(BuildContext context) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      if (newPasswordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        throw Exception('Password fields cannot be empty');
      }

      if (newPasswordController.text != confirmPasswordController.text) {
        throw Exception('Passwords do not match');
      }

      if (newPasswordController.text.length < 8) {
        throw Exception('Password must be at least 8 characters');
      }

      isLoading = true;
      notifyListeners();

      final response = await apiService.post(
        '/auth/reset-password',
        data: {
          'email': emailController.text.trim(),
          'otp': otpController.text.trim(),
          'newPassword': newPasswordController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        showSuccessToast('Password reset successfully', context);
        // Navigator.of(context).pop();
      } else {
        throw Exception(
            'Failed to reset password: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      showErrorToast(e.toString(), context);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void showSuccessToast(String message, BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(
        message,
        overflow: TextOverflow.visible, // Prevent ellipsis
        maxLines: 3, // Allow multiple lines
      ),
      autoCloseDuration: const Duration(seconds: 5),
    );
  }

  void showErrorToast(String message, BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: Text(
        message,
        overflow: TextOverflow.visible, // Prevent ellipsis
        maxLines: 3, // Allow multiple lines
      ),
      autoCloseDuration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
