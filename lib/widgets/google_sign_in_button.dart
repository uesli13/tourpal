import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleSignInButton({ required this.onPressed, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Image.asset('assets/images/google_logo.png', height: 24, width: 24),
      label: const Text("Sign in with Google"),
      onPressed: onPressed,
    );
  }
}