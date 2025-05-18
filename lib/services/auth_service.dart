import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:tourpal/services/user_repository.dart';
import '../models/user.dart'; 
class AuthService {

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final UserRepository _users = UserRepository();

  Future<fb.UserCredential?> signUpWithEmail(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      final now = DateTime.now().toUtc().toIso8601String();
      final appUser = User(
        id: cred.user!.uid,
        email: email,
        name: name,
        profilePhoto: '',
        description: '',
        birthdate: '',
        regdate: now,
      );
      await _users.createUser(appUser);
    }
    return cred;
  }

    Future<fb.User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password);
    return cred.user;
  }

  Future<fb.UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);

    // Delegate to UserRepository
    final uid   = cred.user!.uid;
    final email = cred.user!.email!;
    final name  = cred.user!.displayName ?? 'Unknown';

    // Check for existing doc
    final existing = await _users.fetchUser(uid);
    if (existing == null) {
      final now = DateTime.now().toUtc().toIso8601String();
      final appUser = User(
        id:           uid,
        email:        email,
        name:         name,
        profilePhoto: '',
        description:  '',
        birthdate:    '',
        regdate:      now,
      );
      await _users.createUser(appUser);
    }

    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

}
