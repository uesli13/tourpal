import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final String? profileImageUrl;
  final Timestamp createdAt;
  final Timestamp? birthdate;
  final List<String>? favoriteTours;
  final List<String>? bookedTours;
  final List<String>? completedTours;
  final bool isGuide;
  final bool isAvailable;
  final List<String> languages;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.profileImageUrl,
    required this.createdAt,
    this.birthdate,
    this.favoriteTours,
    this.bookedTours,
    this.completedTours,
    this.isGuide = false,
    this.isAvailable = true,
    this.languages = const [],
  });

  factory User.fromMap(Map<String, dynamic> map, String documentId) {
    return User(
      id: documentId,
      email: map['email'] as String,
      name: map['name'] as String,
      bio: map['bio'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: map['createdAt'] as Timestamp,
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

  User copyWith({
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
    return User(
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

  // Helper methods for business logic
  bool get hasCompletedProfile => 
      bio != null && bio!.isNotEmpty && birthdate != null;
  
  String get displayName => name.isNotEmpty ? name : email.split('@').first;
  
  bool get hasProfileImage => 
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  DateTime? get birthdateAsDateTime => birthdate?.toDate();
  
  DateTime get createdAtAsDateTime => createdAt.toDate();
  
  int? get age {
    if (birthdate == null) return null;
    final now = DateTime.now();
    final birthDate = birthdate!.toDate();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Safe getters for optional lists
  List<String> get safenessFavoriteTours => favoriteTours ?? [];
  List<String> get safenessBookedTours => bookedTours ?? [];
  List<String> get safenessCompletedTours => completedTours ?? [];

  // Validation helpers
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (email.isEmpty || !email.contains('@')) {
      errors.add('Please enter a valid email address');
    }
    
    if (name.trim().length < 2) {
      errors.add('Name must be at least 2 characters long');
    }
    
    if (bio != null && bio!.trim().isNotEmpty && bio!.trim().length < 10) {
      errors.add('Bio must be at least 10 characters long');
    }
    
    // Only validate birthdate if provided
    if (birthdate != null) {
      final userAge = age;
      if (userAge != null && userAge < 18) {
        errors.add('You must be at least 18 years old');
      }
      if (userAge != null && userAge > 120) {
        errors.add('Please enter a valid birthdate');
      }
    }
    
    return errors;
  }
  
  bool get isValidForProfile => validationErrors.isEmpty;

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    bio,
    profileImageUrl,
    createdAt,
    birthdate,
    favoriteTours,
    bookedTours,
    completedTours,
    isGuide,
    isAvailable,
    languages,
  ];

  @override
  String toString() {
    return 'User{id: $id, email: $email, name: $name, isGuide: $isGuide, isAvailable: $isAvailable, languages: $languages}';
  }
}