import 'package:equatable/equatable.dart';
import 'package:tourpal/features/tours/domain/enums/tour_category.dart';
import 'package:tourpal/features/tours/domain/enums/tour_difficulty.dart';
import '../../domain/enums/sort_criteria.dart';

/// Explore BLoC Events following TOURPAL development rules
abstract class ExploreEvent extends Equatable {
  const ExploreEvent();
  
  @override
  List<Object?> get props => [];
}

/// Load initial explore data
class LoadExploreDataEvent extends ExploreEvent {
  const LoadExploreDataEvent();
}

/// Load tours event
class LoadToursEvent extends ExploreEvent {
  const LoadToursEvent();
}

/// Refresh tours event
class RefreshToursEvent extends ExploreEvent {
  const RefreshToursEvent();
}

/// Load tours by location event
class LoadToursByLocationEvent extends ExploreEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;
  
  const LoadToursByLocationEvent({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 50.0,
  });
  
  @override
  List<Object> get props => [latitude, longitude, radiusKm];
}

/// Search tours by query
class SearchToursEvent extends ExploreEvent {
  final String query;
  
  const SearchToursEvent({required this.query});
  
  @override
  List<Object> get props => [query];
}

/// Clear search query and return to all tours
class ClearSearchEvent extends ExploreEvent {
  const ClearSearchEvent();
}

/// Filter tours by category
class FilterByCategoryEvent extends ExploreEvent {
  final TourCategory? category;
  
  const FilterByCategoryEvent({required this.category});
  
  @override
  List<Object?> get props => [category];
}

/// Filter tours by difficulty
class FilterByDifficultyEvent extends ExploreEvent {
  final TourDifficulty? difficulty;
  
  const FilterByDifficultyEvent({required this.difficulty});
  
  @override
  List<Object?> get props => [difficulty];
}

/// Filter tours by price range
class FilterByPriceEvent extends ExploreEvent {
  final double? minPrice;
  final double? maxPrice;
  
  const FilterByPriceEvent({
    this.minPrice,
    this.maxPrice,
  });
  
  @override
  List<Object?> get props => [minPrice, maxPrice];
}

/// Sort tours by criteria
class SortToursEvent extends ExploreEvent {
  final SortCriteria criteria;
  final bool ascending;
  
  const SortToursEvent({
    required this.criteria,
    this.ascending = true,
  });
  
  @override
  List<Object> get props => [criteria, ascending];
}

/// Clear all filters
class ClearFiltersEvent extends ExploreEvent {
  const ClearFiltersEvent();
}