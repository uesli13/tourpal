import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_colors.dart';
import 'core/utils/logger.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    AppLogger.info('Environment variables loaded successfully');
    
    await Firebase.initializeApp();
    AppLogger.info('Firebase initialized successfully');
    
    // Initialize Firebase App Check
    await FirebaseAppCheck.instance.activate(
      // For Android, use debug provider in debug mode
      androidProvider: AndroidProvider.debug,
      // For iOS, use debug provider in debug mode  
      appleProvider: AppleProvider.debug,
    );
    AppLogger.info('Firebase App Check initialized successfully');
    
    runApp(const MyApp());
  } catch (e) {
    AppLogger.critical('Failed to initialize Firebase: $e');
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Please check your configuration and try again.'),
            ],
          ),
        ),
      ),
    );
  }
}