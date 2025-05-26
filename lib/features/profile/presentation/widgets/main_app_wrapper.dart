import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/profile_validation_wrapper.dart';

/// MainAppWrapper handles the main app navigation flow
/// Following TOURPAL BLoC architecture principles
class MainAppWrapper extends StatelessWidget {
  final Widget authenticatedChild;
  final Widget? unauthenticatedChild;
  final bool requireCompleteProfile;

  const MainAppWrapper({
    super.key,
    required this.authenticatedChild,
    this.unauthenticatedChild,
    this.requireCompleteProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        AppLogger.critical('🔍 MainAppWrapper received auth state: ${state.runtimeType}');
        
        switch (state.runtimeType) {
          case AuthLoading:
            AppLogger.critical('🔍 MainAppWrapper: Showing loading screen');
            return _buildLoadingScreen();
            
          case AuthUnauthenticated:
            AppLogger.critical('🔍 MainAppWrapper: Showing login screen');
            return unauthenticatedChild ?? const LoginScreen();
            
          case AuthAuthenticated:
            final authState = state as AuthAuthenticated;
            AppLogger.critical('🔍 AuthAuthenticated user: ${authState.user.id}');
            AppLogger.critical('🔍 User profile complete: ${authState.isProfileComplete}');
            
            // If profile validation is not required, go directly to main app
            if (!requireCompleteProfile) {
              AppLogger.critical('🔍 Profile validation not required - going to main app');
              return authenticatedChild;
            }
            
            // If profile is complete, go directly to main app
            if (authState.isProfileComplete) {
              AppLogger.critical('🔍 Profile complete - going to main app');
              return authenticatedChild;
            }
            
            // Profile is incomplete and required - use ProfileValidationWrapper
            AppLogger.critical('🔍 Profile incomplete - using ProfileValidationWrapper');
            return ProfileValidationWrapper(
              requireCompleteProfile: requireCompleteProfile,
              child: authenticatedChild,
            );
            
          case AuthProfileSetupRequired:
            final authState = state as AuthProfileSetupRequired;
            AppLogger.critical('🔍 AuthProfileSetupRequired user: ${authState.partialUser.id}');
            
            // For users who need profile setup
            return ProfileValidationWrapper(
              requireCompleteProfile: requireCompleteProfile,
              child: authenticatedChild,
              partialUser: authState.partialUser,
            );
            
          case AuthError:
            final authState = state as AuthError;
            AppLogger.critical('🔍 MainAppWrapper: Auth error: ${authState.message}');
            return _buildErrorScreen(message: authState.message);
            
          default:
            AppLogger.critical('🔍 MainAppWrapper: Unknown auth state: ${state.runtimeType}');
            return _buildErrorScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // App Name
            const Text(
              'TOURPAL',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Your Personal Tour Guide',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Starting your journey...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen({String? message}) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: AppColors.error,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              message ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Please restart the app',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}