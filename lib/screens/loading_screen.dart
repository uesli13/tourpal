import 'package:flutter/material.dart';
import 'package:tourpal/screens/home_screen.dart';
import 'package:tourpal/screens/sign_in_screen.dart';
import 'package:tourpal/utils/constants.dart'; // Import the constants file

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Simulate a loading delay (e.g., fetching user data or initializing the app)
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/images/tourpal_logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            // Loading Indicator
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            // App Name
            const Text(
              'TourPal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}