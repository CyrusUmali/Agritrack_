import 'package:dio/dio.dart';
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

  ForgotPasswordProvider(super.context);

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
      } else {
        throw Exception(
            'Failed to send OTP: ${response.data['message'] ?? 'Unknown error'}');
      }
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      showErrorToast(errorMessage, context);
      rethrow;
    } catch (e) {
      showErrorToast(e.toString().replaceAll('Exception: ', ''), context);
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
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      showErrorToast(errorMessage, context);
      rethrow;
    } catch (e) {
      showErrorToast(e.toString().replaceAll('Exception: ', ''), context);
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
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      showErrorToast(errorMessage, context);
      rethrow;
    } catch (e) {
      showErrorToast(e.toString().replaceAll('Exception: ', ''), context);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Extracts a user-friendly error message from DioException
  String _extractErrorMessage(DioException e) {
    // Try to get the message from the response data
    if (e.response?.data != null) {
      final data = e.response!.data;
      
      // Handle your API response format
      if (data is Map<String, dynamic>) {
        // First, try to get the main message
        if (data['message'] != null) {
          return data['message'].toString();
        }
        
        // Then try to get error details
        if (data['error'] != null && data['error'] is Map) {
          final error = data['error'] as Map<String, dynamic>;
          if (error['details'] != null) {
            return error['details'].toString();
          }
        }
      }
    }

    // Fallback to default error messages based on status code
    switch (e.response?.statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 404:
        return 'User not found. Please check your email address.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return e.message ?? 'An unexpected error occurred';
    }
  }

  void showSuccessToast(String message, BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(
        message,
        overflow: TextOverflow.visible,
        maxLines: 3,
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
        overflow: TextOverflow.visible,
        maxLines: 3,
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