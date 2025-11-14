import 'package:flutter/material.dart';

class NetworkErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final IconData? errorIcon;
  final Color? errorColor;
  final double? iconSize;
  final double? fontSize;
  final String? retryButtonText;
  final EdgeInsetsGeometry? padding;

  const NetworkErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.errorIcon,
    this.errorColor,
    this.iconSize,
    this.fontSize,
    this.retryButtonText,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the error message based on the error type
    final errorMessage = _getErrorMessage(error);

    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              errorIcon ?? Icons.error_outline,
              color: errorColor ?? Colors.red,
              size: iconSize ?? 48,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: errorColor ?? Colors.red,
                  fontSize: fontSize ?? 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(retryButtonText ?? 'Retry'),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                backgroundColor: Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(String error) {
    if (error.contains('timeout') || error.contains('network')) {
      return 'Connection failed. Please check your internet connection.';
    } else if (error.contains('server')) {
      return 'Server error. Please try again later.';
    } else {
      return 'Failed to load data: ${error.replaceAll(RegExp(r'^Exception: '), '')}';
    }
  }
}
