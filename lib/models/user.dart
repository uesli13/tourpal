import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final String? profileImageUrl;
  final DateTime? birthdate;
  final bool isGuide;
  final List<String> favoriteTours;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.profileImageUrl,
    this.birthdate,
    required this.isGuide,
    required this.favoriteTours,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      email: map['email'] as String,
      name: map['name'] as String,
      bio: map['bio'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      birthdate: map['birthdate'] != null 
          ? (map['birthdate'] as Timestamp).toDate()
          : null,
      isGuide: map['isGuide'] as bool? ?? false,
      favoriteTours: List<String>.from(map['favoriteTours'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
      'isGuide': isGuide,
      'favoriteTours': favoriteTours,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  User copyWith({
    String? email,
    String? name,
    String? bio,
    String? profileImageUrl,
    DateTime? birthdate,
    bool? isGuide,
    List<String>? favoriteTours,
    DateTime? updatedAt,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      birthdate: birthdate ?? this.birthdate,
      isGuide: isGuide ?? this.isGuide,
      favoriteTours: favoriteTours ?? this.favoriteTours,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasCompletedProfile => bio != null && birthdate != null;

  // BLoC-compatible property names
  bool get needsProfileSetup => !hasCompletedProfile;
  String? get profilePhoto => profileImageUrl;
  
  int get age {
    if (birthdate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthdate!.year;
    if (now.month < birthdate!.month || 
        (now.month == birthdate!.month && now.day < birthdate!.day)) {
      age--;
    }
    return age;
  }

  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    bio,
    profileImageUrl,
    birthdate,
    isGuide,
    favoriteTours,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'User{id: $id, email: $email, name: $name, isGuide: $isGuide}';
  }
}