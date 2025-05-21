import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final fb.User? user = _authService.currentUser;
    if (user != null) {
      emit(AuthSuccess(user));
    } else {
      emit(AuthInitial());
    }
  }

  Future<void> _onSignInRequested(SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final fb.User? user = await _authService.signInWithEmail(event.email, event.password);
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthFailure('Unknown error during sign in'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final cred = await _authService.signUpWithEmail(event.email, event.password, event.name);
      final fb.User? user = cred?.user;
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthFailure('Unknown error during sign up'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onGoogleSignInRequested(GoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final cred = await _authService.signInWithGoogle();
      final fb.User? user = cred?.user;
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthFailure('Google sign‑in aborted'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(SignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authService.signOut();
    emit(AuthInitial());
  }
}
