import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/logger.dart';
import '../../../core/exceptions/app_exceptions.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Force account selection every time by not storing the signed-in state
    forceCodeForRefreshToken: true,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;
  
  /// Current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.auth('Attempting email sign in', email);
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      AppLogger.auth('Email sign in successful', credential.user?.uid);
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase auth error during sign in', e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('Unexpected error during sign in', e);
      throw AuthenticationException('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      AppLogger.auth('Attempting email sign up', email);
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName.trim());
        
        // Create user document in Firestore
        await _createUserDocument(credential.user!, displayName.trim());
        
        AppLogger.auth('Email sign up successful', credential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase auth error during sign up', e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('Unexpected error during sign up', e);
      throw AuthenticationException('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign in with Google with forced account selection
  Future<void> signInWithGoogle() async {
    try {
      AppLogger.auth('Attempting Google sign in with account selection');
      
      // Force complete sign out to ensure account picker appears
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthenticationException('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        AppLogger.auth('Google sign in successful', userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase auth error during Google sign in', e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('Unexpected error during Google sign in', e);
      throw AuthenticationException('Google sign in failed: ${e.toString()}');
    }
  }

  /// Switch Google account with forced account picker
  Future<void> switchGoogleAccount() async {
    try {
      AppLogger.auth('Switching Google account with forced account selection');
      
      // Complete disconnect to ensure fresh account selection
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
      
      // Sign in again - this will always show the account picker
      await signInWithGoogle();
    } catch (e) {
      AppLogger.error('Error switching Google account', e);
      throw AuthenticationException('Failed to switch Google account: ${e.toString()}');
    }
  }

  /// Force Google account selection (for UI buttons)
  Future<void> signInWithGoogleAccountSelection() async {
    try {
      AppLogger.auth('Forcing Google account selection');
      
      // Always disconnect completely before showing account picker
      await _googleSignIn.disconnect();
      await signInWithGoogle();
    } catch (e) {
      AppLogger.error('Error during forced Google account selection', e);
      throw AuthenticationException('Google account selection failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      AppLogger.auth('Signing out');
      
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      AppLogger.auth('Sign out successful');
    } catch (e) {
      AppLogger.error('Error during sign out', e);
      throw AuthenticationException('Sign out failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AppLogger.auth('Sending password reset email', email);
      
      await _auth.sendPasswordResetEmail(email: email.trim());
      
      AppLogger.auth('Password reset email sent', email);
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase auth error sending password reset', e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('Unexpected error sending password reset', e);
      throw AuthenticationException('Failed to send password reset email: ${e.toString()}');
    }
  }

  /// Create user document in Firestore with enhanced profile data
  /// 
  /// Creates a comprehensive user profile document with imported data from
  /// the authentication provider. For Google sign-ups, this includes profile
  /// photos and any available birthdate information.
  Future<void> _createUserDocument(User firebaseUser, String displayName, {
    String? importedProfileImageUrl,
    Timestamp? importedBirthdate,
  }) async {
    final now = DateTime.now();
    
    // Prepare user data with priority: imported data > Firebase data > defaults
    final userData = {
      'email': firebaseUser.email,
      'name': displayName,
      'bio': null,
      'profileImageUrl': importedProfileImageUrl ?? firebaseUser.photoURL,
      'birthdate': importedBirthdate, // Use imported birthdate if available
      'isGuide': false,
      'favoriteTours': <String>[],
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    AppLogger.database('Creating user document with imported profile data', 'users', firebaseUser.uid);
    
    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(userData);
  }

  /// Handle Firebase Auth exceptions
  AuthenticationException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthenticationException('No user found with this email address');
      case 'wrong-password':
        return const AuthenticationException('Incorrect password');
      case 'email-already-in-use':
        return const AuthenticationException('An account already exists with this email');
      case 'weak-password':
        return const AuthenticationException('Password is too weak');
      case 'invalid-email':
        return const AuthenticationException('Invalid email address');
      case 'user-disabled':
        return const AuthenticationException('This account has been disabled');
      case 'too-many-requests':
        return const AuthenticationException('Too many attempts. Please try again later');
      case 'network-request-failed':
        return const AuthenticationException('Network error. Please check your connection');
      default:
        return AuthenticationException('Authentication failed: ${e.message}');
    }
  }
}