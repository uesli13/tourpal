import 'package:flutter/material.dart';
import 'package:tourpal/services/auth_service.dart';
import 'package:tourpal/utils/constants.dart';
import 'package:tourpal/screens/sign_in_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

void _confirmAndSignOut(BuildContext context) async {
  final shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );

  if (shouldSignOut == true) {
    await AuthService().signOut();

    // Use microtask to safely navigate after widget rebuild
    Future.microtask(() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Home'),
        actions: [
          TextButton(
            onPressed:() => _confirmAndSignOut(context),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      body: const Center(
        child: Text('Welcome to TourPal!'),
      ),
    );
  }
}