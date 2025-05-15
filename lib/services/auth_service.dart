// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Google Sign-In
//   Future<User?> signInWithGoogle() async {
//     try {
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) return null; // User canceled the sign-in

//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       final UserCredential userCredential = await _auth.signInWithCredential(credential);
//       return userCredential.user;
//     } catch (e) {
//       print('Error during Google Sign-In: $e');
//       rethrow;
//     }
//   }

//   // Email/Password Sign-Up
//   Future<User?> signUpWithEmail(String email, String password) async {
//     try {
//       final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return userCredential.user;
//     } catch (e) {
//       print('Error during Email Sign-Up: $e');
//       rethrow;
//     }
//   }

//   // Email/Password Sign-In
//   Future<User?> signInWithEmail(String email, String password) async {
//     try {
//       final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return userCredential.user;
//     } catch (e) {
//       print('Error during Email Sign-In: $e');
//       rethrow;
//     }
//   }

//   // Sign Out
//   Future<void> signOut() async {
//     try {
//       await _auth.signOut();
//       await GoogleSignIn().signOut();
//     } catch (e) {
//       print('Error during Sign-Out: $e');
//       rethrow;
//     }
//   }
// }