import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tourpal/core/config/firebase_options.dart';

// Core imports following TourPal rules
import 'core/providers/app_providers.dart';
import 'core/utils/logger.dart';
import 'core/constants/app_theme.dart';
import 'core/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    AppLogger.info('🚀 TOURPAL App initializing...');
    // ✅ FIXED: Use proper Firebase options configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('🔥 Firebase initialized successfully with proper configuration');
    
    runApp(const TourpalApp());
    AppLogger.info('✅ TOURPAL App started successfully');
  } catch (e) {
    AppLogger.critical('💥 Failed to initialize app', e);
    runApp(ErrorApp(error: e.toString()));
  }
}

class TourpalApp extends StatelessWidget {
  const TourpalApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.info('TourpalApp: Building main app with AppProviders');
    
    return AppProviders(
      child: MaterialApp(
        title: 'TOURPAL',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        onUnknownRoute: (settings) {
          AppLogger.warning('Unknown route requested: ${settings.name}');
          return MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          );
        },
      ),
    );
  }
}

/// Error app to show when Firebase initialization fails
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOURPAL - Error',
      theme: ThemeData.light(),
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade700,
                ),
                const SizedBox(height: 24),
                Text(
                  '🚨 TOURPAL Initialization Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'There was an error starting the app:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Please restart the app or contact support.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}