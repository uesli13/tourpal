import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

    Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password);
    return cred.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }


  Future<void> updateUserProfile(String displayName, String photoURL) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateProfile(displayName: displayName, photoURL: photoURL);
      await user.reload();
    }
  }

}
