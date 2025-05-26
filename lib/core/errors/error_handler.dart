import 'package:flutter/foundation.dart';

class AppErrorHandler {
  static void handleCriticalError(dynamic error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('❌❌❌ CRITICAL ERROR ❌❌❌');
      print('Error: $error');
      print('Stack: $stackTrace');
    }
    
    // TODO: Add crash reporting (Firebase Crashlytics)
  }
  
  static void handleError(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ Error: $error');
      if (stackTrace != null) {
        print('Stack: $stackTrace');
      }
    }
    
    // TODO: Add error logging
  }
  
  static void logInfo(String message) {
    if (kDebugMode) {
      print('ℹ️ $message');
    }
  }
}

class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, [this.code]);
  
  @override
  String toString() => 'AppException: $message';
}