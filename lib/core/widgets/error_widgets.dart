import 'package:flutter/material.dart';
import '../../core/utils/bloc_error_handler.dart';
import '../exceptions/app_exceptions.dart';
import '../constants/app_colors.dart';

/// Standardized error display widget for consistent error UI across the app
class ErrorStateWidget extends StatelessWidget {
  final BaseErrorState error;
  final VoidCallback? onRetry;
  final Widget? customIcon;
  final EdgeInsets? padding;
  final bool showErrorCode;

  const ErrorStateWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.customIcon,
    this.padding,
    this.showErrorCode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildErrorIcon(),
          const SizedBox(height: 16),
          _buildErrorMessage(context),
          if (showErrorCode && error.errorCode != null) ...[
            const SizedBox(height: 8),
            _buildErrorCode(context),
          ],
          if (onRetry != null && error.canRetry) ...[
            const SizedBox(height: 24),
            _buildRetryButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorIcon() {
    if (customIcon != null) return customIcon!;

    IconData iconData;
    Color iconColor;

    switch (error.severity) {
      case ErrorSeverity.warning:
        iconData = Icons.warning_amber;
        iconColor = AppColors.warning;
        break;
      case ErrorSeverity.critical:
        iconData = Icons.error;
        iconColor = AppColors.error;
        break;
      default:
        iconData = Icons.error_outline;
        iconColor = AppColors.errorWithOpacity(0.7);
    }

    return Icon(
      iconData,
      size: 64,
      color: iconColor,
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Text(
      error.message,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorCode(BuildContext context) {
    return Text(
      'Error Code: ${error.errorCode}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('Retry'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
    );
  }
}

/// Compact error widget for inline error display (e.g., in cards)
class InlineErrorWidget extends StatelessWidget {
  final BaseErrorState error;
  final VoidCallback? onRetry;
  final bool showIcon;

  const InlineErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              _getIcon(),
              color: _getIconColor(),
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              error.message,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 14,
              ),
            ),
          ),
          if (onRetry != null && error.canRetry) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (error.severity) {
      case ErrorSeverity.warning:
        return AppColors.warningOverlay();
      case ErrorSeverity.critical:
        return AppColors.errorOverlay();
      default:
        return AppColors.errorOverlay();
    }
  }

  Color _getBorderColor() {
    switch (error.severity) {
      case ErrorSeverity.warning:
        return AppColors.warningWithOpacity(0.3);
      case ErrorSeverity.critical:
        return AppColors.errorWithOpacity(0.3);
      default:
        return AppColors.errorWithOpacity(0.2);
    }
  }

  IconData _getIcon() {
    switch (error.severity) {
      case ErrorSeverity.warning:
        return Icons.warning_amber;
      case ErrorSeverity.critical:
        return Icons.error;
      default:
        return Icons.error_outline;
    }
  }

  Color _getIconColor() {
    switch (error.severity) {
      case ErrorSeverity.warning:
        return AppColors.warning;
      case ErrorSeverity.critical:
        return AppColors.error;
      default:
        return AppColors.errorWithOpacity(0.8);
    }
  }

  Color _getTextColor() {
    switch (error.severity) {
      case ErrorSeverity.warning:
        return AppColors.warning.darker;
      case ErrorSeverity.critical:
        return AppColors.error.darker;
      default:
        return AppColors.error.darker;
    }
  }
}

/// Snackbar helper for showing error messages
class ErrorSnackBar {
  static void show(
    BuildContext context,
    BaseErrorState error, {
    VoidCallback? onRetry,
    Duration? duration,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getIcon(error.severity),
            color: AppColors.textOnPrimary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error.message,
              style: const TextStyle(color: AppColors.textOnPrimary),
            ),
          ),
        ],
      ),
      backgroundColor: _getBackgroundColor(error.severity),
      duration: duration ?? const Duration(seconds: 4),
      action: (onRetry != null && error.canRetry)
          ? SnackBarAction(
              label: 'Retry',
              textColor: AppColors.textOnPrimary,
              onPressed: onRetry,
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static IconData _getIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return Icons.warning_amber;
      case ErrorSeverity.critical:
        return Icons.error;
      default:
        return Icons.error_outline;
    }
  }

  static Color _getBackgroundColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return AppColors.warning;
      case ErrorSeverity.critical:
        return AppColors.error;
      default:
        return AppColors.error;
    }
  }
}

/// Form field with built-in validation error display
class ValidatedTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?) validator;
  final void Function(String)? onChanged;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const ValidatedTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    required this.validator,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        errorMaxLines: 2,
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Loading state widget with error fallback
class LoadingWithErrorFallback extends StatelessWidget {
  final bool isLoading;
  final BaseErrorState? error;
  final Widget child;
  final VoidCallback? onRetry;
  final String? loadingMessage;

  const LoadingWithErrorFallback({
    super.key,
    required this.isLoading,
    this.error,
    required this.child,
    this.onRetry,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            if (loadingMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                loadingMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (error != null) {
      return ErrorStateWidget(
        error: error!,
        onRetry: onRetry,
      );
    }

    return child;
  }
}