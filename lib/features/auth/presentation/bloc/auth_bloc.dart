import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/bloc_error_handler.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/sign_up_with_email_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Handles all authentication state management
/// 
/// This BLoC manages the authentication flow and communicates with
/// auth usecases following Clean Architecture principles.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithEmailUsecase _signInWithEmailUsecase;
  final SignUpWithEmailUsecase _signUpWithEmailUsecase;
  final SignInWithGoogleUsecase _signInWithGoogleUsecase;
  final SignOutUsecase _signOutUsecase;
  final SendPasswordResetUsecase _sendPasswordResetUsecase;
  final GetCurrentUserUsecase _getCurrentUserUsecase;

  AuthBloc({
    required SignInWithEmailUsecase signInWithEmailUsecase,
    required SignUpWithEmailUsecase signUpWithEmailUsecase,
    required SignInWithGoogleUsecase signInWithGoogleUsecase,
    required SignOutUsecase signOutUsecase,
    required SendPasswordResetUsecase sendPasswordResetUsecase,
    required GetCurrentUserUsecase getCurrentUserUsecase,
  })  : _signInWithEmailUsecase = signInWithEmailUsecase,
        _signUpWithEmailUsecase = signUpWithEmailUsecase,
        _signInWithGoogleUsecase = signInWithGoogleUsecase,
        _signOutUsecase = signOutUsecase,
        _sendPasswordResetUsecase = sendPasswordResetUsecase,
        _getCurrentUserUsecase = getCurrentUserUsecase,
        super(AuthInitial()) {
    
    AppLogger.info('AuthBloc initialized with Clean Architecture usecases');
    
    on<CheckAuthStatusEvent>(_onCheckAuthStatusEvent);
    on<SignInWithEmailEvent>(_onSignInWithEmailEvent);
    on<SignUpWithEmailEvent>(_onSignUpWithEmailEvent);
    on<SignInWithGoogleEvent>(_onSignInWithGoogleEvent);
    on<SwitchGoogleAccountEvent>(_onSwitchGoogleAccountEvent);
    on<SignOutEvent>(_onSignOutEvent);
    on<SendPasswordResetEvent>(_onSendPasswordResetEvent);
    on<ClearAuthErrorEvent>(_onClearAuthErrorEvent);
    on<UpdateUserRoleEvent>(_onUpdateUserRoleEvent);
    
    // Handle legacy events for backward compatibility
    on<SignInRequested>(_onSignInRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    
    add(const CheckAuthStatusEvent());
  }

  @override
  void onChange(Change<AuthState> change) {
    super.onChange(change);
    BlocErrorHandler.logTransition(
      'AuthBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(AuthEvent event) {
    super.onEvent(event);
    BlocErrorHandler.logEvent('AuthBloc', event.runtimeType.toString());
  }

  Future<void> _onCheckAuthStatusEvent(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    BlocErrorHandler.logEvent('AuthBloc', 'CheckAuthStatusEvent');
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(const AuthLoading());
        
        // Use proper auth repository getCurrentUser method
        return await _getCurrentUserUsecase();
      },
      onSuccess: (user) {
        // Use the User model's proper profile completion check
        final isProfileComplete = user.hasCompletedProfile;
        
        if (isProfileComplete) {
          emit(AuthAuthenticated(user: user, isProfileComplete: true));
        } else {
          emit(AuthProfileSetupRequired(partialUser: user));
        }
      },
      onError: (error) {
        // If getting current user fails, user is not authenticated
        emit(const AuthUnauthenticated());
      },
      operationName: 'checkAuthStatus',
      serviceName: 'AuthUsecase',
    );
  }

  Future<void> _onSignInWithEmailEvent(
    SignInWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    BlocErrorHandler.logEvent('AuthBloc', 'SignInWithEmailEvent', {'email': event.email});
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(AuthLoading());
        final user = await _signInWithEmailUsecase(
          email: event.email,
          password: event.password,
        );
        return user;
      },
      onSuccess: (user) {
        // Use the User model's proper profile completion check
        final isProfileComplete = user.hasCompletedProfile;
        
        if (isProfileComplete) {
          emit(AuthAuthenticated(user: user, isProfileComplete: true));
        } else {
          emit(AuthProfileSetupRequired(partialUser: user));
        }
      },
      onError: (error) => emit(AuthError.fromException(error)),
      operationName: 'signInWithEmail',
      serviceName: 'AuthUsecase',
      context: {'email': event.email},
    );
  }

  Future<void> _onSignUpWithEmailEvent(
    SignUpWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    BlocErrorHandler.logEvent('AuthBloc', 'SignUpWithEmailEvent', {'email': event.email, 'name': event.name});
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(AuthLoading());
        final user = await _signUpWithEmailUsecase(
          email: event.email,
          password: event.password,
          name: event.name,
        );
        return user;
      },
      onSuccess: (user) {
        // New users always need profile setup
        emit(AuthProfileSetupRequired(partialUser: user));
      },
      onError: (error) => emit(AuthError.fromException(error)),
      operationName: 'signUpWithEmail',
      serviceName: 'AuthUsecase',
      context: {'email': event.email, 'name': event.name},
    );
  }

  Future<void> _onSignInWithGoogleEvent(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    BlocErrorHandler.logEvent('AuthBloc', 'SignInWithGoogleEvent');
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(AuthLoading());
        final user = await _signInWithGoogleUsecase();
        return user;
      },
      onSuccess: (user) {
        // Use the User model's proper profile completion check
        final isProfileComplete = user.hasCompletedProfile;
        
        if (isProfileComplete) {
          emit(AuthAuthenticated(user: user, isProfileComplete: true));
        } else {
          emit(AuthProfileSetupRequired(partialUser: user));
        }
      },
      onError: (error) => emit(AuthError.fromException(error)),
      operationName: 'signInWithGoogle',
      serviceName: 'AuthUsecase',
    );
  }

  Future<void> _onSwitchGoogleAccountEvent(
    SwitchGoogleAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    BlocErrorHandler.logEvent('AuthBloc', 'SwitchGoogleAccountEvent');
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(AuthLoading());
        
        // Sign out current user first
        await _signOutUsecase();
        
        // Then sign in with Google (which will prompt for account selection)
        final user = await _signInWithGoogleUsecase();
        return user;
      },
      onSuccess: (user) {
        // Use the User model's proper profile completion check
        final isProfileComplete = user.hasCompletedProfile;
        
        if (isProfileComplete) {
          emit(AuthAuthenticated(user: user, isProfileComplete: true));
        } else {
          emit(AuthProfileSetupRequired(partialUser: user));
        }
      },
      onError: (error) => emit(AuthError.fromException(error)),
      operationName: 'switchGoogleAccount',
      serviceName: 'AuthUsecase',
    );
  }

  Future<void> _onSignOutEvent(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    BlocErrorHandler.logEvent('AuthBloc', 'SignOutEvent');
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(const AuthLoading());
        await _signOutUsecase();
        emit(const AuthUnauthenticated());
      },
      onSuccess: (_) {}, // Success is handled in the operation itself
      onError: (error) => emit(AuthError.fromException(error)),
      operationName: 'signOut',
      serviceName: 'AuthUsecase',
    );
  }

  void _onClearAuthErrorEvent(
    ClearAuthErrorEvent event,
    Emitter<AuthState> emit,
  ) {
    BlocErrorHandler.logEvent('AuthBloc', 'ClearAuthErrorEvent');
    if (state is BaseErrorState) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSendPasswordResetEvent(
    SendPasswordResetEvent event,
    Emitter<AuthState> emit,
  ) async {
    BlocErrorHandler.logEvent('AuthBloc', 'SendPasswordResetEvent', {'email': event.email});
    
    // Input validation
    try {
      _validateEmailInput(event.email);
    } on ValidationException catch (e) {
      emit(AuthValidationError.fromValidationException(e));
      return;
    }

    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(const AuthPasswordResetting());
        await _sendPasswordResetUsecase(event.email);
        emit(const AuthPasswordResetSent());
      },
      onSuccess: (_) {}, // Success is handled in the operation itself
      onError: (error) => emit(AuthError.fromException(error)),
      operationName: 'sendPasswordReset',
      serviceName: 'AuthUsecase',
      context: {'email': event.email},
    );
  }

  Future<void> _onUpdateUserRoleEvent(
    UpdateUserRoleEvent event,
    Emitter<AuthState> emit,
  ) async {
    BlocErrorHandler.logEvent('AuthBloc', 'UpdateUserRoleEvent', {'isGuide': event.isGuide});
    
    // Get current state to update
    final currentState = state;
    if (currentState is! AuthAuthenticated) {
      AppLogger.error('UpdateUserRoleEvent called when user not authenticated');
      return;
    }
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        // Create updated user with new role immediately
        final updatedUser = currentState.user.copyWith(isGuide: event.isGuide);
        return updatedUser;
      },
      onSuccess: (updatedUser) {
        AppLogger.info('User role updated successfully in AuthBloc', {
          'userId': updatedUser.id,
          'isGuide': updatedUser.isGuide,
          'newRole': event.isGuide ? 'Guide' : 'Traveler'
        });
        
        // Immediately emit the new state to trigger UI rebuild
        emit(AuthAuthenticated(user: updatedUser, isProfileComplete: true));
      },
      onError: (error) {
        AppLogger.error('Failed to update user role in AuthBloc', error);
        emit(AuthError.fromException(error));
      },
      operationName: 'updateUserRole',
      serviceName: 'AuthUsecase',
      context: {'isGuide': event.isGuide},
    );
  }

  // Input validation helpers
  void _validateEmailInput(String email) {
    if (email.trim().isEmpty) {
      throw ValidationException.required('Email');
    }
    if (!email.contains('@') || !email.contains('.')) {
      throw ValidationException.invalid('Email', 'Please enter a valid email address');
    }
  }

  // Legacy event handlers for backward compatibility
  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Delegate to the new event
    add(SignInWithEmailEvent(
      email: event.email,
      password: event.password,
    ));
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Delegate to the new event
    add(const SignInWithGoogleEvent());
  }
}