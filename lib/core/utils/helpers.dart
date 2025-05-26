import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

/// A collection of helper functions used throughout the application.
class Helpers {
  /// Picks an image from the gallery or camera
  static Future<File?> pickImage({bool fromCamera = false}) async {
    final imagePicker = ImagePicker();
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
    
    try {
      final pickedFile = await imagePicker.pickImage(
        source: source, 
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    
    return null;
  }
  
  /// Checks and requests permission
  static Future<bool> requestPermission(Permission permission) async {
    final status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      return false;
    }
    
    return false;
  }
  
  /// Launches a URL
  static Future<bool> launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    } else {
      return false;
    }
  }
  
  /// Shares content using the platform's share dialog
  static Future<void> shareContent({
    required String text,
    String? subject,
    List<String>? imagePaths,
  }) async {
    try {
      if (imagePaths != null && imagePaths.isNotEmpty) {
        final files = imagePaths.map((path) => XFile(path)).toList();
        await Share.shareXFiles(files, text: text);
      } else {
        await Share.share(text);
      }
    } catch (e) {
      debugPrint('Error sharing content: $e');
    }
  }
  
  /// Gets the current location
  static Future<Position?> getCurrentLocation() async {
    final permission = await requestPermission(Permission.location);
    
    if (!permission) {
      return null;
    }
    
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }
  
  /// Formats a date
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    return DateFormat(format).format(date);
  }
  
  /// Formats currency
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    return NumberFormat.currency(symbol: symbol).format(amount);
  }
  
  /// Formats a number with commas
  static String formatNumber(num number) {
    return NumberFormat('#,###').format(number);
  }
  
  /// Generates a random string of specified length
  static String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length, 
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
  
  /// Returns a user-friendly file size string (e.g., "2.5 MB")
  static String getFileSizeString(int bytes) {
    if (bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
  
  /// Gets the time difference between now and a given date
  static String getTimeDifference(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Returns a color from a string (useful for consistent avatar colors)
  static Color getColorFromString(String string) {
    var hash = 0;
    for (var i = 0; i < string.length; i++) {
      hash = string.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    final finalHash = hash.abs() % Colors.primaries.length;
    return Colors.primaries[finalHash];
  }
  
  /// Calculates the distance between two coordinates in kilometers
  static double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - 
      cos((lat2 - lat1) * p) / 2 + 
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    
    // 12742 is the diameter of the Earth in kilometers
    return 12742 * asin(sqrt(a));
  }
  
  /// Shows a toast message
  static void showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Input validation helpers
class InputValidators {
  /// Validates an email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  /// Validates a password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    return null;
  }
  
  /// Validates a required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }
  
  /// Validates a phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone may be optional
    }
    
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    
    return null;
  }
  
  /// Validates text length
  static String? validateLength(String? value, int maxLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return null; // Field may be optional
    }
    
    if (value.length > maxLength) {
      return '$fieldName must be $maxLength characters or less';
    }
    
    return null;
  }
  
  /// Validates a URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL may be optional
    }
    
    final urlRegex = RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Enter a valid URL';
    }
    
    return null;
  }
}