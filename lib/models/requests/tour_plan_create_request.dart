import 'package:equatable/equatable.dart';
import 'package:tourpal/features/tours/domain/enums/tour_category.dart';
import 'package:tourpal/features/tours/domain/enums/tour_difficulty.dart';
import '../tour_plan.dart';

/// Request model for creating a new TourPlan following BLoC architecture rules
class TourPlanCreateRequest extends Equatable {
  final String title;
  final String description;
  final String guideId;
  final int duration; // in minutes
  final String difficulty;
  final List<String> tags;
  final bool isPublic;
  final String? imageUrl;
  final double? startLatitude;
  final double? startLongitude;
  final String? startAddress;

  const TourPlanCreateRequest({
    required this.title,
    required this.description,
    required this.guideId,
    required this.duration,
    required this.difficulty,
    this.tags = const [],
    this.isPublic = true,
    this.imageUrl,
    this.startLatitude,
    this.startLongitude,
    this.startAddress,
  });

  /// Convert to TourPlan domain model - required by service layer
  TourPlan toTourPlan(String id) {
    return TourPlan(
      id: id,
      title: title.trim(),
      description: description.trim(),
      guideId: guideId,
      duration: duration,
      difficulty: difficulty.toLowerCase(),
      tags: tags,
      isPublic: isPublic,
      imageUrl: imageUrl,
      averageRating: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalReviews: 0,
      bookingCount: 0,
      favoriteCount: 0,
    );
  }

  /// Create a copy with modified fields
  TourPlanCreateRequest copyWith({
    String? title,
    String? description,
    String? guideId,
    int? duration,
    String? difficulty,
    List<String>? tags,
    bool? isPublic,
    String? imageUrl,
    double? startLatitude,
    double? startLongitude,
    String? startAddress,
  }) {
    return TourPlanCreateRequest(
      title: title ?? this.title,
      description: description ?? this.description,
      guideId: guideId ?? this.guideId,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      imageUrl: imageUrl ?? this.imageUrl,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      startAddress: startAddress ?? this.startAddress,
    );
  }

  @override
  List<Object?> get props => [
    title,
    description,
    guideId,
    duration,
    difficulty,
    tags,
    isPublic,
    imageUrl,
    startLatitude,
    startLongitude,
    startAddress,
  ];

  @override
  String toString() {
    return 'TourPlanCreateRequest{title: $title, difficulty: $difficulty, duration: $duration}';
  }
}

extension TourCategoryExtension on TourCategory {
  String get displayName {
    switch (this) {
      case TourCategory.cultural:
        return 'Cultural';
      case TourCategory.adventure:
        return 'Adventure';
      case TourCategory.nature:
        return 'Nature';
      case TourCategory.food:
        return 'Food & Drink';
      case TourCategory.historical:
        return 'Art & Museums';
      case TourCategory.nightlife:
        return 'Nightlife';
      case TourCategory.shopping:
        return 'Shopping';
      case TourCategory.sports:
        return 'Sports';
      case TourCategory.urban:
        return 'Urban';
      case TourCategory.beach:
        return 'Beach';
      case TourCategory.mountain:
        return 'Mountain';
      case TourCategory.religious:
        return 'Religious';
      case TourCategory.photography:
        return 'Photography';
      case TourCategory.educational:
        return 'Educational';
      case TourCategory.family:
        return 'Family';
      case TourCategory.romantic:
        return 'Romantic';
      case TourCategory.luxury:
        return 'Luxury';
      case TourCategory.budget:
        return 'Budget';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'display_name': displayName,
    };
  }
}

extension TourDifficultyExtension on TourDifficulty {
  String get displayName {
    switch (this) {
      case TourDifficulty.easy:
        return 'Easy';
      case TourDifficulty.moderate:
        return 'Moderate';
      case TourDifficulty.challenging:
        return 'Challenging';
      case TourDifficulty.difficult:
        return 'Difficult';
      case TourDifficulty.extreme:
        return 'Extreme';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'display_name': displayName,
    };
  }
}