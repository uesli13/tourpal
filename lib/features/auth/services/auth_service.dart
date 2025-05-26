import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user.dart' as app_user;
import '../../../core/utils/logger.dart';

/// Handles all Firebase Authentication operations following Tourpal rules
/// 
/// This service manages user authentication including email/password,
/// Google sign-in, and user registration with Firestore integration.
class AuthService {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Get current Firebase user
  firebase_auth.User? get currentUser => _auth.currentUser;
  
  /// Get current user ID - convenience getter for BLoCs
  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream of authentication state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Stream of current user with profile data - BLoC-compatible getter
  Stream<app_user.User?> get currentUserStream => _auth.authStateChanges().asyncMap((firebaseUser) async {
    if (firebaseUser == null) return null;
    
    try {
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return app_user.User.fromMap(userDoc.data()!, firebaseUser.uid);
      }
      return null;
    } catch (e) {
      AppLogger.error('AuthService: Error getting user profile', e);
      return null;
    }
  });

  /// Sign in with email and password - BLoC-compatible method name
  Future<firebase_auth.UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    AppLogger.info('AuthService: Attempting email/password sign in');
    
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      AppLogger.info('AuthService: Email/password sign in successful');
      AppLogger.serviceOperation('AuthService', 'signInWithEmailPassword', true);
      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('AuthService: Email/password sign in failed', e);
      AppLogger.serviceOperation('AuthService', 'signInWithEmailPassword', false);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('AuthService: Unexpected sign in error', e);
      AppLogger.serviceOperation('AuthService', 'signInWithEmailPassword', false);
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign up with email and password - BLoC-compatible method name
  Future<firebase_auth.UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    AppLogger.info('AuthService: Attempting email/password sign up');
    
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName.trim());

        // Create user profile in Firestore
        final user = app_user.User(
          id: credential.user!.uid,
          name: displayName.trim(),
          email: email.trim(),
          profileImageUrl: null,
          bio: null,
          isGuide: false,
          favoriteTours: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(user.toMap());

        AppLogger.info('AuthService: User profile created in Firestore');
      }

      AppLogger.info('AuthService: Email/password sign up successful');
      AppLogger.serviceOperation('AuthService', 'signUpWithEmailPassword', true);
      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('AuthService: Email/password sign up failed', e);
      AppLogger.serviceOperation('AuthService', 'signUpWithEmailPassword', false);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('AuthService: Unexpected sign up error', e);
      AppLogger.serviceOperation('AuthService', 'signUpWithEmailPassword', false);
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign in with Google - always shows account selection
  Future<firebase_auth.UserCredential> signInWithGoogle() async {
    AppLogger.info('AuthService: Attempting Google sign in with account selection');
    
    try {
      // Always clear cached account to ensure account selection appears
      AppLogger.info('AuthService: Clearing cached Google account for account selection');
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        AppLogger.warning('AuthService: Google sign in cancelled by user');
        throw Exception('Google sign in was cancelled');
      }

      AppLogger.info('AuthService: Google account selected - ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user profile in Firestore if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser == true && userCredential.user != null) {
        final user = app_user.User(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'User',
          email: userCredential.user!.email!,
          profileImageUrl: userCredential.user!.photoURL,
          bio: null,
          isGuide: false,
          favoriteTours: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(user.toMap());

        AppLogger.info('AuthService: New Google user profile created in Firestore');
      }

      AppLogger.info('AuthService: Google sign in successful for ${userCredential.user?.email}');
      AppLogger.serviceOperation('AuthService', 'signInWithGoogle', true);
      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('AuthService: Google sign in failed', e);
      AppLogger.serviceOperation('AuthService', 'signInWithGoogle', false);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('AuthService: Unexpected Google sign in error', e);
      AppLogger.serviceOperation('AuthService', 'signInWithGoogle', false);
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  /// Switch Google account - signs out and shows account selection
  Future<firebase_auth.UserCredential> switchGoogleAccount() async {
    AppLogger.info('AuthService: Switching Google account');
    
    try {
      // Sign out from current session
      await signOut();
      
      // Small delay to ensure sign out is complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Sign in with account selection
      return await signInWithGoogle();
    } catch (e) {
      AppLogger.error('AuthService: Switch Google account failed', e);
      throw Exception('Failed to switch Google account: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    AppLogger.info('AuthService: Attempting sign out');
    
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      AppLogger.info('AuthService: Sign out successful');
      AppLogger.serviceOperation('AuthService', 'signOut', true);
    } catch (e) {
      AppLogger.error('AuthService: Sign out failed', e);
      AppLogger.serviceOperation('AuthService', 'signOut', false);
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    AppLogger.info('AuthService: Sending password reset email');
    
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      
      AppLogger.info('AuthService: Password reset email sent successfully');
      AppLogger.serviceOperation('AuthService', 'sendPasswordResetEmail', true);
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('AuthService: Password reset failed', e);
      AppLogger.serviceOperation('AuthService', 'sendPasswordResetEmail', false);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('AuthService: Unexpected password reset error', e);
      AppLogger.serviceOperation('AuthService', 'sendPasswordResetEmail', false);
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions with user-friendly messages
  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email address.');
      case 'wrong-password':
        return Exception('Incorrect password.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email.');
      case 'weak-password':
        return Exception('Password is too weak. Please choose a stronger password.');
      case 'invalid-email':
        return Exception('Invalid email address.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please try again later.');
      case 'operation-not-allowed':
        return Exception('This sign-in method is not enabled.');
      case 'invalid-credential':
        return Exception('Invalid credentials provided.');
      case 'account-exists-with-different-credential':
        return Exception('An account already exists with the same email but different sign-in credentials.');
      case 'requires-recent-login':
        return Exception('This operation requires recent authentication. Please sign in again.');
      default:
        return Exception('Authentication failed: ${e.message ?? e.code}');
    }
  }
}