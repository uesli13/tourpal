import 'package:bloc/bloc.dart';
import 'package:tourpal/core/utils/logger.dart';
import 'package:tourpal/features/tours/domain/entities/tour.dart';
import 'package:tourpal/features/tours/domain/enums/tour_category.dart';
import 'package:tourpal/features/tours/domain/enums/tour_difficulty.dart';
import '../../domain/enums/sort_criteria.dart';
import '../../services/explore_service.dart';
import 'explore_event.dart';
import 'explore_state.dart';

/// Explore BLoC for managing explore screen state
/// Follows TourPal BLoC architecture principles
class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final ExploreService _exploreService;

  ExploreBloc({required ExploreService exploreService}) 
      : _exploreService = exploreService,
        super(const ExploreInitial()) {
    on<LoadExploreDataEvent>(_onLoadExploreData);
    on<LoadToursEvent>(_onLoadTours);
    on<RefreshToursEvent>(_onRefreshTours);
    on<LoadToursByLocationEvent>(_onLoadToursByLocation);
    on<SearchToursEvent>(_onSearchTours);
    on<ClearSearchEvent>(_onClearSearch);
    on<FilterByCategoryEvent>(_onFilterByCategory);
    on<FilterByDifficultyEvent>(_onFilterByDifficulty);
    on<FilterByPriceEvent>(_onFilterByPriceRange);
    on<SortToursEvent>(_onSortTours);
    on<ClearFiltersEvent>(_onClearFilters);
    
    AppLogger.info('ExploreBloc initialized');
  }

  @override
  void onChange(Change<ExploreState> change) {
    super.onChange(change);
    AppLogger.blocTransition(
      'ExploreBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(ExploreEvent event) {
    super.onEvent(event);
    AppLogger.blocEvent('ExploreBloc', event.runtimeType.toString());
  }

  /// Load initial explore data
  Future<void> _onLoadExploreData(
    LoadExploreDataEvent event,
    Emitter<ExploreState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading explore data');
    emit(const ExploreLoading());
    
    try {
      // Load all data concurrently for better performance
      final results = await Future.wait([
        _exploreService.getAllTours(),
        _exploreService.getFeaturedTours(),
        _exploreService.getPopularDestinations(),
      ]);
      
      final tours = results[0] as List<Tour>;
      final featuredTours = results[1] as List<Tour>;
      final popularDestinations = results[2] as List<String>;
      
      // For nearby tours, use empty list initially (will be loaded when location is available)
      final nearbyTours = <Tour>[];

      stopwatch.stop();
      AppLogger.performance('Explore Data Load', stopwatch.elapsed);
      
      emit(ExploreLoaded(
        tours: tours,
        filteredTours: tours,
        popularDestinations: popularDestinations,
        featuredTours: featuredTours,
        nearbyTours: nearbyTours,
      ));
      
      AppLogger.info('Explore data loaded successfully: ${tours.length} tours');
      AppLogger.serviceOperation('ExploreService', 'loadExploreData', true);
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load explore data', e);
      AppLogger.serviceOperation('ExploreService', 'loadExploreData', false);
      emit(ExploreError(message: 'Failed to load tours: ${e.toString()}'));
    }
  }

  /// Load tours
  Future<void> _onLoadTours(
    LoadToursEvent event,
    Emitter<ExploreState> emit,
  ) async {
    emit(const ExploreLoading());
    add(const LoadExploreDataEvent());
  }

  /// Refresh tours
  Future<void> _onRefreshTours(
    RefreshToursEvent event,
    Emitter<ExploreState> emit,
  ) async {
    AppLogger.info('Refreshing tours data');
    add(const LoadExploreDataEvent());
  }

  /// Load tours by location
  Future<void> _onLoadToursByLocation(
    LoadToursByLocationEvent event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    
    final currentState = state as ExploreLoaded;
    AppLogger.info('Loading tours by location: ${event.latitude}, ${event.longitude}');
    
    try {
      final nearbyTours = await _exploreService.getToursByLocation(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );
      
      emit(currentState.copyWith(nearbyTours: nearbyTours));
      AppLogger.info('Loaded ${nearbyTours.length} nearby tours');
      AppLogger.serviceOperation('ExploreService', 'getToursByLocation', true);
    } catch (e) {
      AppLogger.error('Failed to load nearby tours', e);
      AppLogger.serviceOperation('ExploreService', 'getToursByLocation', false);
      // Don't emit error state, just keep current state
    }
  }

  /// Search tours by query
  Future<void> _onSearchTours(
    SearchToursEvent event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    
    final currentState = state as ExploreLoaded;
    AppLogger.info('Searching tours with query: "${event.query}"');
    
    emit(const ExploreSearching());
    
    try {
      // Simulate search delay for better UX
      await Future.delayed(const Duration(milliseconds: 300));
      
      List<Tour> filtered = currentState.tours;
      
      if (event.query.isNotEmpty) {
        final query = event.query.toLowerCase().trim();
        filtered = currentState.tours.where((tour) {
          // Search in tour basic info
          final matchesBasicInfo = tour.title.toLowerCase().contains(query) ||
                 tour.description.toLowerCase().contains(query) ||
                 tour.summary.toLowerCase().contains(query);
          
          final matchesStartLocation = _searchInLocation(tour.startLocation, query);
          
          final matchesEndLocation = tour.endLocation != null 
              ? _searchInLocation(tour.endLocation!, query)
              : false;
          
          final matchesItineraryLocations = tour.itinerary.any((item) {
            if (item.location != null) {
              return _searchInLocation(item.location!, query);
            }
            return false;
          });
          
          final matchesContent = tour.highlights.any((highlight) => 
              highlight.toLowerCase().contains(query)) ||
              tour.includes.any((include) => 
              include.toLowerCase().contains(query));
          
          return matchesBasicInfo || 
                 matchesStartLocation || 
                 matchesEndLocation || 
                 matchesItineraryLocations ||
                 matchesContent;
        }).toList();
        
        AppLogger.info('Location-enhanced search for "$query" found ${filtered.length} tours');
      } else {
        filtered = _applyAllFilters(
          currentState.tours,
          category: currentState.selectedCategory,
          difficulty: currentState.selectedDifficulty,
          minPrice: currentState.minPrice,
          maxPrice: currentState.maxPrice,
          searchQuery: null, // Clear search query
        );
        AppLogger.info('Search cleared - Showing ${filtered.length} tours');
      }
      
      emit(currentState.copyWith(
        searchQuery: event.query.isEmpty ? null : event.query,
        filteredTours: filtered,
        hasFilters: _hasActiveFilters(currentState.copyWith(
          searchQuery: event.query.isEmpty ? null : event.query,
        )),
      ));
      
      AppLogger.info('Search completed: ${filtered.length} tours displayed');
    } catch (e) {
      AppLogger.error('Search failed', e);
      emit(currentState);
    }
  }

  /// Clear search query
  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    
    final currentState = state as ExploreLoaded;
    AppLogger.info('Clearing search query');
    
    emit(currentState.copyWith(
      searchQuery: null,
      filteredTours: currentState.tours,
      hasFilters: _hasActiveFilters(currentState.copyWith(searchQuery: null)),
      clearSearchQuery: true,
    ));
    
    AppLogger.info('Search query cleared - Showing ${currentState.tours.length} tours');
  }

  /// Filter tours by category
  Future<void> _onFilterByCategory(
    FilterByCategoryEvent event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    
    final currentState = state as ExploreLoaded;
    AppLogger.info('Filtering tours by category: ${event.category?.displayName ?? 'All'}');
    
    final filtered = _applyAllFilters(
      currentState.tours,
      category: event.category,
      difficulty: currentState.selectedDifficulty,
      minPrice: currentState.minPrice,
      maxPrice: currentState.maxPrice,
      searchQuery: currentState.searchQuery,
    );
    
    emit(currentState.copyWith(
      selectedCategory: event.category,
      filteredTours: filtered,
      hasFilters: _hasActiveFilters(currentState.copyWith(selectedCategory: event.category)),
      clearCategory: event.category == null,
    ));
  }

  /// Filter tours by difficulty
  Future<void> _onFilterByDifficulty(
    FilterByDifficultyEvent event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    
    final currentState = state as ExploreLoaded;
    AppLogger.info('Filtering tours by difficulty: ${event.difficulty?.displayName ?? 'All'}');
    
    final filtered = _applyAllFilters(
      currentState.tours,
      category: currentState.selectedCategory,
      difficulty: event.difficulty,
      minPrice: currentState.minPrice,
      maxPrice: currentState.maxPrice,
      searchQuery: currentState.searchQuery,
    );
    
    emit(currentState.copyWith(
      selectedDifficulty: event.difficulty,
      filteredTours: filtered,
      hasFilters: _hasActiveFilters(currentState.copyWith(selectedDifficulty: event.difficulty)),
    ));
  }

  /// Filter tours by price range
  Future<void> _onFilterByPriceRange(
    FilterByPriceEvent event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    
    final currentState = state as ExploreLoaded;
    AppLogger.info('Filtering tours by price range: \$${event.minPrice} - \$${event.maxPrice}');
    
    final filtered = _applyAllFilters(
      currentState.tours,
      category: currentState.selectedCategory,
      difficulty: currentState.selectedDifficulty,
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      searchQuery: currentState.searchQuery,
    );
    
    emit(currentState.copyWith(
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      filteredTours: filtered,
      hasFilters: _hasActiveFilters(currentState.copyWith(
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
      )),
      clearMinPrice: event.minPrice == null,
      clearMaxPrice: event.maxPrice == null,
    ));
  }

  /// Sort tours
  Future<void> _onSortTours(
    SortToursEvent event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    
    final currentState = state as ExploreLoaded;
    AppLogger.info('Sorting tours by: ${event.criteria.displayName}');
    
    final sortedTours = _sortTours(currentState.filteredTours, event.criteria, event.ascending);
    
    emit(currentState.copyWith(
      filteredTours: sortedTours,
      sortCriteria: event.criteria,
      sortAscending: event.ascending,
    ));
  }

  /// Clear all filters
  Future<void> _onClearFilters(
    ClearFiltersEvent event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    
    final currentState = state as ExploreLoaded;
    AppLogger.info('Clearing all filters');
    
    emit(currentState.copyWith(
      filteredTours: currentState.tours,
      hasFilters: false,
      clearSearchQuery: true,
      clearCategory: true,
      clearDifficulty: true,
      clearMinPrice: true,
      clearMaxPrice: true,
    ));
    
    AppLogger.info('All filters cleared - Showing ${currentState.tours.length} tours');
  }

  /// Apply all active filters to tour list
  List<Tour> _applyAllFilters(
    List<Tour> tours, {
    TourCategory? category,
    TourDifficulty? difficulty,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) {
    List<Tour> filtered = List.from(tours);
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((tour) {
        // Search in tour basic info
        final matchesBasicInfo = tour.title.toLowerCase().contains(query) ||
               tour.description.toLowerCase().contains(query) ||
               tour.summary.toLowerCase().contains(query);
        
        final matchesStartLocation = _searchInLocation(tour.startLocation, query);
        
        final matchesEndLocation = tour.endLocation != null 
            ? _searchInLocation(tour.endLocation!, query)
            : false;
        
        final matchesItineraryLocations = tour.itinerary.any((item) {
          if (item.location != null) {
            return _searchInLocation(item.location!, query);
          }
          return false;
        });
        
        final matchesContent = tour.highlights.any((highlight) => 
            highlight.toLowerCase().contains(query)) ||
            tour.includes.any((include) => 
            include.toLowerCase().contains(query));
        
        return matchesBasicInfo || 
               matchesStartLocation || 
               matchesEndLocation || 
               matchesItineraryLocations ||
               matchesContent;
      }).toList();
      
      AppLogger.info('Location-enhanced search for "$query" found ${filtered.length} tours');
    }
    
    // Apply category filter
    if (category != null) {
      filtered = filtered.where((tour) => tour.category == category).toList();
    }
    
    // Apply difficulty filter
    if (difficulty != null) {
      filtered = filtered.where((tour) => tour.difficulty == difficulty).toList();
    }
    
    // Apply price filter
    if (minPrice != null) {
      filtered = filtered.where((tour) => tour.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      filtered = filtered.where((tour) => tour.price <= maxPrice).toList();
    }
    
    return filtered;
  }

  bool _searchInLocation(TourLocation location, String query) {
    final queryLower = query.toLowerCase().trim();
    
    // Don't match single characters or very short queries for locations
    if (queryLower.length < 2) return false;
    
    // Check for exact matches first (highest priority)
    if (location.name?.toLowerCase() == queryLower) {
      return true;
    }
    
    // Check for word-based matches (medium priority)
    final nameWords = location.name?.toLowerCase().split(' ') ?? [];
    final addressWords = location.address.toLowerCase().split(' ');
    
    // Match if query is a complete word in any location field
    if (nameWords.contains(queryLower) ||
        addressWords.contains(queryLower)) {
      return true;
    }
    
    // Only for longer queries (3+ chars), check if it starts with the query
    if (queryLower.length >= 3) {
      return (location.name?.toLowerCase().startsWith(queryLower) ?? false) ||
             location.address.toLowerCase().startsWith(queryLower);
    }
    
    return false;
  }

  /// Sort tours based on criteria
  List<Tour> _sortTours(List<Tour> tours, SortCriteria criteria, bool ascending) {
    final sortedTours = List<Tour>.from(tours);
    
    switch (criteria) {
      case SortCriteria.name:
        sortedTours.sort((a, b) => ascending ? a.title.compareTo(b.title) : b.title.compareTo(a.title));
        break;
      case SortCriteria.price:
        sortedTours.sort((a, b) => ascending ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
        break;
      case SortCriteria.duration:
        sortedTours.sort((a, b) => ascending ? a.duration.inMinutes.compareTo(b.duration.inMinutes) : b.duration.inMinutes.compareTo(a.duration.inMinutes));
        break;
      case SortCriteria.rating:
        // Use rating if available, otherwise fallback to price
        sortedTours.sort((a, b) => ascending ? (a.rating ?? 0).compareTo(b.rating ?? 0) : (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case SortCriteria.popularity:
        // Use booking count if available, otherwise fallback to rating
        sortedTours.sort((a, b) => ascending ? (a.bookingCount ?? 0).compareTo(b.bookingCount ?? 0) : (b.bookingCount ?? 0).compareTo(a.bookingCount ?? 0));
        break;
      case SortCriteria.distance:
        // For distance sorting, we'd need user location - for now use price as fallback
        sortedTours.sort((a, b) => ascending ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
        break;
      case SortCriteria.newest:
        // Sort by creation date if available
        sortedTours.sort((a, b) => ascending ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt));
        break;
      case SortCriteria.featured:
        // Featured tours first, then by rating
        sortedTours.sort((a, b) {
          final aFeatured = (a.rating ?? 0) > 4.0 ? 1 : 0;
          final bFeatured = (b.rating ?? 0) > 4.0 ? 1 : 0;
          if (ascending) {
            return aFeatured.compareTo(bFeatured);
          } else {
            return bFeatured.compareTo(aFeatured);
          }
        });
        break;
    }
    
    return sortedTours;
  }

  /// Check if there are active filters
  bool _hasActiveFilters(ExploreLoaded state) {
    return state.searchQuery != null ||
           state.selectedCategory != null ||
           state.selectedDifficulty != null ||
           state.minPrice != null ||
           state.maxPrice != null;
  }
}