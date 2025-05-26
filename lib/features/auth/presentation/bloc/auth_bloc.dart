import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourpal/features/auth/services/auth_service.dart';
import '../../../profile/services/profile_service.dart';
import '../../../../core/utils/logger.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Handles all authentication state management
/// 
/// This BLoC manages the authentication flow and communicates with
/// [AuthService] and [ProfileService] to perform authentication operations.
/// 
/// Events:
/// - [CheckAuthStatusEvent]: Checks current authentication status
/// - [SignInWithEmailEvent]: Signs in with email and password
/// - [SignUpWithEmailEvent]: Creates new account with email and password
/// - [SignInWithGoogleEvent]: Signs in with Google
/// - [SignOutEvent]: Signs out current user
/// - [ClearAuthErrorEvent]: Clears error state
/// 
/// States:
/// - [AuthInitial]: Initial state
/// - [AuthLoading]: Operation in progress
/// - [AuthAuthenticated]: User is authenticated
/// - [AuthUnauthenticated]: User is not authenticated
/// - [AuthSignUpSuccess]: Account created successfully
/// - [AuthError]: Operation failed
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final ProfileService _profileService;

  AuthBloc({
    required AuthService authService,
    required ProfileService profileService,
  })  : _authService = authService,
        _profileService = profileService,
        super(const AuthInitial()) {
    
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInWithEmailEvent>(_onSignInWithEmail);
    on<SignUpWithEmailEvent>(_onSignUpWithEmail);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SwitchGoogleAccountEvent>(_onSwitchGoogleAccount);
    on<SignOutEvent>(_onSignOut);
    on<ClearAuthErrorEvent>(_onClearAuthError);
    on<SendPasswordResetEvent>(_onSendPasswordReset);
    
    // Handle legacy events for backward compatibility
    on<SignInRequested>(_onSignInRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    
    add(const CheckAuthStatusEvent());
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    add(SignInWithEmailEvent(
      email: event.email,
      password: event.password,
    ));
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    add(const SignInWithGoogleEvent());
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.critical('🔍 AuthBloc: Starting auth status check');
    emit(const AuthLoading());
    
    try {
      final firebaseUser = _authService.currentUser;
      AppLogger.critical('🔍 AuthBloc: Firebase currentUser: ${firebaseUser?.uid ?? "null"}');
      
      if (firebaseUser == null) {
        AppLogger.critical('🔍 AuthBloc: No Firebase user found, emitting AuthUnauthenticated');
        emit(const AuthUnauthenticated());
        return;
      }

      AppLogger.critical('🔍 AuthBloc: Firebase user found, loading full profile');
      // User is authenticated, load their full profile
      final user = await _profileService.getUserProfile(firebaseUser.uid);
      AppLogger.critical('🔍 AuthBloc: Profile loaded for user: ${user.id}');
      AppLogger.critical('🔍 AuthBloc: User name: ${user.name}');
      AppLogger.critical('🔍 AuthBloc: User bio: "${user.bio}"');
      AppLogger.critical('🔍 AuthBloc: User birthdate: ${user.birthdate}');
      AppLogger.critical('🔍 AuthBloc: Has completed profile: ${user.hasCompletedProfile}');
      
      // Check if user has completed their profile
      if (user.hasCompletedProfile) {
        AppLogger.critical('🔍 AuthBloc: Profile complete, emitting AuthAuthenticated');
        emit(AuthAuthenticated(user: user, isProfileComplete: true));
      } else {
        AppLogger.critical('🔍 AuthBloc: Profile incomplete, emitting AuthProfileSetupRequired');
        emit(AuthProfileSetupRequired(partialUser: user));
      }
    } catch (e) {
      AppLogger.critical('🔍 AuthBloc: Error during auth check: $e');
      AppLogger.error('Failed to check auth status', e);
      emit(AuthError(message: 'Failed to check authentication status: ${e.toString()}'));
    }
  }

  Future<void> _onSignInWithEmail(
    SignInWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Validate inputs
      if (event.email.trim().isEmpty) {
        emit(const AuthError(message: 'Email is required'));
        return;
      }
      
      if (event.password.isEmpty) {
        emit(const AuthError(message: 'Password is required'));
        return;
      }

      await _authService.signInWithEmailPassword(
        email: event.email,
        password: event.password,
      );
      
      final userId = _authService.currentUserId;
      if (userId != null) {
        final user = await _profileService.getUserProfile(userId);
        final isProfileComplete = user.bio != null && user.bio!.isNotEmpty;
        emit(AuthAuthenticated(user: user, isProfileComplete: isProfileComplete));
            } else {
        emit(const AuthError(message: 'Failed to get user ID'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSignUpWithEmail(
    SignUpWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Validate inputs
      if (event.name.trim().isEmpty) {
        emit(const AuthError(message: 'Name is required'));
        return;
      }
      
      if (event.email.trim().isEmpty) {
        emit(const AuthError(message: 'Email is required'));
        return;
      }
      
      if (event.password.length < 6) {
        emit(const AuthError(message: 'Password must be at least 6 characters'));
        return;
      }

      await _authService.signUpWithEmailPassword(
        email: event.email,
        password: event.password,
        displayName: event.name,
      );
      
      final userId = _authService.currentUserId;
      if (userId != null) {
        final user = await _profileService.getUserProfile(userId);
        emit(AuthSignUpSuccess(user: user));
            } else {
        emit(const AuthError(message: 'Failed to get user ID'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authService.signInWithGoogle();
      
      final userId = _authService.currentUserId;
      if (userId != null) {
        final user = await _profileService.getUserProfile(userId);
        final isProfileComplete = user.bio != null && user.bio!.isNotEmpty;
        emit(AuthAuthenticated(user: user, isProfileComplete: isProfileComplete));
            } else {
        emit(const AuthError(message: 'Failed to get user ID'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authService.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  void _onClearAuthError(
    ClearAuthErrorEvent event,
    Emitter<AuthState> emit,
  ) {
    if (state is AuthError) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSendPasswordReset(
    SendPasswordResetEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Validate email
      if (event.email.trim().isEmpty) {
        emit(const AuthError(message: 'Email is required'));
        return;
      }
      
      await _authService.sendPasswordResetEmail(event.email);
      emit(const AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle switching Google accounts - signs out and shows account selection
  Future<void> _onSwitchGoogleAccount(
    SwitchGoogleAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authService.switchGoogleAccount();
      
      final userId = _authService.currentUserId;
      if (userId != null) {
        final user = await _profileService.getUserProfile(userId);
        final isProfileComplete = user.bio != null && user.bio!.isNotEmpty;
        emit(AuthAuthenticated(user: user, isProfileComplete: isProfileComplete));
      } else {
        emit(const AuthError(message: 'Failed to get user ID'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}