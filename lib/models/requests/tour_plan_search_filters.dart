import 'package:equatable/equatable.dart';

/// Search filters for TourPlan queries following BLoC architecture rules
class TourPlanSearchFilters extends Equatable {
  final String? query;
  final String? difficulty;
  final int? minDuration;
  final int? maxDuration;
  final double? minRating;
  final List<String>? tags;
  final bool? isPublic;
  final String? guideId;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;

  const TourPlanSearchFilters({
    this.query,
    this.difficulty,
    this.minDuration,
    this.maxDuration,
    this.minRating,
    this.tags,
    this.isPublic,
    this.guideId,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  /// Check if any filters are applied
  bool get hasFilters =>
      query != null ||
      difficulty != null ||
      minDuration != null ||
      maxDuration != null ||
      minRating != null ||
      (tags != null && tags!.isNotEmpty) ||
      isPublic != null ||
      guideId != null ||
      (latitude != null && longitude != null);

  /// Create a copy with modified fields
  TourPlanSearchFilters copyWith({
    String? query,
    String? difficulty,
    int? minDuration,
    int? maxDuration,
    double? minRating,
    List<String>? tags,
    bool? isPublic,
    String? guideId,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) {
    return TourPlanSearchFilters(
      query: query ?? this.query,
      difficulty: difficulty ?? this.difficulty,
      minDuration: minDuration ?? this.minDuration,
      maxDuration: maxDuration ?? this.maxDuration,
      minRating: minRating ?? this.minRating,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      guideId: guideId ?? this.guideId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }

  /// Clear all filters
  TourPlanSearchFilters clearAll() {
    return const TourPlanSearchFilters();
  }

  @override
  List<Object?> get props => [
    query,
    difficulty,
    minDuration,
    maxDuration,
    minRating,
    tags,
    isPublic,
    guideId,
    latitude,
    longitude,
    radiusKm,
  ];

  @override
  String toString() {
    return 'TourPlanSearchFilters{query: $query, difficulty: $difficulty, hasFilters: $hasFilters}';
  }
}