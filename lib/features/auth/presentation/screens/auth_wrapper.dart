import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../navigation/presentation/screens/main_navigation_screen.dart';
import '../../../profile/presentation/screens/profile_setup_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is AuthAuthenticated) {
          // Check if profile is complete using the user from auth state
          if (state.isProfileComplete) {
            return const MainNavigationScreen();
          } else {
            return const ProfileSetupScreen();
          }
        } else if (state is AuthProfileSetupRequired) {
          return const ProfileSetupScreen();
        } else if (state is AuthSignUpSuccess) {
          return const ProfileSetupScreen();
        }
        return const LoginScreen();
      },
    );
  }
}