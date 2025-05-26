import 'package:equatable/equatable.dart';
import '../../../../models/place.dart' as place_models;
import 'place_event.dart' show PlaceFilters, PlaceSortType;

// Use alias for PlaceCategory to avoid conflicts
typedef PlaceCategory = place_models.PlaceCategory;

abstract class PlaceState extends Equatable {
  const PlaceState();
  
  @override
  List<Object?> get props => [];
}

class PlaceInitial extends PlaceState {
  const PlaceInitial();
}

class PlaceLoading extends PlaceState {
  const PlaceLoading();
}

class PlacesLoading extends PlaceState {
  const PlacesLoading();
}

class PlaceActionLoading extends PlaceState {
  final String action;
  final String placeId;
  
  const PlaceActionLoading({
    required this.action,
    required this.placeId,
  });
  
  @override
  List<Object> get props => [action, placeId];
}

class PlaceImageUploadLoading extends PlaceState {
  final double progress;
  
  const PlaceImageUploadLoading({required this.progress});
  
  @override
  List<Object> get props => [progress];
}

class PlaceLoaded extends PlaceState {
  final place_models.Place place;
  
  const PlaceLoaded({required this.place});
  
  @override
  List<Object> get props => [place];
}

class PlaceCreated extends PlaceState {
  final place_models.Place place;
  
  const PlaceCreated({required this.place});
  
  @override
  List<Object> get props => [place];
}

class PlaceUpdated extends PlaceState {
  final place_models.Place place;
  
  const PlaceUpdated({required this.place});
  
  @override
  List<Object> get props => [place];
}

class PlaceDeleted extends PlaceState {
  final String placeId;
  
  const PlaceDeleted({required this.placeId});
  
  @override
  List<Object> get props => [placeId];
}

class PlaceAddedToFavorites extends PlaceState {
  final place_models.Place place;
  
  const PlaceAddedToFavorites({required this.place});
  
  @override
  List<Object> get props => [place];
}

class PlaceRemovedFromFavorites extends PlaceState {
  final place_models.Place place;
  
  const PlaceRemovedFromFavorites({required this.place});
  
  @override
  List<Object> get props => [place];
}

class PlaceInFavoritesChecked extends PlaceState {
  final String placeId;
  final bool isFavorite;
  
  const PlaceInFavoritesChecked({
    required this.placeId,
    required this.isFavorite,
  });
  
  @override
  List<Object> get props => [placeId, isFavorite];
}

class PlaceImageUploaded extends PlaceState {
  final String imageUrl;
  
  const PlaceImageUploaded({required this.imageUrl});
  
  @override
  List<Object> get props => [imageUrl];
}

class PlacesLoaded extends PlaceState {
  final List<place_models.Place> places;
  final PlaceLoadType loadType;
  final String? entityId; // category, region, userId
  
  const PlacesLoaded({
    required this.places,
    required this.loadType,
    this.entityId,
  });
  
  @override
  List<Object?> get props => [places, loadType, entityId];
}

class FilteredPlacesLoaded extends PlaceState {
  final List<place_models.Place> places;
  final List<place_models.Place> allPlaces;
  final PlaceFilters filters;
  
  const FilteredPlacesLoaded({
    required this.places,
    required this.allPlaces,
    required this.filters,
  });
  
  @override
  List<Object> get props => [places, allPlaces, filters];
}

class SortedPlacesLoaded extends PlaceState {
  final List<place_models.Place> places;
  final List<place_models.Place> allPlaces;
  final PlaceSortType sortType;
  
  const SortedPlacesLoaded({
    required this.places,
    required this.allPlaces,
    required this.sortType,
  });
  
  @override
  List<Object> get props => [places, allPlaces, sortType];
}

class SearchPlacesLoaded extends PlaceState {
  final List<place_models.Place> places;
  final List<place_models.Place> allPlaces;
  final String query;
  final PlaceSearchContext searchContext;
  
  const SearchPlacesLoaded({
    required this.places,
    required this.allPlaces,
    required this.query,
    required this.searchContext,
  });
  
  @override
  List<Object> get props => [places, allPlaces, query, searchContext];
}

class NearbyPlacesLoaded extends PlaceState {
  final List<place_models.Place> places;
  final double latitude;
  final double longitude;
  final double radiusKm;
  
  const NearbyPlacesLoaded({
    required this.places,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });
  
  @override
  List<Object> get props => [places, latitude, longitude, radiusKm];
}

class PopularPlacesLoaded extends PlaceState {
  final List<place_models.Place> places;
  final int limit;
  
  const PopularPlacesLoaded({
    required this.places,
    required this.limit,
  });
  
  @override
  List<Object> get props => [places, limit];
}

class TrendingPlacesLoaded extends PlaceState {
  final List<place_models.Place> places;
  final Duration timeWindow;
  
  const TrendingPlacesLoaded({
    required this.places,
    required this.timeWindow,
  });
  
  @override
  List<Object> get props => [places, timeWindow];
}

class FavoritePlacesLoaded extends PlaceState {
  final List<place_models.Place> places;
  final String userId;
  
  const FavoritePlacesLoaded({
    required this.places,
    required this.userId,
  });
  
  @override
  List<Object> get props => [places, userId];
}

class PlaceRecommendationsLoaded extends PlaceState {
  final List<place_models.Place> places;
  final String userId;
  final RecommendationReason reason;
  
  const PlaceRecommendationsLoaded({
    required this.places,
    required this.userId,
    required this.reason,
  });
  
  @override
  List<Object> get props => [places, userId, reason];
}

class PlacesByRegionLoaded extends PlaceState {
  final List<place_models.Place> places;
  final String region;
  final PlaceCategory? category;
  
  const PlacesByRegionLoaded({
    required this.places,
    required this.region,
    this.category,
  });
  
  @override
  List<Object?> get props => [places, region, category];
}

class PlacesByCategoryLoaded extends PlaceState {
  final List<place_models.Place> places;
  final PlaceCategory category;
  
  const PlacesByCategoryLoaded({
    required this.places,
    required this.category,
  });
  
  @override
  List<Object> get props => [places, category];
}

class PlaceError extends PlaceState {
  final String message;
  final String? errorCode;
  
  const PlaceError({
    required this.message,
    this.errorCode,
  });
  
  @override
  List<Object?> get props => [message, errorCode];
}

class PlaceValidationError extends PlaceState {
  final Map<String, String> fieldErrors;
  final String generalMessage;
  
  const PlaceValidationError({
    required this.fieldErrors,
    required this.generalMessage,
  });
  
  @override
  List<Object> get props => [fieldErrors, generalMessage];
}

class PlaceActionError extends PlaceState {
  final String message;
  final String action;
  final String placeId;
  
  const PlaceActionError({
    required this.message,
    required this.action,
    required this.placeId,
  });
  
  @override
  List<Object> get props => [message, action, placeId];
}

class PlaceImageUploadError extends PlaceState {
  final String message;
  final String imagePath;
  
  const PlaceImageUploadError({
    required this.message,
    required this.imagePath,
  });
  
  @override
  List<Object> get props => [message, imagePath];
}

class PlaceLocationError extends PlaceState {
  final String message;
  
  const PlaceLocationError({required this.message});
  
  @override
  List<Object> get props => [message];
}

class PlacesEmpty extends PlaceState {
  final PlaceLoadType loadType;
  final String message;
  
  const PlacesEmpty({
    required this.loadType,
    required this.message,
  });
  
  @override
  List<Object> get props => [loadType, message];
}

class NoPlacesFound extends PlaceState {
  final String searchQuery;
  final PlaceFilters? filters;
  final PlaceSearchContext? searchContext;
  
  const NoPlacesFound({
    required this.searchQuery,
    this.filters,
    this.searchContext,
  });
  
  @override
  List<Object?> get props => [searchQuery, filters, searchContext];
}

class NoNearbyPlacesFound extends PlaceState {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final PlaceCategory? category;
  
  const NoNearbyPlacesFound({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    this.category,
  });
  
  @override
  List<Object?> get props => [latitude, longitude, radiusKm, category];
}

enum PlaceLoadType {
  category,
  popular,
  trending,
  nearby,
  favorites,
  recommendations,
  region,
  search,
  all,
}

enum RecommendationReason {
  basedOnHistory,
  basedOnFavorites,
  basedOnLocation,
  trending,
  popular,
}

class PlaceSearchContext extends Equatable {
  final String? category;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final String? region;
  
  const PlaceSearchContext({
    this.category,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.region,
  });
  
  bool get hasLocationContext => latitude != null && longitude != null;
  
  bool get hasRegionContext => region != null && region!.isNotEmpty;
  
  bool get hasCategoryContext => category != null && category!.isNotEmpty;
  
  String get contextDescription {
    final parts = <String>[];
    
    if (hasCategoryContext) {
      parts.add('in $category');
    }
    
    if (hasLocationContext) {
      final radius = radiusKm ?? 5.0;
      parts.add('within ${radius.toStringAsFixed(1)}km');
    }
    
    if (hasRegionContext) {
      parts.add('in $region');
    }
    
    return parts.isEmpty ? 'everywhere' : parts.join(' ');
  }
  
  @override
  List<Object?> get props => [category, latitude, longitude, radiusKm, region];
}

extension PlaceLoadTypeExtension on PlaceLoadType {
  String get displayName {
    switch (this) {
      case PlaceLoadType.category:
        return 'Category Places';
      case PlaceLoadType.popular:
        return 'Popular Places';
      case PlaceLoadType.trending:
        return 'Trending Places';
      case PlaceLoadType.nearby:
        return 'Nearby Places';
      case PlaceLoadType.favorites:
        return 'Favorite Places';
      case PlaceLoadType.recommendations:
        return 'Recommended Places';
      case PlaceLoadType.region:
        return 'Regional Places';
      case PlaceLoadType.search:
        return 'Search Results';
      case PlaceLoadType.all:
        return 'All Places';
    }
  }
  
  String get emptyMessage {
    switch (this) {
      case PlaceLoadType.category:
        return 'No places found in this category';
      case PlaceLoadType.popular:
        return 'No popular places available';
      case PlaceLoadType.trending:
        return 'No trending places right now';
      case PlaceLoadType.nearby:
        return 'No places found nearby';
      case PlaceLoadType.favorites:
        return 'You haven\'t added any favorite places yet';
      case PlaceLoadType.recommendations:
        return 'No recommendations available';
      case PlaceLoadType.region:
        return 'No places found in this region';
      case PlaceLoadType.search:
        return 'No places match your search';
      case PlaceLoadType.all:
        return 'No places found';
    }
  }
}

extension RecommendationReasonExtension on RecommendationReason {
  String get displayName {
    switch (this) {
      case RecommendationReason.basedOnHistory:
        return 'Based on Your History';
      case RecommendationReason.basedOnFavorites:
        return 'Similar to Your Favorites';
      case RecommendationReason.basedOnLocation:
        return 'Near Your Location';
      case RecommendationReason.trending:
        return 'Currently Trending';
      case RecommendationReason.popular:
        return 'Popular Destinations';
    }
  }
  
  String get description {
    switch (this) {
      case RecommendationReason.basedOnHistory:
        return 'Places recommended based on your visit history';
      case RecommendationReason.basedOnFavorites:
        return 'Places similar to your favorites';
      case RecommendationReason.basedOnLocation:
        return 'Places near your current location';
      case RecommendationReason.trending:
        return 'Places that are trending right now';
      case RecommendationReason.popular:
        return 'Most popular places among users';
    }
  }
}