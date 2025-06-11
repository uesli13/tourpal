import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../models/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.bio,
    super.profileImageUrl,
    super.birthdate,
    super.isGuide = false,
    super.isAvailable = true,
    super.languages = const [],
    super.favoriteTours,
    super.bookedTours,
    super.completedTours,
    required super.createdAt,
  });

  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      profileImageUrl: firebaseUser.photoURL,
      createdAt: Timestamp.fromDate(firebaseUser.metadata.creationTime ?? DateTime.now()),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] as String,
      name: map['name'] as String,
      bio: map['bio'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      birthdate: map['birthdate'] as Timestamp?,
      isGuide: map['isGuide'] as bool? ?? false,
      isAvailable: map['isAvailable'] as bool? ?? true,
      languages: map['languages'] != null 
          ? List<String>.from(map['languages'])
          : const [],
      favoriteTours: map['favoriteTours'] != null 
          ? List<String>.from(map['favoriteTours'])
          : null,
      bookedTours: map['bookedTours'] != null 
          ? List<String>.from(map['bookedTours'])
          : null,
      completedTours: map['completedTours'] != null 
          ? List<String>.from(map['completedTours'])
          : null,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'birthdate': birthdate,
      'isGuide': isGuide,
      'isAvailable': isAvailable,
      'languages': languages,
      'favoriteTours': favoriteTours,
      'bookedTours': bookedTours,
      'completedTours': completedTours,
      'createdAt': createdAt,
    };
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
      birthdate: birthdate ?? this.birthdate,
      favoriteTours: favoriteTours ?? this.favoriteTours,
      bookedTours: bookedTours ?? this.bookedTours,
      completedTours: completedTours ?? this.completedTours,
      isGuide: isGuide ?? this.isGuide,
      isAvailable: isAvailable ?? this.isAvailable,
      languages: languages ?? this.languages,
      createdAt: createdAt,
    );
  }
}