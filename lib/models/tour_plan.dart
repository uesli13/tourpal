import 'package:cloud_firestore/cloud_firestore.dart';
import 'place.dart';
import '../core/services/tour_duration_calculator.dart';

class TourPlan {
  final String id;
  final String guideId;
  final String title;
  final String? description;
  final num duration;
  final String difficulty;
  final num price;
  final List<String>? tags;
  final String category;
  final String location;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final num? averageRating;
  final int reviewCount;
  final TourStatus status;
  final List<Place> places;
  final String? coverImageUrl;

  TourPlan({
    required this.id,
    required this.guideId,
    required this.title,
    this.description,
    required this.duration,
    required this.difficulty,
    required this.price,
    this.tags,
    required this.category,
    required this.location,
    required this.createdAt,
    this.updatedAt,
    this.averageRating,
    this.reviewCount = 0,
    required this.status,
    this.places = const [],
    this.coverImageUrl,
  });

  String get guideName => 'Guide'; // Placeholder - would need proper user lookup

  factory TourPlan.fromMap(Map<String, dynamic> map, String documentId) {
    return TourPlan(
      id: documentId,
      guideId: map['guideId'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      duration: map['duration'] as num,
      difficulty: map['difficulty'] as String,
      price: map['price'] as num,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      createdAt: map['createdAt'] as Timestamp,
      updatedAt: map['updatedAt'] as Timestamp?,
      averageRating: map['averageRating'] as num?,
      reviewCount: map['reviewCount'] as int? ?? 0,
      status: TourStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TourStatus.draft,
      ),
      places: map['places'] != null 
          ? (map['places'] as List).asMap().entries.map((entry) => 
              Place.fromMap(entry.value as Map<String, dynamic>, entry.key.toString())
            ).toList()
          : [],
      coverImageUrl: map['coverImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guideId': guideId,
      'title': title,
      'description': description,
      'duration': duration,
      'difficulty': difficulty,
      'price': price,
      'tags': tags,
      'category': category,
      'location': location,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'status': status.toString().split('.').last,
      'places': places.map((p) => p.toMap()).toList(),
      'coverImageUrl': coverImageUrl,
    };
  }

  TourPlan copyWith({
    String? id,
    String? guideId,
    String? title,
    String? description,
    num? duration,
    String? difficulty,
    num? price,
    List<String>? tags,
    String? category,
    String? location,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    num? averageRating,
    int? reviewCount,
    TourStatus? status,
    List<Place>? places,
    String? coverImageUrl,
  }) {
    return TourPlan(
      id: id ?? this.id,
      guideId: guideId ?? this.guideId,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      price: price ?? this.price,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? Timestamp.now(),
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      status: status ?? this.status,
      places: places ?? this.places,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  /// Calculate the total duration automatically based on walking time + staying time
  Future<double> calculateAutomaticDuration() async {
    return await TourDurationCalculator.calculateTotalDuration(places);
  }

  /// Get detailed breakdown of tour duration components
  Future<Map<String, dynamic>> getDurationBreakdown() async {
    return await TourDurationCalculator.getDurationBreakdown(places);
  }

  /// Create a copy with automatically calculated duration
  Future<TourPlan> copyWithCalculatedDuration({
    String? id,
    String? guideId,
    String? title,
    String? description,
    String? difficulty,
    num? price,
    List<String>? tags,
    String? category,
    String? location,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    num? averageRating,
    int? reviewCount,
    TourStatus? status,
    List<Place>? places,
    String? coverImageUrl,
  }) async {
    final updatedPlaces = places ?? this.places;
    final calculatedDuration = await TourDurationCalculator.calculateTotalDuration(updatedPlaces);
    
    return TourPlan(
      id: id ?? this.id,
      guideId: guideId ?? this.guideId,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: calculatedDuration,
      difficulty: difficulty ?? this.difficulty,
      price: price ?? this.price,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? Timestamp.now(),
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      status: status ?? this.status,
      places: updatedPlaces,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  /// Check if tour has minimum required places (2 or more)
  bool get hasMinimumPlaces => places.length >= 2;

  /// Check if tour is ready to be published
  bool get isReadyToPublish =>
      hasMinimumPlaces &&
      title.isNotEmpty &&
      description != null &&
      description!.isNotEmpty;

  /// Check if tour is a draft
  bool get isDraft => status == TourStatus.draft;

  // Helper methods for image management
  bool get hasCoverImage => coverImageUrl != null && coverImageUrl!.isNotEmpty;
}

enum TourStatus {
  draft('draft', 'Draft', '✏️'),
  published('published', 'Published', '🌟');

  const TourStatus(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static TourStatus fromString(String value) {
    for (TourStatus status in TourStatus.values) {
      if (status.value == value) {
        return status;
      }
    }
    return TourStatus.draft; // Default fallback
  }

  bool get isPublished => this == TourStatus.published;
  bool get isDraft => this == TourStatus.draft;

  String get description {
    switch (this) {
      case TourStatus.draft:
        return 'Tour is being created and not visible to travelers';
      case TourStatus.published:
        return 'Tour is published and available for booking';
    }
  }
}