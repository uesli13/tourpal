import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _firestore = firestore;

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'sign_in_failed',
          message: 'Sign in failed',
        );
      }
      
      return UserModel.fromFirebaseUser(credential.user!);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'sign_up_failed',
          message: 'Sign up failed',
        );
      }

      // Update display name
      await credential.user!.updateDisplayName(name);
      
      // Create user document in Firestore
      final userModel = UserModel.fromFirebaseUser(credential.user!);
      await _firestore.collection('users').doc(credential.user!.uid).set(
        userModel.copyWith(name: name).toMap(),
      );
      
      return userModel.copyWith(name: name);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'sign_in_aborted',
          message: 'Google sign in was aborted',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'sign_in_failed',
          message: 'Google sign in failed',
        );
      }

      // Check if user exists in Firestore, create if not
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      final userModel = UserModel.fromFirebaseUser(userCredential.user!);
      
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set(
          userModel.toMap(),
        );
      }
      
      return userModel;
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'sign_out_failed',
        message: e.toString(),
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!, user.uid);
      } else {
        return UserModel.fromFirebaseUser(user);
      }
    } catch (e) {
      return UserModel.fromFirebaseUser(user);
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data()!, user.uid);
        } else {
          return UserModel.fromFirebaseUser(user);
        }
      } catch (e) {
        return UserModel.fromFirebaseUser(user);
      }
    });
  }
}