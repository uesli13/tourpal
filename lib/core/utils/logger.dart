import 'dart:developer' as dev;

enum LogLevel { debug, info, warning, error, critical }

/// Centralized logging utility for the TourPal application
/// 
/// Provides consistent logging patterns with different severity levels
/// and context-aware logging for better debugging and monitoring.
class AppLogger {
  static const String _appName = 'TourPal';

  /// Log levels for filtering
  static bool debugEnabled = true;
  static bool infoEnabled = true;
  static bool warningEnabled = true;
  static bool errorEnabled = true;
  static bool criticalEnabled = true;
  
  static void _log(String level, String message, [dynamic data]) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $level: $message';
    
    // Print to console in debug mode
    dev.log(
      logMessage,
      name: _appName,
      error: data is Exception ? data : null,
    );
    
    // In production, you might want to send critical errors to a monitoring service
    // if (level == '🚨 CRITICAL' && !kDebugMode) {
    //   FirebaseCrashlytics.instance.recordError(message, null);
    // }
  }
  
  static void debug(String message, [dynamic data]) {
    if (debugEnabled) {
      _log('🐛 DEBUG', message, data);
    }
  }
  
  static void info(String message, [dynamic data]) {
    if (infoEnabled) {
      _log('ℹ️ INFO', message, data);
    }
  }
  
  static void warning(String message, [dynamic data]) {
    if (warningEnabled) {
      _log('⚠️ WARNING', message, data);
    }
  }
  
  static void error(String message, [dynamic data]) {
    if (errorEnabled) {
      _log('❌ ERROR', message, data);
    }
  }
  
  static void critical(String message, [dynamic data]) {
    if (criticalEnabled) {
      _log('🚨 CRITICAL', message, data);
    }
  }
  
  static void blocEvent(String blocName, String eventName) {
    _log('🎯 BLOC EVENT', '$blocName: $eventName');
  }
  
  static void blocTransition(String blocName, String currentState, String nextState) {
    _log('🔄 BLOC TRANSITION', '$blocName: $currentState → $nextState');
  }
  
  static void serviceOperation(String serviceName, String operation, bool success) {
    final status = success ? '✅' : '❌';
    _log('🔧 SERVICE', '$status $serviceName.$operation()');
  }
  
  static void performance(String operation, Duration duration) {
    final ms = duration.inMilliseconds;
    final status = ms < 100 ? '🚀' : ms < 500 ? '⚡' : '🐌';
    _log('⏱️ PERFORMANCE', '$status $operation: ${ms}ms');
  }
  
  static void firebase(String operation, [dynamic data]) {
    _log('🔥 FIREBASE', '$operation${data != null ? ': $data' : ''}');
  }
  
  static void navigation(String route, [Map<String, dynamic>? params]) {
    final paramStr = params?.isNotEmpty == true ? ' with params: $params' : '';
    _log('🧭 NAVIGATION', 'Navigating to $route$paramStr');
  }
  
  static void network(String method, String url, int? statusCode, [Duration? duration]) {
    final statusStr = statusCode != null ? ' ($statusCode)' : '';
    final durationStr = duration != null ? ' in ${duration.inMilliseconds}ms' : '';
    _log('🌐 NETWORK', '$method $url$statusStr$durationStr');
  }
  
  static void auth(String operation, [String? userId]) {
    final userStr = userId != null ? ' for user $userId' : '';
    _log('🔐 AUTH', '$operation$userStr');
  }
  
  static void database(String operation, String collection, [String? docId]) {
    final docStr = docId != null ? '/$docId' : '';
    _log('🗄️ DATABASE', '$operation: $collection$docStr');
  }
  
  static void storage(String operation, String path, [int? fileSize]) {
    final sizeStr = fileSize != null ? ' (${(fileSize / 1024).toStringAsFixed(1)}KB)' : '';
    _log('📁 STORAGE', '$operation: $path$sizeStr');
  }
}