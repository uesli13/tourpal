import 'package:flutter/material.dart';
import 'package:tourpal/screens/home_screen.dart';
import 'package:tourpal/screens/sign_in_screen.dart';
import 'package:tourpal/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {

  void _checkAuthState() {
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      // Not signed in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    } else {
      // Signed in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _checkAuthState();
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