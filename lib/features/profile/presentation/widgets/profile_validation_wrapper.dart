import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../screens/profile_setup_screen.dart';

/// ProfileValidationWrapper ensures users have a valid profile after authentication
/// Following TOURPAL BLoC architecture principles
class ProfileValidationWrapper extends StatefulWidget {
  final Widget child;
  final bool requireCompleteProfile;
  final User? partialUser; // For cases where we have a partial user from auth

  const ProfileValidationWrapper({
    super.key,
    required this.child,
    this.requireCompleteProfile = true,
    this.partialUser,
  });

  @override
  State<ProfileValidationWrapper> createState() => _ProfileValidationWrapperState();
}

class _ProfileValidationWrapperState extends State<ProfileValidationWrapper> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('ProfileValidationWrapper initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProfile();
    });
  }

  void _initializeProfile() {
    final authState = context.read<AuthBloc>().state;
    
    if (authState is AuthAuthenticated) {
      AppLogger.profile('User authenticated, loading profile', authState.user.id);
      context.read<ProfileBloc>().add(LoadProfile(authState.user.id));
    } else {
      AppLogger.info('User not authenticated, skipping profile load');
    }
    
    setState(() {
      _hasInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we have a partial user, skip profile loading and go to setup
    if (widget.partialUser != null) {
      AppLogger.profile('Partial user provided, validating for setup', widget.partialUser!.id);
      final validation = _validateUserProfile(widget.partialUser!);
      
      if (!validation.isValid && widget.requireCompleteProfile) {
        return _buildProfileSetupRequired(context, validation);
      }
      
      return widget.child;
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        AppLogger.blocTransition('AuthBloc', 'Previous', authState.runtimeType.toString());
        
        if (authState is AuthAuthenticated) {
          AppLogger.profile('Auth state changed to authenticated, loading profile', authState.user.id);
          context.read<ProfileBloc>().add(LoadProfile(authState.user.id));
        } else if (authState is AuthUnauthenticated) {
          AppLogger.profile('User unauthenticated, clearing profile state', '');
          // Profile will be cleared automatically when user signs out
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          // Show loading while initializing
          if (!_hasInitialized) {
            return _buildLoadingScreen();
          }

          // Handle unauthenticated state
          if (authState is! AuthAuthenticated) {
            AppLogger.info('User not authenticated, showing child widget');
            return widget.child;
          }

          // User is authenticated, check profile validity
          return BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, profileState) {
              AppLogger.blocTransition('ProfileBloc', 'Previous', profileState.runtimeType.toString());
              
              if (profileState is ProfileError) {
                AppLogger.error('Profile validation error: ${profileState.message}');
                _showErrorSnackBar(context, profileState.message);
              }
            },
            builder: (context, profileState) {
              return _buildProfileValidationContent(
                context,
                authState,
                profileState,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileValidationContent(
    BuildContext context,
    AuthAuthenticated authState,
    ProfileState profileState,
  ) {
    // Handle loading state
    if (profileState is ProfileLoading) {
      AppLogger.info('Profile loading, showing loading screen');
      return _buildLoadingScreen();
    }

    // Handle error state
    if (profileState is ProfileError) {
      AppLogger.error('Profile error, showing retry screen');
      return _buildErrorScreen(context, authState.user as firebase_auth.User, profileState.message);
    }

    // Handle loaded profile
    if (profileState is ProfileLoaded) {
      final user = profileState.user;
      AppLogger.profile('Profile loaded for user', user.id);
      
      // Validate profile completeness
      final profileValidation = _validateUserProfile(user);
      
      if (!profileValidation.isValid) {
        AppLogger.warning('Profile validation failed: ${profileValidation.reason}');
        
        if (widget.requireCompleteProfile) {
          return _buildProfileSetupRequired(context, profileValidation);
        } else {
          AppLogger.info('Profile incomplete but not required, showing child');
          return widget.child;
        }
      }

      AppLogger.profile('Profile validation passed, showing app', user.id);
      return widget.child;
    }

    // Default state - profile not loaded yet
    AppLogger.info('Profile not loaded, attempting to load');
    context.read<ProfileBloc>().add(LoadProfile(authState.user.id));
    return _buildLoadingScreen();
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 24),
            
            // Loading Text
            const Text(
              'Loading your profile...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Please wait while we set things up',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, firebase_auth.User user, String error) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.defaultPadding),
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
              
              // Error Title
              const Text(
                'Profile Load Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Error Message
              Text(
                error,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Retry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AppLogger.info('Retrying profile load for user: ${user.uid}');
                    context.read<ProfileBloc>().add(LoadProfile(user.uid));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UIConstants.defaultBorderRadius),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSetupRequired(BuildContext context, ProfileValidationResult validation) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Setup Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 60,
                  color: AppColors.accent,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Setup Title
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Setup Message
              Text(
                validation.reason,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Setup Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AppLogger.profile('Navigating to profile setup', validation.userId ?? '');
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const ProfileSetupScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UIConstants.defaultBorderRadius),
                    ),
                  ),
                  child: const Text(
                    'Complete Setup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ProfileValidationResult _validateUserProfile(dynamic user) {
    AppLogger.profile('🔍 VALIDATING USER PROFILE', user.id);
    AppLogger.profile('User bio: "${user.bio}"', user.id);
    AppLogger.profile('User birthdate: ${user.birthdate}', user.id);
    AppLogger.profile('Has completed profile: ${user.hasCompletedProfile}', user.id);
    
    if (!widget.requireCompleteProfile) {
      AppLogger.profile('✅ Profile validation SKIPPED (not required)', user.id);
      return ProfileValidationResult(
        isValid: true,
        reason: 'Profile validation not required',
        userId: user.id,
        missingFields: [],
      );
    }
    
    final hasBio = user.bio != null && user.bio!.trim().isNotEmpty;
    final hasBirthdate = user.birthdate != null;
    
    AppLogger.profile('Bio check: $hasBio (value: "${user.bio}")', user.id);
    AppLogger.profile('Birthdate check: $hasBirthdate (value: ${user.birthdate})', user.id);
    
    final missingFields = <String>[];
    if (!hasBio) missingFields.add('bio');
    if (!hasBirthdate) missingFields.add('birthdate');
    
    if (hasBio && hasBirthdate) {
      AppLogger.profile('✅ Profile validation PASSED - navigating to main app', user.id);
      return ProfileValidationResult(
        isValid: true,
        reason: 'Profile is complete',
        userId: user.id,
        missingFields: [],
      );
    } else {
      AppLogger.profile('❌ Profile validation FAILED - showing profile setup', user.id);
      if (!hasBio) AppLogger.profile('Missing: bio', user.id);
      if (!hasBirthdate) AppLogger.profile('Missing: birthdate', user.id);
      
      return ProfileValidationResult(
        isValid: false,
        reason: 'Please complete your profile to continue. Missing: ${missingFields.join(", ")}',
        userId: user.id,
        missingFields: missingFields,
      );
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Profile validation result following TOURPAL validation patterns
class ProfileValidationResult {
  final bool isValid;
  final String reason;
  final String? userId;
  final List<String> missingFields;

  const ProfileValidationResult({
    required this.isValid,
    required this.reason,
    this.userId,
    required this.missingFields,
  });

  @override
  String toString() {
    return 'ProfileValidationResult{isValid: $isValid, reason: $reason, missingFields: $missingFields}';
  }
}