import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/enums/tour_category.dart';
import '../../domain/enums/tour_difficulty.dart';
import '../../domain/entities/tour.dart';

/// Request model for creating a new tour
class TourCreateRequest extends Equatable {
  final String title;
  final String description;
  final TourCategory category;
  final TourDifficulty difficulty;
  final List<File> images;
  final TourLocation location;
  final double? estimatedDuration;
  final double? estimatedCost;
  final String? currency;
  final List<String> highlights;
  final List<String> includes;
  final List<String> excludes;
  final List<String> requirements;
  final List<TourItineraryItem> itinerary;
  final int maxGroupSize;
  final bool isPublic;
  final List<String> tags;

  const TourCreateRequest({
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.images,
    required this.location,
    this.estimatedDuration,
    this.estimatedCost,
    this.currency,
    required this.highlights,
    required this.includes,
    required this.excludes,
    required this.requirements,
    required this.itinerary,
    this.maxGroupSize = 10,
    this.isPublic = true,
    required this.tags,
  });

  /// Validate the request data and return list of errors
  List<String> validate() {
    return validationErrors;
  }

  /// Validate the request data
  bool get isValid {
    return title.trim().isNotEmpty &&
        description.trim().isNotEmpty &&
        // Remove image requirement for initial testing
        location.isValid &&
        maxGroupSize > 0 &&
        maxGroupSize <= 50;
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];

    if (title.trim().isEmpty) {
      errors.add('Title is required');
    } else if (title.trim().length > 100) {
      errors.add('Title cannot exceed 100 characters');
    }

    if (description.trim().isEmpty) {
      errors.add('Description is required');
    } else if (description.trim().length > 1000) {
      errors.add('Description cannot exceed 1000 characters');
    }

    // Make images optional for initial testing
    if (images.length > 10) {
      errors.add('Cannot upload more than 10 images');
    }

    if (!location.isValid) {
      errors.add('Valid location is required');
    }

    // Make highlights optional for initial testing
    if (highlights.length > 10) {
      errors.add('Cannot have more than 10 highlights');
    }

    // Make itinerary optional for initial testing
    if (itinerary.length > 20) {
      errors.add('Cannot have more than 20 itinerary items');
    }

    if (maxGroupSize <= 0) {
      errors.add('Max group size must be greater than 0');
    } else if (maxGroupSize > 50) {
      errors.add('Max group size cannot exceed 50');
    }

    if (estimatedCost != null && estimatedCost! < 0) {
      errors.add('Estimated cost cannot be negative');
    }

    if (estimatedDuration != null && estimatedDuration! <= 0) {
      errors.add('Estimated duration must be greater than 0');
    }

    return errors;
  }

  TourCreateRequest copyWith({
    String? title,
    String? description,
    TourCategory? category,
    TourDifficulty? difficulty,
    List<File>? images,
    TourLocation? location,
    double? estimatedDuration,
    double? estimatedCost,
    String? currency,
    List<String>? highlights,
    List<String>? includes,
    List<String>? excludes,
    List<String>? requirements,
    List<TourItineraryItem>? itinerary,
    int? maxGroupSize,
    bool? isPublic,
    List<String>? tags,
  }) {
    return TourCreateRequest(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      images: images ?? this.images,
      location: location ?? this.location,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      currency: currency ?? this.currency,
      highlights: highlights ?? this.highlights,
      includes: includes ?? this.includes,
      excludes: excludes ?? this.excludes,
      requirements: requirements ?? this.requirements,
      itinerary: itinerary ?? this.itinerary,
      maxGroupSize: maxGroupSize ?? this.maxGroupSize,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        category,
        difficulty,
        images,
        location,
        estimatedDuration,
        estimatedCost,
        currency,
        highlights,
        includes,
        excludes,
        requirements,
        itinerary,
        maxGroupSize,
        isPublic,
        tags,
      ];
}

/// Request model for updating an existing tour
class TourUpdateRequest extends Equatable {
  final String? title;
  final String? description;
  final TourCategory? category;
  final TourDifficulty? difficulty;
  final List<File>? newImages;
  final List<String>? imagesToRemove;
  final TourLocation? location;
  final double? estimatedDuration;
  final double? estimatedCost;
  final String? currency;
  final List<String>? highlights;
  final List<String>? includes;
  final List<String>? excludes;
  final List<String>? requirements;
  final List<TourItineraryItem>? itinerary;
  final int? maxGroupSize;
  final bool? isPublic;
  final bool? isActive;
  final List<String>? tags;

  const TourUpdateRequest({
    this.title,
    this.description,
    this.category,
    this.difficulty,
    this.newImages,
    this.imagesToRemove,
    this.location,
    this.estimatedDuration,
    this.estimatedCost,
    this.currency,
    this.highlights,
    this.includes,
    this.excludes,
    this.requirements,
    this.itinerary,
    this.maxGroupSize,
    this.isPublic,
    this.isActive,
    this.tags,
  });

  /// Check if request has any updates
  bool get hasUpdates {
    return title != null ||
        description != null ||
        category != null ||
        difficulty != null ||
        newImages != null ||
        imagesToRemove != null ||
        location != null ||
        estimatedDuration != null ||
        estimatedCost != null ||
        currency != null ||
        highlights != null ||
        includes != null ||
        excludes != null ||
        requirements != null ||
        itinerary != null ||
        maxGroupSize != null ||
        isPublic != null ||
        isActive != null ||
        tags != null;
  }

  @override
  List<Object?> get props => [
        title,
        description,
        category,
        difficulty,
        newImages,
        imagesToRemove,
        location,
        estimatedDuration,
        estimatedCost,
        currency,
        highlights,
        includes,
        excludes,
        requirements,
        itinerary,
        maxGroupSize,
        isPublic,
        isActive,
        tags,
      ];
}