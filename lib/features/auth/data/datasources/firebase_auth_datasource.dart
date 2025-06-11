import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/user.dart' as app_user;
import '../../../../core/utils/logger.dart';

class FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  FirebaseAuthDataSource(this._firebaseAuth, this._googleSignIn, this._firestore);

  Future<app_user.User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    // Use retry logic to handle potential race conditions when loading profile
    const maxRetries = 2;
    const retryDelay = Duration(milliseconds: 300);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Get user data from Firestore
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!userDoc.exists) {
          if (attempt == maxRetries) {
            AppLogger.warning('User profile document not found after $maxRetries attempts', firebaseUser.uid);
            return null;
          }
          await Future.delayed(retryDelay);
          continue;
        }

        return app_user.User.fromMap(userDoc.data()!, firebaseUser.uid);
      } catch (e) {
        AppLogger.error('Error loading current user profile (attempt $attempt)', e);
        
        if (attempt == maxRetries) {
          AppLogger.error('Failed to load current user after $maxRetries attempts');
          return null;
        }
        
        await Future.delayed(retryDelay);
      }
    }
    
    return null;
  }

  Future<app_user.User> signInWithEmailAndPassword(String email, String password) async {
    AppLogger.info('🔐 FirebaseAuthDataSource: Signing in with email');
    
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) {
      throw Exception('Sign in failed - no user returned');
    }

    // Get user data from Firestore
    final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
    if (!userDoc.exists) {
      throw Exception('User profile not found');
    }

    return app_user.User.fromMap(userDoc.data()!, credential.user!.uid);
  }

  Future<app_user.User> signUpWithEmailAndPassword(String email, String password, String name) async {
    AppLogger.info('📝 FirebaseAuthDataSource: Creating new account');
    
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) {
      throw Exception('Sign up failed - no user returned');
    }

    // Create user profile in Firestore
    final newUser = app_user.User(
      id: credential.user!.uid,
      email: email,
      name: name,
      createdAt: Timestamp.now(),
      isGuide: false,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set(newUser.toMap());

    return newUser;
  }

  Future<app_user.User> signInWithGoogle() async {
    AppLogger.info('🔍 FirebaseAuthDataSource: Signing in with Google');
    
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign in cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final authResult = await _firebaseAuth.signInWithCredential(credential);
    if (authResult.user == null) {
      throw Exception('Google sign in failed');
    }

    final firebaseUser = authResult.user!;
    
    // Use retry logic to handle potential race conditions with Firestore
    return await _getOrCreateUserProfile(firebaseUser, googleUser);
  }

  /// Get existing user profile or create new one with retry logic for race conditions
  Future<app_user.User> _getOrCreateUserProfile(
    firebase_auth.User firebaseUser, 
    GoogleSignInAccount googleUser,
  ) async {
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 500);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.info('Attempting to load user profile (attempt $attempt/$maxRetries)');
        
        // Check if user profile exists in Firestore
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        
        if (userDoc.exists) {
          // Existing user - return profile
          final userData = userDoc.data()!;
          AppLogger.info('Found existing user profile for Google sign-in');
          return app_user.User.fromMap(userData, firebaseUser.uid);
        } else if (attempt == maxRetries) {
          // Last attempt - create new user profile
          AppLogger.info('Creating new user profile for Google sign-in');
          return await _createNewGoogleUserProfile(firebaseUser, googleUser);
        } else {
          // Profile doesn't exist yet, but we're not on the last attempt
          // Wait and retry (document might still be propagating)
          AppLogger.info('User profile not found, retrying in ${retryDelay.inMilliseconds}ms...');
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        AppLogger.error('Error during profile loading attempt $attempt', e);
        
        if (attempt == maxRetries) {
          throw Exception('Failed to load or create user profile after $maxRetries attempts: ${e.toString()}');
        }
        
        // Wait before retrying
        await Future.delayed(retryDelay);
      }
    }
    
    throw Exception('Failed to load user profile');
  }

  /// Create new user profile for Google sign-in with enhanced data
  Future<app_user.User> _createNewGoogleUserProfile(
    firebase_auth.User firebaseUser,
    GoogleSignInAccount googleUser,
  ) async {
    final now = Timestamp.now();
    
    // Extract enhanced profile data from Google account (consistent with AuthService)
    final displayName = firebaseUser.displayName ?? 
                       googleUser.displayName ?? 
                       firebaseUser.email?.split('@').first ?? 
                       'User';
    
    // Optimize profile image URL for higher resolution
    String? profileImageUrl;
    if (firebaseUser.photoURL != null) {
      profileImageUrl = _getHighResolutionPhotoUrl(firebaseUser.photoURL!);
      AppLogger.info('Importing Google profile photo for new user');
    }
    
    final newUser = app_user.User(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      name: displayName,
      bio: null, // Will be set during profile setup
      profileImageUrl: profileImageUrl,
      birthdate: null, // Will be set during profile setup
      createdAt: now,
      isGuide: false,
      favoriteTours: [],
      bookedTours: [],
      completedTours: [],
    );

    AppLogger.info('Creating new Google user profile with enhanced data');
    await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
    
    return newUser;
  }

  /// Optimize Google profile photo URL for higher resolution
  String _getHighResolutionPhotoUrl(String originalUrl) {
    try {
      // Google profile photos can be resized by modifying the size parameter
      if (originalUrl.contains('googleusercontent.com')) {
        return originalUrl.replaceAll(RegExp(r's\d+-c'), 's400-c');
      }
      return originalUrl;
    } catch (e) {
      AppLogger.warning('Failed to optimize Google profile photo URL', e);
      return originalUrl;
    }
  }

  Future<void> signOut() async {
    AppLogger.info('👋 FirebaseAuthDataSource: Signing out');
    
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    AppLogger.info('📧 FirebaseAuthDataSource: Sending password reset email');
    
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Stream<app_user.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!userDoc.exists) return null;

        return app_user.User.fromMap(userDoc.data()!, firebaseUser.uid);
      } catch (e) {
        AppLogger.error('Error getting user from auth state change', e);
        return null;
      }
    });
  }
}