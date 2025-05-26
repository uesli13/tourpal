import 'dart:developer' as developer;

class AppLogger {
  static const String _appName = 'TOURPAL';
  
  // ✅ GOOD: Different log levels with emojis for easy identification
  static void debug(String message, [dynamic error]) {
    _log('🐛 DEBUG', message, error);
  }
  
  static void info(String message, [dynamic error]) {
    _log('ℹ️ INFO', message, error);
  }
  
  static void warning(String message, [dynamic error]) {
    _log('⚠️ WARNING', message, error);
  }
  
  static void error(String message, [dynamic error]) {
    _log('🚨 ERROR', message, error);
  }
  
  static void critical(String message, [dynamic error]) {
    _log('💥 CRITICAL', message, error);
  }
  
  // ✅ GOOD: Specialized logging for BLoC architecture
  static void blocTransition(String blocName, String currentState, String nextState) {
    _log('🔄 BLOC TRANSITION', '$blocName: $currentState → $nextState');
  }
  
  static void blocEvent(String blocName, String eventName) {
    _log('🎯 BLOC EVENT', '$blocName: $eventName');
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
  
  static void auth(String operation, [String? userId]) {
    final userStr = userId != null ? ' (User: $userId)' : '';
    _log('🔐 AUTH', '$operation$userStr');
  }
  
  // ✅ GOOD: Private method for consistent formatting
  static void _log(String level, String message, [dynamic error]) {
    final timestamp = DateTime.now().toIso8601String();
    final formattedMessage = '[$_appName] [$timestamp] $level: $message';
    
    if (error != null) {
      developer.log(
        formattedMessage,
        error: error,
        name: _appName,
      );
    } else {
      developer.log(
        formattedMessage,
        name: _appName,
      );
    }
  }
  
  // ✅ GOOD: Feature-specific logging helpers
  static void profile(String operation, [dynamic data]) {
    _log('👤 PROFILE', '$operation${data != null ? ': $data' : ''}');
  }
  
  static void tour(String operation, [dynamic data]) {
    _log('🗺️ TOUR', '$operation${data != null ? ': $data' : ''}');
  }
  
  static void booking(String operation, [dynamic data]) {
    _log('📅 BOOKING', '$operation${data != null ? ': $data' : ''}');
  }
  
  static void review(String operation, [dynamic data]) {
    _log('⭐ REVIEW', '$operation${data != null ? ': $data' : ''}');
  }
  
  static void message(String operation, [dynamic data]) {
    _log('💬 MESSAGE', '$operation${data != null ? ': $data' : ''}');
  }
  
  static void journal(String operation, [dynamic data]) {
    _log('📖 JOURNAL', '$operation${data != null ? ': $data' : ''}');
  }
  
  static void guide(String operation, [dynamic data]) {
    _log('👨‍🏫 GUIDE', '$operation${data != null ? ': $data' : ''}');
  }

  static void place(String operation, String placeId) {
    _log('📍 PLACE', '$operation (Place ID: $placeId)');
  }
}