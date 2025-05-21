import 'package:flutter/material.dart';
import 'package:tourpal/blocs/auth/auth_bloc.dart';
import 'package:tourpal/screens/home_screen.dart';
import 'package:tourpal/screens/sign_in_screen.dart';
import 'package:tourpal/utils/constants.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_state.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SignInScreen()),
          );
        } else if (state is AuthSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Auth error: ${state.error}')),
          );
        }
      },
      child: Scaffold(
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
      ),
    );
  }
}