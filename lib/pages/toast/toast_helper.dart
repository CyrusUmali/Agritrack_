import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastHelper {
  static String? _lastMessage;
  static DateTime? _lastToastTime;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  static void showToast({
    required BuildContext context,
    required String message,
    required ToastificationType type,
    Duration duration = const Duration(seconds: 5),
    int maxLines = 3, // Add maxLines parameter with default value
  }) {
    final now = DateTime.now();
    
    // Prevent duplicate toasts within the debounce period
    if (_lastMessage == message && 
        _lastToastTime != null && 
        now.difference(_lastToastTime!) < _debounceDuration) {
      return;
    }

    _lastMessage = message;
    _lastToastTime = now;

    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      title: Text(
        message,
        overflow: TextOverflow.ellipsis, // Changed to ellipsis for better UX
        maxLines: maxLines, // Use the parameter here
      ),
      autoCloseDuration: duration,
    );
  }

  static void showSuccessToast(String message, BuildContext context, {int maxLines = 3}) {
    showToast(
      context: context,
      message: message,
      type: ToastificationType.success,
      maxLines: maxLines, // Pass the parameter
    );
  }

  static void showErrorToast(String message, BuildContext context, {int maxLines = 3}) {
    showToast(
      context: context,
      message: message,
      type: ToastificationType.error,
      maxLines: maxLines, // Pass the parameter
    );
  }

  static void showInfoToast(String message, BuildContext context, {int maxLines = 3}) {
    showToast(
      context: context,
      message: message,
      type: ToastificationType.info,
      maxLines: maxLines, // Pass the parameter
    );
  }

  static void showWarningToast(String message, BuildContext context, {int maxLines = 3}) {
    showToast(
      context: context,
      message: message,
      type: ToastificationType.warning,
      maxLines: maxLines, // Pass the parameter
    );
  }
}