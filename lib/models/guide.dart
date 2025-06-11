import 'package:cloud_firestore/cloud_firestore.dart';
import 'available_time.dart'; // Import the standardized AvailableTime model

class Guide {
  final String userId;
  final String? bio;
  final List<String> languages;
  final bool isAvailable;
  final List<AvailableTime> availability;

  Guide({
    required this.userId,
    this.bio,
    required this.languages,
    required this.isAvailable,
    this.availability = const [],
  });

  String get id => userId;

  factory Guide.fromMap(Map<String, dynamic> map) {
    return Guide(
      userId: map['userId'] as String,
      bio: map['bio'] as String?,
      languages: List<String>.from(map['languages'] ?? []),
      isAvailable: map['isAvailable'] as bool? ?? true,
      availability: map['availability'] != null
          ? (map['availability'] as List<dynamic>)
              .map((availMap) => AvailableTime.fromMap(
                  availMap as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  // Add Firestore factory constructor
  factory Guide.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Guide.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bio': bio,
      'languages': languages,
      'isAvailable': isAvailable,
      'availability': availability.map((time) => time.toMap()).toList(),
    };
  }

  // Add Firestore method
  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  // Add copyWith method
  Guide copyWith({
    String? userId,
    String? bio,
    List<String>? languages,
    bool? isAvailable,
    List<AvailableTime>? availability,
  }) {
    return Guide(
      userId: userId ?? this.userId,
      bio: bio ?? this.bio,
      languages: languages ?? this.languages,
      isAvailable: isAvailable ?? this.isAvailable,
      availability: availability ?? this.availability,
    );
  }
}