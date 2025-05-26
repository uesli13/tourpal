import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// String Extensions
extension StringExtensions on String {
  /// Capitalizes the first letter of the string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts a string to title case (capitalizes each word)
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Truncates the string to the specified length with an ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Checks if the string is a valid email
  bool get isValidEmail {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(this);
  }

  /// Checks if the string is a valid URL
  bool get isValidUrl {
    final urlRegExp = RegExp(
        r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$');
    return urlRegExp.hasMatch(this);
  }

  /// Returns the file extension of a path
  String get fileExtension {
    return contains('.') ? split('.').last : '';
  }

  /// Checks if the string represents an image file
  bool get isImageFile {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'wbmp'];
    final ext = fileExtension.toLowerCase();
    return imageExtensions.contains(ext);
  }

  /// Checks if the string represents an audio file
  bool get isAudioFile {
    final audioExtensions = ['mp3', 'wav', 'ogg', 'aac', 'm4a'];
    final ext = fileExtension.toLowerCase();
    return audioExtensions.contains(ext);
  }
}

/// DateTime Extensions
extension DateTimeExtensions on DateTime {
  /// Returns a formatted date string (e.g., "May 24, 2025")
  String toFormattedDate() {
    return DateFormat('MMMM d, y').format(this);
  }

  /// Returns a formatted date and time string (e.g., "May 24, 2025 3:30 PM")
  String toFormattedDateTime() {
    return DateFormat('MMMM d, y h:mm a').format(this);
  }

  /// Returns a relative time string (e.g., "2 hours ago", "5 days ago")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Returns a short formatted date (e.g., "24/05/2025")
  String toShortDate() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// Returns a short formatted time (e.g., "15:30")
  String toShortTime() {
    return DateFormat('HH:mm').format(this);
  }

  /// Returns a day of week (e.g., "Monday", "Tuesday")
  String toDayOfWeek() {
    return DateFormat('EEEE').format(this);
  }

  /// Checks if the date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Checks if the date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
}

/// BuildContext Extensions
extension BuildContextExtensions on BuildContext {
  /// Gets the current theme
  ThemeData get theme => Theme.of(this);

  /// Gets the current text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Gets the current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Gets the screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Gets the screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Gets the screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Checks if the device is in dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Shows a snackbar with the given message
  void showSnackBar(String message, {Duration? duration, Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Shows a success snackbar
  void showSuccessSnackBar(String message, {Duration? duration}) {
    showSnackBar(
      message,
      backgroundColor: Colors.green,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shows an error snackbar
  void showErrorSnackBar(String message, {Duration? duration}) {
    showSnackBar(
      message,
      backgroundColor: Colors.red,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Navigates to a named route
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replaces the current route with a named route
  Future<T?> replaceWith<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushReplacementNamed<T, dynamic>(
      routeName,
      arguments: arguments,
    );
  }

  /// Goes back to the previous route
  void goBack<T>([T? result]) {
    return Navigator.of(this).pop<T>(result);
  }
}

/// File Extensions
extension FileExtensions on File {
  /// Gets the file name from a file
  String get fileName {
    return path.split('/').last;
  }

  /// Gets the file extension from a file
  String get fileExtension {
    return path.contains('.') ? path.split('.').last : '';
  }

  /// Checks if the file is an image
  bool get isImage {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'wbmp'];
    final ext = fileExtension.toLowerCase();
    return imageExtensions.contains(ext);
  }

  /// Checks if the file is an audio
  bool get isAudio {
    final audioExtensions = ['mp3', 'wav', 'ogg', 'aac', 'm4a'];
    final ext = fileExtension.toLowerCase();
    return audioExtensions.contains(ext);
  }

  /// Gets the file size in MB
  Future<double> get fileSizeInMB async {
    final bytes = await length();
    return bytes / (1024 * 1024);
  }
}

/// List Extensions
extension ListExtensions<T> on List<T> {
  /// Returns a new list with duplicates removed
  List<T> get removeDuplicates => toSet().toList();

  /// Returns a random element from the list
  T get randomElement => this[DateTime.now().millisecondsSinceEpoch % length];

  /// Splits the list into chunks of the specified size
  List<List<T>> chunked(int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += chunkSize) {
      chunks.add(sublist(i, i + chunkSize > length ? length : i + chunkSize));
    }
    return chunks;
  }

  /// Checks if the list contains all elements from another list
  bool containsAll(List<T> elements) {
    return elements.every((element) => contains(element));
  }

  /// Checks if the list contains any element from another list
  bool containsAny(List<T> elements) {
    return elements.any((element) => contains(element));
  }

  /// Returns the list sorted by a property
  List<T> sortedBy<R extends Comparable<R>>(R Function(T) selector) {
    final sorted = [...this];
    sorted.sort((a, b) => selector(a).compareTo(selector(b)));
    return sorted;
  }
}