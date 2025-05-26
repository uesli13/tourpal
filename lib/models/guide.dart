import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Guide extends Equatable {
  final String id;
  final String userId; // Reference to User document
  final String name;
  final String email;
  final String? profileImageUrl;
  final String bio;
  final List<String> specializations; // e.g., ['Adventure', 'Cultural', 'Food']
  final List<String> languages;
  final String location; // City/Region where guide operates
  final double latitude;
  final double longitude;
  final double averageRating;
  final int totalReviews;
  final int totalTours;
  final int yearsOfExperience;
  final String phoneNumber;
  final bool isVerified;
  final bool isAvailable;
  final double pricePerHour; // in USD
  final GuideStatus status;
  final List<String> certifications;
  final Map<String, dynamic> socialMedia; // {'instagram': '@guide', 'facebook': 'page'}
  final String? aboutMe;
  final List<String> tourPlanIds; // Tours created by this guide
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActiveAt;
  
  const Guide({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.bio,
    required this.specializations,
    required this.languages,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalTours = 0,
    this.yearsOfExperience = 0,
    required this.phoneNumber,
    this.isVerified = false,
    this.isAvailable = true,
    this.pricePerHour = 0.0,
    this.status = GuideStatus.pending,
    this.certifications = const [],
    this.socialMedia = const {},
    this.aboutMe,
    this.tourPlanIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveAt,
  });

  // ✅ GOOD: Factory constructor from Firestore
  factory Guide.fromMap(Map<String, dynamic> map, String documentId) {
    return Guide(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'] ?? '',
      specializations: List<String>.from(map['specializations'] ?? []),
      languages: List<String>.from(map['languages'] ?? []),
      location: map['location'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      totalTours: map['totalTours'] ?? 0,
      yearsOfExperience: map['yearsOfExperience'] ?? 0,
      phoneNumber: map['phoneNumber'] ?? '',
      isVerified: map['isVerified'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      pricePerHour: (map['pricePerHour'] ?? 0.0).toDouble(),
      status: GuideStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => GuideStatus.pending,
      ),
      certifications: List<String>.from(map['certifications'] ?? []),
      socialMedia: Map<String, dynamic>.from(map['socialMedia'] ?? {}),
      aboutMe: map['aboutMe'],
      tourPlanIds: List<String>.from(map['tourPlanIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastActiveAt: map['lastActiveAt'] != null 
          ? (map['lastActiveAt'] as Timestamp).toDate()
          : null,
    );
  }

  // ✅ GOOD: Factory constructor from Firestore DocumentSnapshot
  factory Guide.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Guide.fromMap(data, doc.id);
  }

  // ✅ GOOD: Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'specializations': specializations,
      'languages': languages,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'totalTours': totalTours,
      'yearsOfExperience': yearsOfExperience,
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'pricePerHour': pricePerHour,
      'status': status.name,
      'certifications': certifications,
      'socialMedia': socialMedia,
      'aboutMe': aboutMe,
      'tourPlanIds': tourPlanIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }

  // ✅ GOOD: CopyWith method for immutable updates
  Guide copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? profileImageUrl,
    String? bio,
    List<String>? specializations,
    List<String>? languages,
    String? location,
    double? latitude,
    double? longitude,
    double? averageRating,
    int? totalReviews,
    int? totalTours,
    int? yearsOfExperience,
    String? phoneNumber,
    bool? isVerified,
    bool? isAvailable,
    double? pricePerHour,
    GuideStatus? status,
    List<String>? certifications,
    Map<String, dynamic>? socialMedia,
    String? aboutMe,
    List<String>? tourPlanIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
  }) {
    return Guide(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      specializations: specializations ?? this.specializations,
      languages: languages ?? this.languages,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalTours: totalTours ?? this.totalTours,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      status: status ?? this.status,
      certifications: certifications ?? this.certifications,
      socialMedia: socialMedia ?? this.socialMedia,
      aboutMe: aboutMe ?? this.aboutMe,
      tourPlanIds: tourPlanIds ?? this.tourPlanIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  // ✅ GOOD: Business logic helpers
  bool get hasProfileImage => profileImageUrl != null && profileImageUrl!.isNotEmpty;
  
  bool get isActive => isAvailable && status == GuideStatus.approved;
  
  bool get hasGoodRating => averageRating >= 4.0 && totalReviews >= 5;
  
  bool get isExperienced => yearsOfExperience >= 2;
  
  String get displayRating => averageRating.toStringAsFixed(1);
  
  String get displayPrice => '\$${pricePerHour.toStringAsFixed(0)}/hour';
  
  String get experienceText {
    if (yearsOfExperience == 0) return 'New guide';
    if (yearsOfExperience == 1) return '1 year experience';
    return '$yearsOfExperience years experience';
  }
  
  String get reviewsText {
    if (totalReviews == 0) return 'No reviews yet';
    if (totalReviews == 1) return '1 review';
    return '$totalReviews reviews';
  }
  
  String get toursText {
    if (totalTours == 0) return 'No tours yet';
    if (totalTours == 1) return '1 tour';
    return '$totalTours tours';
  }
  
  String get statusDisplayName => status.displayName;
  
  String get availabilityText => isAvailable ? 'Available' : 'Unavailable';
  
  List<String> get primarySpecializations => specializations.take(3).toList();
  
  bool get hasAboutMe => aboutMe != null && aboutMe!.trim().isNotEmpty;
  
  bool get hasCertifications => certifications.isNotEmpty;
  
  bool get hasSocialMedia => socialMedia.isNotEmpty;
  
  // ✅ GOOD: Calculate distance from coordinates
  double calculateDistance(double userLat, double userLng) {
    // Haversine formula implementation
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(userLat - latitude);
    final double dLng = _degreesToRadians(userLng - longitude);
    
    final double a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        latitude.degreesToRadians().cos() * userLat.degreesToRadians().cos() *
        (dLng / 2).sin() * (dLng / 2).sin();
    
    final double c = 2 * a.sqrt().asin();
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
  
  String getDistanceText(double userLat, double userLng) {
    final distance = calculateDistance(userLat, userLng);
    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    }
    return '${distance.toStringAsFixed(1)}km away';
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    email,
    profileImageUrl,
    bio,
    specializations,
    languages,
    location,
    latitude,
    longitude,
    averageRating,
    totalReviews,
    totalTours,
    yearsOfExperience,
    phoneNumber,
    isVerified,
    isAvailable,
    pricePerHour,
    status,
    certifications,
    socialMedia,
    aboutMe,
    tourPlanIds,
    createdAt,
    updatedAt,
    lastActiveAt,
  ];

  @override
  String toString() {
    return 'Guide(id: $id, name: $name, email: $email, location: $location, '
           'rating: $averageRating, tours: $totalTours, status: ${status.name})';
  }
}

// ✅ GOOD: Guide status enum
enum GuideStatus {
  pending,
  approved,
  rejected,
  suspended,
  inactive,
}

extension GuideStatusExtension on GuideStatus {
  String get displayName {
    switch (this) {
      case GuideStatus.pending:
        return 'Pending Approval';
      case GuideStatus.approved:
        return 'Approved';
      case GuideStatus.rejected:
        return 'Rejected';
      case GuideStatus.suspended:
        return 'Suspended';
      case GuideStatus.inactive:
        return 'Inactive';
    }
  }
  
  bool get isActive => this == GuideStatus.approved;
  
  bool get canCreateTours => this == GuideStatus.approved;
  
  bool get needsApproval => this == GuideStatus.pending;
}

// ✅ GOOD: Helper extension for double
extension on double {
  double degreesToRadians() => this * (3.14159265359 / 180);
}

extension on num {
  double sin() => math.sin(toDouble());
  double cos() => math.cos(toDouble());
  double asin() => math.asin(toDouble());
  double sqrt() => math.sqrt(toDouble());
}
