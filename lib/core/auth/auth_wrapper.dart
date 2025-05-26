import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/navigation/presentation/screens/main_navigation_screen.dart';
import '../../features/profile/presentation/widgets/main_app_wrapper.dart';
import '../../core/utils/logger.dart';

/// AuthWrapper manages the authentication flow using the new ProfileValidationWrapper
/// 
/// This widget uses MainAppWrapper to handle authentication and profile validation
/// following TOURPAL BLoC architecture principles.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    AppLogger.critical('🔍 AuthWrapper: initState called');
    // Check auth status when wrapper initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.critical('🔍 AuthWrapper: Triggering CheckAuthStatusEvent');
      context.read<AuthBloc>().add(const CheckAuthStatusEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        AppLogger.critical('🔍 AuthWrapper: Auth state = ${state.runtimeType}');
        
        switch (state.runtimeType) {
          case AuthLoading:
            AppLogger.critical('🔍 AuthWrapper: Showing loading screen');
            return _buildLoadingScreen();
            
          case AuthAuthenticated:
            final authState = state as AuthAuthenticated;
            AppLogger.critical('🔍 AuthWrapper: User authenticated - ${authState.user.id}');
            AppLogger.critical('🔍 AuthWrapper: Profile complete - ${authState.isProfileComplete}');
            
            // For verified users with complete profiles, go directly to main screen
            if (authState.isProfileComplete) {
              AppLogger.critical('🔍 AuthWrapper: NAVIGATING TO MAIN SCREEN');
              return const MainNavigationScreen();
            } else {
              AppLogger.critical('🔍 AuthWrapper: Profile incomplete - using wrapper');
              return MainAppWrapper(
                authenticatedChild: const MainNavigationScreen(),
                unauthenticatedChild: const LoginScreen(),
                requireCompleteProfile: true,
              );
            }
            
          case AuthProfileSetupRequired:
            AppLogger.critical('🔍 AuthWrapper: Profile setup required');
            return MainAppWrapper(
              authenticatedChild: const MainNavigationScreen(),
              unauthenticatedChild: const LoginScreen(),
              requireCompleteProfile: true,
            );
            
          case AuthUnauthenticated:
            AppLogger.critical('🔍 AuthWrapper: User unauthenticated - showing login');
            return const LoginScreen();
            
          case AuthError:
            final authState = state as AuthError;
            AppLogger.critical('🔍 AuthWrapper: Auth error - ${authState.message}');
            return _buildErrorScreen(authState.message);
            
          default:
            AppLogger.critical('🔍 AuthWrapper: Unknown state - ${state.runtimeType}');
            return _buildErrorScreen('Unknown authentication state');
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'TOURPAL',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $message',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                AppLogger.critical('🔍 AuthWrapper: Retrying auth check');
                context.read<AuthBloc>().add(const CheckAuthStatusEvent());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}