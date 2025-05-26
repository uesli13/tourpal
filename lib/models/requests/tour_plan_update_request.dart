import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourpal/models/tour_plan.dart';

/// Request model for updating an existing TourPlan following BLoC architecture rules
class TourPlanUpdateRequest extends Equatable {
  final String? title;
  final String? description;
  final int? duration;
  final String? difficulty;
  final List<String>? tags;
  final bool? isPublic;
  final String? imageUrl;
  final double? price;

  const TourPlanUpdateRequest({
    this.title,
    this.description,
    this.duration,
    this.difficulty,
    this.tags,
    this.isPublic,
    this.imageUrl,
    this.price,
  });

  /// Check if any updates are provided
  bool get hasUpdates =>
      title != null ||
      description != null ||
      duration != null ||
      difficulty != null ||
      tags != null ||
      isPublic != null ||
      imageUrl != null ||
      price != null;

  /// Convert to update map for Firestore - required by service layer
  Map<String, dynamic> toUpdateMap() {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updateData['title'] = title!.trim();
    if (description != null) updateData['description'] = description!.trim();
    if (duration != null) updateData['duration'] = duration;
    if (difficulty != null) updateData['difficulty'] = difficulty!.toLowerCase();
    if (tags != null) updateData['tags'] = tags;
    if (isPublic != null) updateData['isPublic'] = isPublic;
    if (imageUrl != null) updateData['imageUrl'] = imageUrl;
    if (price != null) updateData['price'] = price;

    return updateData;
  }

  /// Create a copy with modified fields
  TourPlanUpdateRequest copyWith({
    String? title,
    String? description,
    int? duration,
    String? difficulty,
    List<String>? tags,
    bool? isPublic,
    String? imageUrl,
    double? price,
  }) {
    return TourPlanUpdateRequest(
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
    );
  }

  @override
  List<Object?> get props => [
    title,
    description,
    duration,
    difficulty,
    tags,
    isPublic,
    imageUrl,
    price,
  ];

  @override
  String toString() {
    return 'TourPlanUpdateRequest{hasUpdates: $hasUpdates}';
  }

  /// Create a TourPlanUpdateRequest from a TourPlan
  static TourPlanUpdateRequest fromTourPlan(TourPlan tourPlan) {
    return TourPlanUpdateRequest(
      title: tourPlan.title,
      description: tourPlan.description,
      duration: tourPlan.duration,
      difficulty: tourPlan.difficulty,
      tags: tourPlan.tags,
      isPublic: tourPlan.isPublic,
      imageUrl: tourPlan.imageUrl,
      price: tourPlan.price,
    );
  }
}