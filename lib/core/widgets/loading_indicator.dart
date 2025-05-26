import 'package:flutter/material.dart';

/// A widget that displays a loading indicator with customizable properties
class LoadingIndicator extends StatelessWidget {
  /// Creates a [LoadingIndicator] with customizable properties
  const LoadingIndicator({
    super.key,
    this.color,
    this.size = 24.0,
    this.strokeWidth = 4.0,
    this.value,
    this.backgroundColor,
  });

  /// The color of the loading indicator
  final Color? color;
  
  /// The size of the loading indicator
  final double size;
  
  /// The width of the loading indicator's stroke
  final double strokeWidth;
  
  /// The value of the loading indicator, between 0.0 and 1.0
  /// If null, an indeterminate progress indicator is shown
  final double? value;
  
  /// The background color of the loading indicator
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color ?? theme.colorScheme.primary),
        value: value,
        strokeWidth: strokeWidth,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

/// A widget that displays a loading indicator with text
class LoadingIndicatorWithText extends StatelessWidget {
  /// Creates a [LoadingIndicatorWithText] with customizable properties
  const LoadingIndicatorWithText({
    super.key,
    this.text = 'Loading...',
    this.textStyle,
    this.color,
    this.size = 24.0,
    this.strokeWidth = 4.0,
    this.value,
    this.backgroundColor,
    this.spacing = 16.0,
  });

  /// The text to display next to the loading indicator
  final String text;
  
  /// The style of the text
  final TextStyle? textStyle;
  
  /// The color of the loading indicator
  final Color? color;
  
  /// The size of the loading indicator
  final double size;
  
  /// The width of the loading indicator's stroke
  final double strokeWidth;
  
  /// The value of the loading indicator, between 0.0 and 1.0
  /// If null, an indeterminate progress indicator is shown
  final double? value;
  
  /// The background color of the loading indicator
  final Color? backgroundColor;
  
  /// The spacing between the loading indicator and the text
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoadingIndicator(
          color: color,
          size: size,
          strokeWidth: strokeWidth,
          value: value,
          backgroundColor: backgroundColor,
        ),
        SizedBox(width: spacing),
        Text(
          text,
          style: textStyle ?? theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// A widget that displays a loading indicator in the center of the screen
class FullScreenLoadingIndicator extends StatelessWidget {
  /// Creates a [FullScreenLoadingIndicator] with customizable properties
  const FullScreenLoadingIndicator({
    super.key,
    this.color,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.backgroundColor,
    this.text,
    this.textStyle,
  });

  /// The color of the loading indicator
  final Color? color;
  
  /// The size of the loading indicator
  final double size;
  
  /// The width of the loading indicator's stroke
  final double strokeWidth;
  
  /// The background color of the loading indicator
  final Color? backgroundColor;
  
  /// Optional text to display below the loading indicator
  final String? text;
  
  /// The style of the text
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: Colors.black.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingIndicator(
            color: color,
            size: size,
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor,
          ),
          if (text != null) ...[
            const SizedBox(height: 16.0),
            Text(
              text!,
              style: textStyle ?? theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}