import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../models/user.dart';

/// Data layer model for User that handles Firebase conversions
/// Extends the domain User model and adds Firebase-specific functionality
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.bio,
    super.profileImageUrl,
    required super.createdAt,
    super.birthdate,
    super.favoriteTours,
    super.bookedTours,
    super.completedTours,
    super.isGuide = false,
    super.isAvailable = true,
    super.languages = const [],
  });

  /// Create UserModel from Firebase Auth User
  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      profileImageUrl: firebaseUser.photoURL,
      createdAt: Timestamp.fromDate(firebaseUser.metadata.creationTime ?? DateTime.now()),
      isGuide: false,
    );
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  /// Create UserModel from Map with document ID
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      bio: map['bio'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      birthdate: map['birthdate'] as Timestamp?,
      favoriteTours: map['favoriteTours'] != null 
          ? List<String>.from(map['favoriteTours'])
          : null,
      bookedTours: map['bookedTours'] != null 
          ? List<String>.from(map['bookedTours'])
          : null,
      completedTours: map['completedTours'] != null 
          ? List<String>.from(map['completedTours'])
          : null,
      isGuide: map['isGuide'] as bool? ?? false,
      isAvailable: map['isAvailable'] as bool? ?? true,
      languages: map['languages'] != null 
          ? List<String>.from(map['languages'])
          : const [],
    );
  }

  /// Convert UserModel to Map for Firestore
  @override
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
      'birthdate': birthdate,
      'favoriteTours': favoriteTours,
      'bookedTours': bookedTours,
      'completedTours': completedTours,
      'isGuide': isGuide,
      'isAvailable': isAvailable,
      'languages': languages,
    };
  }

  /// Convert to domain User model (in this case, it's the same)
  User toDomain() {
    return User(
      id: id,
      email: email,
      name: name,
      bio: bio,
      profileImageUrl: profileImageUrl,
      createdAt: createdAt,
      birthdate: birthdate,
      favoriteTours: favoriteTours,
      bookedTours: bookedTours,
      completedTours: completedTours,
      isGuide: isGuide,
      isAvailable: isAvailable,
      languages: languages,
    );
  }

  /// Create UserModel from domain User
  factory UserModel.fromDomain(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      bio: user.bio,
      profileImageUrl: user.profileImageUrl,
      createdAt: user.createdAt,
      birthdate: user.birthdate,
      favoriteTours: user.favoriteTours,
      bookedTours: user.bookedTours,
      completedTours: user.completedTours,
      isGuide: user.isGuide,
      isAvailable: user.isAvailable,
      languages: user.languages,
    );
  }

  @override
  UserModel copyWith({
    String? email,
    String? name,
    String? bio,
    String? profileImageUrl,
    Timestamp? birthdate,
    List<String>? favoriteTours,
    List<String>? bookedTours,
    List<String>? completedTours,
    bool? isGuide,
    bool? isAvailable,
    List<String>? languages,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      birthdate: birthdate ?? this.birthdate,
      favoriteTours: favoriteTours ?? this.favoriteTours,
      bookedTours: bookedTours ?? this.bookedTours,
      completedTours: completedTours ?? this.completedTours,
      isGuide: isGuide ?? this.isGuide,
      isAvailable: isAvailable ?? this.isAvailable,
      languages: languages ?? this.languages,
    );
  }
}