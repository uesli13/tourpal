import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_colors.dart';

class AppConfig {
  static const String appName = 'TourPal';
  static const String appVersion = '1.0.0';
  
  // API Keys from environment variables
  static String get googlePlacesApiKey {
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GOOGLE_PLACES_API_KEY not found in environment variables.');
    }
    return apiKey;
  }
  
  static String get googleMapsApiKey {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GOOGLE_MAPS_API_KEY not found in environment variables.');
    }
    return apiKey;
  }
  
  // Environment configuration
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static bool get isDebugMode => dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  
  // Theme configurations
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}