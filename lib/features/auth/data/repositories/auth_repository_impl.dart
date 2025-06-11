import '../../domain/repositories/auth_repository.dart';
import '../../../../models/user.dart' as app_user;
import '../datasources/firebase_auth_datasource.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<app_user.User?> getCurrentUser() async {
    try {
      return await _dataSource.getCurrentUser();
    } catch (e) {
      AppLogger.error('Failed to get current user', e);
      throw const AuthenticationException('Failed to get current user');
    }
  }

  @override
  Future<app_user.User> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _dataSource.signInWithEmailAndPassword(email, password);
    } catch (e) {
      AppLogger.error('Sign in failed', e);
      throw AuthenticationException('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<app_user.User> signUpWithEmailAndPassword(String email, String password, String name) async {
    try {
      return await _dataSource.signUpWithEmailAndPassword(email, password, name);
    } catch (e) {
      AppLogger.error('Sign up failed', e);
      throw AuthenticationException('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<app_user.User> signInWithGoogle() async {
    try {
      return await _dataSource.signInWithGoogle();
    } catch (e) {
      AppLogger.error('Google sign in failed', e);
      throw AuthenticationException('Google sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } catch (e) {
      AppLogger.error('Sign out failed', e);
      throw const AuthenticationException('Sign out failed');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
    } catch (e) {
      AppLogger.error('Password reset failed', e);
      throw AuthenticationException('Password reset failed: ${e.toString()}');
    }
  }

  @override
  Stream<app_user.User?> get authStateChanges => _dataSource.authStateChanges;
}