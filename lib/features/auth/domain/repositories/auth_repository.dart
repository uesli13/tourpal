import '../../../../models/user.dart' as app_user;

abstract class AuthRepository {
  Future<app_user.User> signInWithEmailAndPassword(String email, String password);
  Future<app_user.User> signUpWithEmailAndPassword(String email, String password, String name);
  Future<app_user.User> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<app_user.User?> getCurrentUser();
  Stream<app_user.User?> get authStateChanges;
}