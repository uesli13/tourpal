import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Image.asset(
        'assets/images/google_logo.png',
        height: 24,
        width: 24,
      ),
      label: const Text("Sign in with Google"),
      onPressed: () async {
        final userCredential = await AuthService().signInWithGoogle();
        if (userCredential != null) {
          // Handle successful login
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          // Show error or keep on login screen
        }
      },
    );
  }
}
