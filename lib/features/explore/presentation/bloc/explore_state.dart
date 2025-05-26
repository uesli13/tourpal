import 'package:equatable/equatable.dart';
import 'package:tourpal/features/tours/domain/entities/tour.dart';
import 'package:tourpal/features/tours/domain/enums/tour_category.dart';
import 'package:tourpal/features/tours/domain/enums/tour_difficulty.dart';
import '../../domain/enums/sort_criteria.dart';

/// Explore BLoC States following TOURPAL development rules
abstract class ExploreState extends Equatable {
  const ExploreState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state
class ExploreInitial extends ExploreState {
  const ExploreInitial();
}

/// Loading state
class ExploreLoading extends ExploreState {
  const ExploreLoading();
}

/// Searching state
class ExploreSearching extends ExploreState {
  const ExploreSearching();
}

/// Loaded state with tours data
class ExploreLoaded extends ExploreState {
  final List<Tour> tours;
  final List<Tour> filteredTours;
  final List<String> popularDestinations;
  final List<Tour> featuredTours;
  final List<Tour> nearbyTours;
  final String? searchQuery;
  final TourCategory? selectedCategory;
  final TourDifficulty? selectedDifficulty;
  final double? minPrice;
  final double? maxPrice;
  final SortCriteria? sortCriteria;
  final bool sortAscending;
  final bool hasFilters;

  const ExploreLoaded({
    required this.tours,
    required this.filteredTours,
    required this.popularDestinations,
    required this.featuredTours,
    required this.nearbyTours,
    this.searchQuery,
    this.selectedCategory,
    this.selectedDifficulty,
    this.minPrice,
    this.maxPrice,
    this.sortCriteria,
    this.sortAscending = true,
    this.hasFilters = false,
  });

  /// Convenience getters for backwards compatibility
  List<Tour> get displayTours => filteredTours;
  bool get hasSearchQuery => searchQuery != null && searchQuery!.isNotEmpty;

  /// Copy with method for state updates
  ExploreLoaded copyWith({
    List<Tour>? tours,
    List<Tour>? filteredTours,
    List<String>? popularDestinations,
    List<Tour>? featuredTours,
    List<Tour>? nearbyTours,
    String? searchQuery,
    TourCategory? selectedCategory,
    TourDifficulty? selectedDifficulty,
    double? minPrice,
    double? maxPrice,
    SortCriteria? sortCriteria,
    bool? sortAscending,
    bool? hasFilters,
    bool clearSearchQuery = false,
    bool clearCategory = false,
    bool clearDifficulty = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return ExploreLoaded(
      tours: tours ?? this.tours,
      filteredTours: filteredTours ?? this.filteredTours,
      popularDestinations: popularDestinations ?? this.popularDestinations,
      featuredTours: featuredTours ?? this.featuredTours,
      nearbyTours: nearbyTours ?? this.nearbyTours,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedDifficulty: clearDifficulty ? null : (selectedDifficulty ?? this.selectedDifficulty),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sortCriteria: sortCriteria ?? this.sortCriteria,
      sortAscending: sortAscending ?? this.sortAscending,
      hasFilters: hasFilters ?? this.hasFilters,
    );
  }

  @override
  List<Object?> get props => [
        tours,
        filteredTours,
        popularDestinations,
        featuredTours,
        nearbyTours,
        searchQuery,
        selectedCategory,
        selectedDifficulty,
        minPrice,
        maxPrice,
        sortCriteria,
        sortAscending,
        hasFilters,
      ];
}

/// Error state
class ExploreError extends ExploreState {
  final String message;

  const ExploreError({required this.message});

  @override
  List<Object> get props => [message];
}