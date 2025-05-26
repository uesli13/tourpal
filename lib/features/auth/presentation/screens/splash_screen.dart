import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_screen.dart';
import '../../../navigation/presentation/screens/main_navigation_screen.dart';
import '../../../profile/presentation/screens/profile_setup_screen.dart';

/// Splash screen with enhanced visual design matching ProfileSetupScreen
/// Following TOURPAL development rules with BLoC integration and AppLogger
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _subtitleOpacityAnimation;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('SplashScreen: Initializing with enhanced animations');
    
    _setupAnimations();
    _startAnimationSequence();
    
    // Initialize auth check after short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_hasInitialized) {
        AppLogger.info('SplashScreen: Starting auth status check');
        context.read<AuthBloc>().add(const CheckAuthStatusEvent());
        _hasInitialized = true;
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: AnimationDurations.extraSlow,
      vsync: this,
    );

    // Logo scale animation with bounce effect
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    // Title slide animation
    _titleSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    // Subtitle opacity animation
    _subtitleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    ));
  }

  void _startAnimationSequence() {
    _animationController.forward();
  }

  @override
  void dispose() {
    AppLogger.info('SplashScreen: Disposing animation controller');
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('SplashScreen: Building enhanced splash screen');
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        AppLogger.blocTransition('AuthBloc', 'Previous', state.runtimeType.toString());
        
        // Add small delay to let animations complete
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          
          if (state is AuthAuthenticated) {
            AppLogger.auth('User authenticated, checking profile completion', state.user.id);
            
            if (state.user.hasCompletedProfile) {
              AppLogger.info('SplashScreen: Profile complete, navigating to main app');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              );
            } else {
              AppLogger.info('SplashScreen: Profile incomplete, navigating to profile setup');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
              );
            }
          } else if (state is AuthUnauthenticated) {
            AppLogger.info('SplashScreen: User not authenticated, navigating to login');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          } else if (state is AuthError) {
            AppLogger.error('SplashScreen: Auth error - ${state.message}');
            _showErrorSnackBar(state.message);
          }
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    AppColors.gray50,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(UIConstants.paddingLarge),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Welcome Text (animated)
                      Transform.translate(
                        offset: Offset(0, _titleSlideAnimation.value),
                        child: Opacity(
                          opacity: _subtitleOpacityAnimation.value,
                          child: const Text(
                            'Welcome to',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Logo Container (animated)
                      Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Opacity(
                          opacity: _logoOpacityAnimation.value,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.1),
                                  AppColors.secondary.withValues(alpha: 0.1),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  blurRadius: 50,
                                  offset: const Offset(0, 25),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    AssetPaths.appIcon,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      AppLogger.warning('Failed to load app icon, using fallback');
                                      return const Icon(
                                        Icons.explore,
                                        size: 60,
                                        color: AppColors.white,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // App Name (animated)
                      Transform.translate(
                        offset: Offset(0, _titleSlideAnimation.value),
                        child: Opacity(
                          opacity: _logoOpacityAnimation.value,
                          child: Text(
                            AppInfo.name,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 3,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Tagline (animated)
                      Transform.translate(
                        offset: Offset(0, _titleSlideAnimation.value * 0.5),
                        child: Opacity(
                          opacity: _subtitleOpacityAnimation.value,
                          child: const Text(
                            'Your Personal Tour Guide',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Loading Section (animated)
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return Opacity(
                            opacity: _subtitleOpacityAnimation.value,
                            child: _buildLoadingSection(state),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Version Info (animated)
                      Opacity(
                        opacity: _subtitleOpacityAnimation.value * 0.7,
                        child: Text(
                          'Version ${AppInfo.version}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingSection(AuthState state) {
    if (state is AuthLoading) {
      return Column(
        children: [
          // Custom loading indicator matching profile setup style
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 3,
              ),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Loading text
          const Text(
            'Starting your journey...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Loading dots animation
          _buildLoadingDots(),
        ],
      );
    }
    
    if (state is AuthError) {
      return Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 30,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Initialization failed',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    return const SizedBox(height: 100); // Maintain spacing
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delay = index * 0.2;
            final progress = (_animationController.value - delay).clamp(0.0, 1.0);
            final opacity = (progress * 2).clamp(0.0, 1.0);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            AppLogger.info('SplashScreen: Retrying auth status check');
            context.read<AuthBloc>().add(const CheckAuthStatusEvent());
          },
        ),
      ),
    );
  }
}