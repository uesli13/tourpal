import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? user;
  bool isLoading = false;
  String? error;

  AuthProvider(this._authService) {
    _authService.authStateChanges.listen((u) async {
      user = u;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _authService.signInWithEmailPassword(
        email: email, 
        password: password,
      );
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> signUp(String email, String password, String displayName) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _authService.signUpWithEmailPassword(
        email: email, 
        password: password,
        displayName: displayName,
      );
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    user = null;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
