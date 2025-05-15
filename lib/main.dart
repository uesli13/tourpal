import 'package:flutter/material.dart';
import 'package:tourpal/screens/loading_screen.dart';
import 'package:tourpal/utils/constants.dart'; // Import the constants file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Remove: await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TourPal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary), // Use the app color here
        useMaterial3: true,
      ),
      home: LoadingScreen(),
    );
  }
}
