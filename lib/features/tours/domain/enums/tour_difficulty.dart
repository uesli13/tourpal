import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Tour difficulty enumeration following Tourpal development rules
enum TourDifficulty {
  easy('Easy', 'Perfect for beginners and families'),
  moderate('Moderate', 'Some experience recommended'),
  challenging('Challenging', 'For experienced adventurers'),
  difficult('Difficult', 'Challenging with some risks involved'),
  extreme('Extreme', 'Only for experts with proper preparation');

  const TourDifficulty(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Parse difficulty from string value
  static TourDifficulty fromString(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return TourDifficulty.easy;
      case 'moderate':
        return TourDifficulty.moderate;
      case 'challenging':
        return TourDifficulty.challenging;
      case 'difficult':
        return TourDifficulty.difficult;
      case 'extreme':
        return TourDifficulty.extreme;
      default:
        return TourDifficulty.easy; // Default fallback
    }
  }

  /// Convert to JSON string (used by Tour model)
  String toJson() => name;

  /// Get difficulty level as integer (1-5)
  int get level => index + 1;

  /// Get difficulty color for UI using app colors
  Color get color {
    switch (this) {
      case TourDifficulty.easy:
        return AppColors.success; // Green
      case TourDifficulty.moderate:
        return AppColors.warning; // Orange
      case TourDifficulty.challenging:
        return AppColors.accent; // Accent color
      case TourDifficulty.difficult:
        return AppColors.error; // Red
      case TourDifficulty.extreme:
        return AppColors.primary; // Primary color
    }
  }

  /// Get all difficulty names as strings
  static List<String> get difficultyNames => 
      TourDifficulty.values.map((e) => e.displayName).toList();

  @override
  String toString() => displayName;
}