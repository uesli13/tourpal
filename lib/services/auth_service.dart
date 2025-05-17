import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:tourpal/services/user_repository.dart';
import '../models/user.dart'; 
class AuthService {

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserRepository _users = UserRepository();


  // Future<fb.UserCredential?> signUpWithEmail(String email, String password, String name) async {
  //   final cred = await _auth.createUserWithEmailAndPassword(
  //     email: email, password: password);
  //   if (cred.user != null) {
  //     // write to Firestore
  //     await _createFirestoreUser(
  //       uid: cred.user!.uid,
  //       email: email,
  //       name: name,
  //     );
  //   }
  //   return cred;
  // }

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

  
  

    // Future<fb.UserCredential?> signInWithGoogle() async {
    //   final googleUser = await GoogleSignIn().signIn();
    //   if (googleUser == null) return null;

    //   final googleAuth = await googleUser.authentication;
    //   final credential = fb.GoogleAuthProvider.credential(
    //     accessToken: googleAuth.accessToken,
    //     idToken: googleAuth.idToken,
    //   );
    //   final cred = await _auth.signInWithCredential(credential);

    //   // If this is first time, create Firestore doc
    //   final doc = await _db.collection('user').doc(cred.user!.uid).get();
    //   if (!doc.exists) {
    //     await _createFirestoreUser(
    //       uid: cred.user!.uid,
    //       email: cred.user!.email!,
    //       name: cred.user!.displayName ?? 'Unknown',
    //     );
    //   }
    //   return cred;
    // }

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



    




    

  
  //   Future<void> _createFirestoreUser({
  //   required String uid,
  //   required String email,
  //   required String name,
  // }) async {
  //   final now = DateTime.now().toUtc().toIso8601String();
  //   final user = User(
  //     id:        uid,
  //     email:     email,
  //     name:      name,
  //     profilePhoto: '',
  //     description:  '',
  //     birthdate:    '',
  //     regdate:      now,
  //   );
  //   await _db.collection('user').doc(uid).set(user.toJson());
  // }



  

  Future<void> signOut() async {
    await _auth.signOut();
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

}
