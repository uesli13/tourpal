import '../core/services/google_places_service.dart';

/// Enhanced place suggestion that includes photo thumbnail and cached place details
class PlaceSuggestion {
  final PlaceAutocomplete suggestion;
  final String? thumbnailUrl;
  final PlaceDetails? placeDetails;

  PlaceSuggestion({
    required this.suggestion,
    this.thumbnailUrl,
    this.placeDetails,
  });

  /// Check if this suggestion has a photo available
  bool get hasPhoto => thumbnailUrl != null;

  /// Check if this suggestion has cached place details
  bool get hasDetails => placeDetails != null;

  /// Get the main text (place name) from the suggestion
  String get mainText => 
      suggestion.structuredFormatting?.mainText ?? suggestion.description;

  /// Get the secondary text (address/location) from the suggestion
  String? get secondaryText => suggestion.structuredFormatting?.secondaryText;

  /// Get the place rating if available
  double? get rating => placeDetails?.rating;

  /// Get the place types if available
  List<String>? get types => placeDetails?.types;
}