import 'package:equatable/equatable.dart';
import '../../../../models/place.dart';

abstract class PlaceEvent extends Equatable {
  const PlaceEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadPlacesByCategoryEvent extends PlaceEvent {
  final PlaceCategory category;
  
  const LoadPlacesByCategoryEvent({required this.category});
  
  @override
  List<Object> get props => [category];
}

class LoadPopularPlacesEvent extends PlaceEvent {
  final int limit;
  
  const LoadPopularPlacesEvent({this.limit = 20});
  
  @override
  List<Object> get props => [limit];
}

class SearchPlacesEvent extends PlaceEvent {
  final String query;
  final PlaceCategory? category;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  
  const SearchPlacesEvent({
    required this.query,
    this.category,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });
  
  @override
  List<Object?> get props => [query, category, latitude, longitude, radiusKm];
}

class LoadNearbyPlacesEvent extends PlaceEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final PlaceCategory? category;
  
  const LoadNearbyPlacesEvent({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5.0,
    this.category,
  });
  
  @override
  List<Object?> get props => [latitude, longitude, radiusKm, category];
}

class LoadPlaceDetailsEvent extends PlaceEvent {
  final String placeId;
  
  const LoadPlaceDetailsEvent({required this.placeId});
  
  @override
  List<Object> get props => [placeId];
}

class CreatePlaceEvent extends PlaceEvent {
  final String name;
  final String description;
  final PlaceCategory category;
  final double latitude;
  final double longitude;
  final String address;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  
  const CreatePlaceEvent({
    required this.name,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.imageUrl,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [
    name,
    description,
    category,
    latitude,
    longitude,
    address,
    imageUrl,
    metadata,
  ];
}

class UpdatePlaceEvent extends PlaceEvent {
  final String tourPlanId;
  final String placeId;
  final String? name;
  final String? description;
  final PlaceCategory? category;
  final String? address;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  
  const UpdatePlaceEvent({
    required this.tourPlanId,
    required this.placeId,
    this.name,
    this.description,
    this.category,
    this.address,
    this.imageUrl,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [
    tourPlanId,
    placeId,
    name,
    description,
    category,
    address,
    imageUrl,
    metadata,
  ];
}

class DeletePlaceEvent extends PlaceEvent {
  final String placeId;
  
  const DeletePlaceEvent({required this.placeId});
  
  @override
  List<Object> get props => [placeId];
}

class AddPlaceToFavoritesEvent extends PlaceEvent {
  final String placeId;
  
  const AddPlaceToFavoritesEvent({required this.placeId});
  
  @override
  List<Object> get props => [placeId];
}

class RemovePlaceFromFavoritesEvent extends PlaceEvent {
  final String placeId;
  
  const RemovePlaceFromFavoritesEvent({required this.placeId});
  
  @override
  List<Object> get props => [placeId];
}

class LoadFavoritePlacesEvent extends PlaceEvent {
  final String userId;
  
  const LoadFavoritePlacesEvent({required this.userId});
  
  @override
  List<Object> get props => [userId];
}

class CheckPlaceInFavoritesEvent extends PlaceEvent {
  final String placeId;
  
  const CheckPlaceInFavoritesEvent({required this.placeId});
  
  @override
  List<Object> get props => [placeId];
}

class FilterPlacesEvent extends PlaceEvent {
  final PlaceFilters filters;
  
  const FilterPlacesEvent({required this.filters});
  
  @override
  List<Object> get props => [filters];
}

class SortPlacesEvent extends PlaceEvent {
  final PlaceSortType sortType;
  
  const SortPlacesEvent({required this.sortType});
  
  @override
  List<Object> get props => [sortType];
}

class LoadPlacesByRegionEvent extends PlaceEvent {
  final String region;
  final PlaceCategory? category;
  
  const LoadPlacesByRegionEvent({
    required this.region,
    this.category,
  });
  
  @override
  List<Object?> get props => [region, category];
}

class LoadTrendingPlacesEvent extends PlaceEvent {
  final int limit;
  final Duration timeWindow;
  
  const LoadTrendingPlacesEvent({
    this.limit = 10,
    this.timeWindow = const Duration(days: 7),
  });
  
  @override
  List<Object> get props => [limit, timeWindow];
}

class GetPlaceRecommendationsEvent extends PlaceEvent {
  final String userId;
  final int limit;
  
  const GetPlaceRecommendationsEvent({
    required this.userId,
    this.limit = 10,
  });
  
  @override
  List<Object> get props => [userId, limit];
}

class UploadPlaceImageEvent extends PlaceEvent {
  final String imagePath;
  
  const UploadPlaceImageEvent({required this.imagePath});
  
  @override
  List<Object> get props => [imagePath];
}

class RefreshPlacesEvent extends PlaceEvent {
  const RefreshPlacesEvent();
}

class ClearPlaceErrorEvent extends PlaceEvent {
  const ClearPlaceErrorEvent();
}

class ResetPlaceFiltersEvent extends PlaceEvent {
  const ResetPlaceFiltersEvent();
}

class LoadMorePlacesEvent extends PlaceEvent {
  const LoadMorePlacesEvent();
}

enum PlaceSortType {
  name,
  distance,
  popularity,
  rating,
  newest,
  oldest,
}

class PlaceFilters extends Equatable {
  final List<PlaceCategory> categories;
  final double? minRating;
  final double? maxDistance;
  final bool? isAccessible;
  final bool? hasParking;
  final bool? isOpenNow;
  
  const PlaceFilters({
    this.categories = const [],
    this.minRating,
    this.maxDistance,
    this.isAccessible,
    this.hasParking,
    this.isOpenNow,
  });
  
  @override
  List<Object?> get props => [
    categories,
    minRating,
    maxDistance,
    isAccessible,
    hasParking,
    isOpenNow,
  ];
}

extension PlaceSortTypeExtension on PlaceSortType {
  String get displayName {
    switch (this) {
      case PlaceSortType.name:
        return 'Name';
      case PlaceSortType.distance:
        return 'Distance';
      case PlaceSortType.popularity:
        return 'Popularity';
      case PlaceSortType.rating:
        return 'Rating';
      case PlaceSortType.newest:
        return 'Newest';
      case PlaceSortType.oldest:
        return 'Oldest';
    }
  }
}