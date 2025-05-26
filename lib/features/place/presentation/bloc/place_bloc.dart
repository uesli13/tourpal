import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../services/place_service.dart';
import '../../../../models/place.dart' hide PlaceFilters, PlaceSortType;
import 'place_event.dart';
import 'place_state.dart';

class PlaceBloc extends Bloc<PlaceEvent, PlaceState> {
  final PlaceService _placeService;
  
  List<Place> _allPlaces = [];
  PlaceFilters _currentFilters = const PlaceFilters();
  PlaceSortType _currentSortType = PlaceSortType.popularity;
  String _currentSearchQuery = '';
  double? _userLatitude;
  double? _userLongitude;

  PlaceBloc({
    required PlaceService placeService,
  }) : _placeService = placeService,
       super(const PlaceInitial()) {
    
    AppLogger.info('PlaceBloc initialized');
    
    on<LoadPlacesByCategoryEvent>(_onLoadPlacesByCategory);
    on<LoadPopularPlacesEvent>(_onLoadPopularPlaces);
    on<SearchPlacesEvent>(_onSearchPlaces);
    on<LoadNearbyPlacesEvent>(_onLoadNearbyPlaces);
    on<LoadPlaceDetailsEvent>(_onLoadPlaceDetails);
    on<CreatePlaceEvent>(_onCreatePlace);
    on<UpdatePlaceEvent>(_onUpdatePlace);
    on<DeletePlaceEvent>(_onDeletePlace);
    on<AddPlaceToFavoritesEvent>(_onAddPlaceToFavorites);
    on<RemovePlaceFromFavoritesEvent>(_onRemovePlaceFromFavorites);
    on<LoadFavoritePlacesEvent>(_onLoadFavoritePlaces);
    on<CheckPlaceInFavoritesEvent>(_onCheckPlaceInFavorites);
    on<FilterPlacesEvent>(_onFilterPlaces);
    on<SortPlacesEvent>(_onSortPlaces);
    on<LoadPlacesByRegionEvent>(_onLoadPlacesByRegion);
    on<LoadTrendingPlacesEvent>(_onLoadTrendingPlaces);
    on<GetPlaceRecommendationsEvent>(_onGetPlaceRecommendations);
    on<UploadPlaceImageEvent>(_onUploadPlaceImage);
    on<RefreshPlacesEvent>(_onRefreshPlaces);
    on<ClearPlaceErrorEvent>(_onClearPlaceError);
    on<ResetPlaceFiltersEvent>(_onResetPlaceFilters);
    on<LoadMorePlacesEvent>(_onLoadMorePlaces);
  }

  @override
  void onChange(Change<PlaceState> change) {
    super.onChange(change);
    AppLogger.blocTransition(
      'PlaceBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(PlaceEvent event) {
    super.onEvent(event);
    AppLogger.blocEvent('PlaceBloc', event.runtimeType.toString());
  }

  Future<void> _onLoadPlacesByCategory(
    LoadPlacesByCategoryEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading places by category: ${event.category.name}');
    
    emit(const PlacesLoading());
    
    try {
      final places = await _placeService.getPlacesByCategory(event.category);
      _allPlaces = places;
      
      stopwatch.stop();
      AppLogger.performance('Load Places By Category', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'getPlacesByCategory', true);
      
      if (places.isEmpty) {
        emit(PlacesEmpty(
          loadType: PlaceLoadType.category,
          message: PlaceLoadType.category.emptyMessage,
        ));
      } else {
        emit(PlacesByCategoryLoaded(
          places: places,
          category: event.category,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load places by category', e);
      AppLogger.serviceOperation('PlaceService', 'getPlacesByCategory', false);
      emit(PlaceError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLoadPopularPlaces(
    LoadPopularPlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading popular places (limit: ${event.limit})');
    
    emit(const PlacesLoading());
    
    try {
      final places = await _placeService.getPopularPlaces(limit: event.limit);
      _allPlaces = places;
      
      stopwatch.stop();
      AppLogger.performance('Load Popular Places', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'getPopularPlaces', true);
      
      if (places.isEmpty) {
        emit(PlacesEmpty(
          loadType: PlaceLoadType.popular,
          message: PlaceLoadType.popular.emptyMessage,
        ));
      } else {
        emit(PopularPlacesLoaded(
          places: places,
          limit: event.limit,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load popular places', e);
      AppLogger.serviceOperation('PlaceService', 'getPopularPlaces', false);
      emit(PlaceError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onSearchPlaces(
    SearchPlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Searching places with query: "${event.query}"');
    
    emit(const PlacesLoading());
    
    try {
      final places = await _placeService.searchPlaces(
        query: event.query,
        category: event.category,
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );
      
      _allPlaces = places;
      _currentSearchQuery = event.query;
      
      final searchContext = PlaceSearchContext(
        category: event.category?.name,
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );
      
      stopwatch.stop();
      AppLogger.performance('Search Places', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'searchPlaces', true);
      
      if (places.isEmpty) {
        emit(NoPlacesFound(
          searchQuery: event.query,
          searchContext: searchContext,
        ));
      } else {
        emit(SearchPlacesLoaded(
          places: places,
          allPlaces: places,
          query: event.query,
          searchContext: searchContext,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to search places', e);
      AppLogger.serviceOperation('PlaceService', 'searchPlaces', false);
      emit(PlaceError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLoadNearbyPlaces(
    LoadNearbyPlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading nearby places within ${event.radiusKm}km');
    
    emit(const PlacesLoading());
    
    try {
      final places = await _placeService.getNearbyPlaces(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
        category: event.category,
      );
      
      _allPlaces = places;
      _userLatitude = event.latitude;
      _userLongitude = event.longitude;
      
      stopwatch.stop();
      AppLogger.performance('Load Nearby Places', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'getNearbyPlaces', true);
      
      if (places.isEmpty) {
        emit(NoNearbyPlacesFound(
          latitude: event.latitude,
          longitude: event.longitude,
          radiusKm: event.radiusKm,
          category: event.category,
        ));
      } else {
        emit(NearbyPlacesLoaded(
          places: places,
          latitude: event.latitude,
          longitude: event.longitude,
          radiusKm: event.radiusKm,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load nearby places', e);
      AppLogger.serviceOperation('PlaceService', 'getNearbyPlaces', false);
      emit(PlaceError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLoadPlaceDetails(
    LoadPlaceDetailsEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading place details: ${event.placeId}');
    
    emit(const PlaceLoading());
    
    try {
      final place = await _placeService.getPlaceById(event.placeId);
      
      stopwatch.stop();
      AppLogger.performance('Load Place Details', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'getPlaceById', true);
      
      if (place == null) {
        emit(const PlaceError(message: 'Place not found'));
      } else {
        emit(PlaceLoaded(place: place));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load place details', e);
      AppLogger.serviceOperation('PlaceService', 'getPlaceById', false);
      emit(PlaceError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onCreatePlace(
    CreatePlaceEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Creating place: ${event.name}');
    
    emit(const PlaceLoading());
    
    try {
      // Validate place data
      _validatePlaceData(event.name, event.description, event.address);
      
      final place = await _placeService.createPlace(
        name: event.name,
        description: event.description,
        category: event.category,
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
        imageUrl: event.imageUrl,
        metadata: event.metadata,
      );
      
      stopwatch.stop();
      AppLogger.performance('Create Place', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'createPlace', true);
      AppLogger.info('Place created successfully: ${place.id}');
      
      emit(PlaceCreated(place: place));
    } on ValidationException catch (e) {
      stopwatch.stop();
      AppLogger.warning('Place validation failed: ${e.message}');
      emit(PlaceValidationError(
        fieldErrors: _extractFieldErrors(e.message),
        generalMessage: e.message,
      ));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to create place', e);
      AppLogger.serviceOperation('PlaceService', 'createPlace', false);
      emit(PlaceError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onUpdatePlace(
    UpdatePlaceEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Updating place: ${event.placeId}');
    
    emit(PlaceActionLoading(
      action: 'Updating place',
      placeId: event.placeId,
    ));
    
    try {
      // Validate optional fields if provided
      if (event.name != null) {
        _validatePlaceName(event.name!);
      }
      if (event.description != null) {
        _validatePlaceDescription(event.description!);
      }
      
      final updatedPlace = await _placeService.updatePlace(
        tourPlanId: event.tourPlanId, // Now passing the required tourPlanId
        placeId: event.placeId,
        name: event.name,
        description: event.description,
        address: event.address,
        imageUrl: event.imageUrl,
      );
      
      stopwatch.stop();
      AppLogger.performance('Update Place', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'updatePlace', true);
      AppLogger.info('Place updated successfully: ${event.placeId}');
      
      emit(PlaceUpdated(place: updatedPlace));
    } on ValidationException catch (e) {
      stopwatch.stop();
      AppLogger.warning('Place validation failed: ${e.message}');
      emit(PlaceValidationError(
        fieldErrors: _extractFieldErrors(e.message),
        generalMessage: e.message,
      ));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to update place', e);
      AppLogger.serviceOperation('PlaceService', 'updatePlace', false);
      emit(PlaceActionError(
        message: _getErrorMessage(e),
        action: 'update',
        placeId: event.placeId,
      ));
    }
  }

  Future<void> _onDeletePlace(
    DeletePlaceEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Deleting place: ${event.placeId}');
    
    emit(PlaceActionLoading(
      action: 'Deleting place',
      placeId: event.placeId,
    ));
    
    try {
      await _placeService.deletePlace(event.placeId);
      
      stopwatch.stop();
      AppLogger.performance('Delete Place', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'deletePlace', true);
      AppLogger.info('Place deleted successfully: ${event.placeId}');
      
      emit(PlaceDeleted(placeId: event.placeId));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to delete place', e);
      AppLogger.serviceOperation('PlaceService', 'deletePlace', false);
      emit(PlaceActionError(
        message: _getErrorMessage(e),
        action: 'delete',
        placeId: event.placeId,
      ));
    }
  }

  Future<void> _onAddPlaceToFavorites(
    AddPlaceToFavoritesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Adding place to favorites: ${event.placeId}');
    
    emit(PlaceActionLoading(
      action: 'Adding to favorites',
      placeId: event.placeId,
    ));
    
    try {
      final place = await _placeService.addToFavorites(event.placeId);
      
      stopwatch.stop();
      AppLogger.performance('Add To Favorites', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'addToFavorites', true);
      
      if (place == null) {
        emit(PlaceActionError(
          message: 'Failed to add place to favorites',
          action: 'add to favorites',
          placeId: event.placeId,
        ));
      } else {
        emit(PlaceAddedToFavorites(place: place));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to add place to favorites', e);
      AppLogger.serviceOperation('PlaceService', 'addToFavorites', false);
      emit(PlaceActionError(
        message: _getErrorMessage(e),
        action: 'add to favorites',
        placeId: event.placeId,
      ));
    }
  }

  Future<void> _onRemovePlaceFromFavorites(
    RemovePlaceFromFavoritesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Removing place from favorites: ${event.placeId}');
    
    emit(PlaceActionLoading(
      action: 'Removing from favorites',
      placeId: event.placeId,
    ));
    
    try {
      final place = await _placeService.removeFromFavorites(event.placeId);
      
      stopwatch.stop();
      AppLogger.performance('Remove From Favorites', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'removeFromFavorites', true);
      
      if (place == null) {
        emit(PlaceActionError(
          message: 'Failed to remove place from favorites',
          action: 'remove from favorites',
          placeId: event.placeId,
        ));
      } else {
        emit(PlaceRemovedFromFavorites(place: place));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to remove place from favorites', e);
      AppLogger.serviceOperation('PlaceService', 'removeFromFavorites', false);
      emit(PlaceActionError(
        message: _getErrorMessage(e),
        action: 'remove from favorites',
        placeId: event.placeId,
      ));
    }
  }

  Future<void> _onLoadFavoritePlaces(
    LoadFavoritePlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading favorite places for user: ${event.userId}');
    
    emit(const PlacesLoading());
    
    try {
      final places = await _placeService.getFavoritePlaces(event.userId);
      _allPlaces = places;
      
      stopwatch.stop();
      AppLogger.performance('Load Favorite Places', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'getFavoritePlaces', true);
      
      if (places.isEmpty) {
        emit(PlacesEmpty(
          loadType: PlaceLoadType.favorites,
          message: PlaceLoadType.favorites.emptyMessage,
        ));
      } else {
        emit(FavoritePlacesLoaded(
          places: places,
          userId: event.userId,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load favorite places', e);
      AppLogger.serviceOperation('PlaceService', 'getFavoritePlaces', false);
      emit(PlaceError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onCheckPlaceInFavorites(
    CheckPlaceInFavoritesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Checking if place is in favorites: ${event.placeId}');
    
    try {
      final isFavorite = await _placeService.isPlaceInFavorites(event.placeId);
      
      stopwatch.stop();
      AppLogger.performance('Check Place In Favorites', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'isPlaceInFavorites', true);
      
      emit(PlaceInFavoritesChecked(
        placeId: event.placeId,
        isFavorite: isFavorite,
      ));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to check place favorite status', e);
      AppLogger.serviceOperation('PlaceService', 'isPlaceInFavorites', false);
      emit(PlaceError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onFilterPlaces(
    FilterPlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    AppLogger.info('Filtering places with ${event.filters.categories.length} categories');
    
    _currentFilters = event.filters;
    _applyFiltersAndSort(emit);
  }

  Future<void> _onSortPlaces(
    SortPlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    AppLogger.info('Sorting places by: ${event.sortType.displayName}');
    
    _currentSortType = event.sortType;
    _applyFiltersAndSort(emit);
  }

  Future<void> _onLoadPlacesByRegion(
    LoadPlacesByRegionEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading places by region: ${event.region}');
    
    emit(const PlacesLoading());
    
    try {
      final places = await _placeService.getPlacesByRegion(
        event.region,
        category: event.category,
      );
      _allPlaces = places;
      
      stopwatch.stop();
      AppLogger.performance('Load Places By Region', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'getPlacesByRegion', true);
      
      if (places.isEmpty) {
        emit(PlacesEmpty(
          loadType: PlaceLoadType.region,
          message: PlaceLoadType.region.emptyMessage,
        ));
      } else {
        emit(PlacesByRegionLoaded(
          places: places,
          region: event.region,
          category: event.category,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load places by region', e);
      AppLogger.serviceOperation('PlaceService', 'getPlacesByRegion', false);
      emit(PlaceError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLoadTrendingPlaces(
    LoadTrendingPlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading trending places (${event.timeWindow.inDays} days)');
    
    emit(const PlacesLoading());
    
    try {
      final places = await _placeService.getTrendingPlaces(
        limit: event.limit,
        timeWindow: event.timeWindow,
      );
      _allPlaces = places;
      
      stopwatch.stop();
      AppLogger.performance('Load Trending Places', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'getTrendingPlaces', true);
      
      if (places.isEmpty) {
        emit(PlacesEmpty(
          loadType: PlaceLoadType.trending,
          message: PlaceLoadType.trending.emptyMessage,
        ));
      } else {
        emit(TrendingPlacesLoaded(
          places: places,
          timeWindow: event.timeWindow,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load trending places', e);
      AppLogger.serviceOperation('PlaceService', 'getTrendingPlaces', false);
      emit(PlaceError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onGetPlaceRecommendations(
    GetPlaceRecommendationsEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Getting place recommendations for user: ${event.userId}');
    
    emit(const PlacesLoading());
    
    try {
      final recommendations = await _placeService.getPlaceRecommendations(
        event.userId,
        limit: event.limit,
      );
      
      stopwatch.stop();
      AppLogger.performance('Get Place Recommendations', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'getPlaceRecommendations', true);
      
      if (recommendations.places.isEmpty) {
        emit(PlacesEmpty(
          loadType: PlaceLoadType.recommendations,
          message: PlaceLoadType.recommendations.emptyMessage,
        ));
      } else {
        // Convert string reason to enum
        final reasonEnum = _mapStringToRecommendationReason(recommendations.reason);
        
        emit(PlaceRecommendationsLoaded(
          places: recommendations.places,
          userId: event.userId,
          reason: reasonEnum,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to get place recommendations', e);
      AppLogger.serviceOperation('PlaceService', 'getPlaceRecommendations', false);
      emit(PlaceError(message: _getErrorMessage(e)));
    }
  }

  RecommendationReason _mapStringToRecommendationReason(String reason) {
    if (reason.toLowerCase().contains('history')) {
      return RecommendationReason.basedOnHistory;
    } else if (reason.toLowerCase().contains('favorites')) {
      return RecommendationReason.basedOnFavorites;
    } else if (reason.toLowerCase().contains('location')) {
      return RecommendationReason.basedOnLocation;
    } else if (reason.toLowerCase().contains('trending')) {
      return RecommendationReason.trending;
    } else {
      return RecommendationReason.popular;
    }
  }

  Future<void> _onUploadPlaceImage(
    UploadPlaceImageEvent event,
    Emitter<PlaceState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Uploading place image: ${event.imagePath}');
    
    emit(const PlaceImageUploadLoading(progress: 0.0));
    
    try {
      final imageUrl = await _placeService.uploadPlaceImage(event.imagePath);
      
      stopwatch.stop();
      AppLogger.performance('Upload Place Image', stopwatch.elapsed);
      AppLogger.serviceOperation('PlaceService', 'uploadPlaceImage', true);
      AppLogger.info('Place image uploaded successfully');
      
      emit(PlaceImageUploaded(imageUrl: imageUrl));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to upload place image', e);
      AppLogger.serviceOperation('PlaceService', 'uploadPlaceImage', false);
      emit(PlaceImageUploadError(
        message: _getErrorMessage(e),
        imagePath: event.imagePath,
      ));
    }
  }

  Future<void> _onRefreshPlaces(
    RefreshPlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    AppLogger.info('Refreshing places');
    
    // Refresh based on current state
    if (state is PlacesLoaded) {
      final currentState = state as PlacesLoaded;
      switch (currentState.loadType) {
        case PlaceLoadType.popular:
          add(const LoadPopularPlacesEvent());
          break;
        case PlaceLoadType.trending:
          add(const LoadTrendingPlacesEvent());
          break;
        case PlaceLoadType.nearby:
          if (_userLatitude != null && _userLongitude != null) {
            add(LoadNearbyPlacesEvent(
              latitude: _userLatitude!,
              longitude: _userLongitude!,
            ));
          }
          break;
        default:
          AppLogger.warning('Cannot refresh places for type: ${currentState.loadType}');
      }
    }
  }

  Future<void> _onClearPlaceError(
    ClearPlaceErrorEvent event,
    Emitter<PlaceState> emit,
  ) async {
    AppLogger.info('Clearing place error');
    emit(const PlaceInitial());
  }

  Future<void> _onResetPlaceFilters(
    ResetPlaceFiltersEvent event,
    Emitter<PlaceState> emit,
  ) async {
    AppLogger.info('Resetting place filters');
    
    _currentFilters = const PlaceFilters();
    _currentSortType = PlaceSortType.popularity;
    _currentSearchQuery = '';
    
    if (_allPlaces.isNotEmpty) {
      emit(PlacesLoaded(
        places: _sortPlaces(_allPlaces, _currentSortType),
        loadType: PlaceLoadType.all,
      ));
    }
  }

  Future<void> _onLoadMorePlaces(
    LoadMorePlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    AppLogger.info('Loading more places');
    
    // Implement pagination logic based on current state
    if (state is PlacesLoaded) {
      final currentState = state as PlacesLoaded;
      AppLogger.info('Current places count: ${currentState.places.length}');
      // Additional pagination logic would go here
    }
  }

  void _applyFiltersAndSort(Emitter<PlaceState> emit) {
    if (_allPlaces.isEmpty) {
      emit(NoPlacesFound(
        searchQuery: _currentSearchQuery,
        filters: _currentFilters,
      ));
      return;
    }
    
    List<Place> filteredPlaces = _allPlaces;
    
    // Apply filters
    if (_currentFilters.categories.isNotEmpty) {
      filteredPlaces = filteredPlaces
          .where((place) => _currentFilters.categories.contains(place.category))
          .toList();
    }
    
    if (_currentFilters.minRating != null) {
      filteredPlaces = filteredPlaces
          .where((place) => place.averageRating >= _currentFilters.minRating!)
          .toList();
    }
    
    if (_currentFilters.maxDistance != null && _userLatitude != null && _userLongitude != null) {
      filteredPlaces = filteredPlaces
          .where((place) => place.calculateDistance(_userLatitude!, _userLongitude!) <= _currentFilters.maxDistance!)
          .toList();
    }
    
    // Apply sorting
    filteredPlaces = _sortPlaces(filteredPlaces, _currentSortType);
    
    if (filteredPlaces.isEmpty) {
      emit(NoPlacesFound(
        searchQuery: _currentSearchQuery,
        filters: _currentFilters,
      ));
    } else {
      emit(FilteredPlacesLoaded(
        places: filteredPlaces,
        allPlaces: _allPlaces,
        filters: _currentFilters,
      ));
    }
  }

  List<Place> _sortPlaces(List<Place> places, PlaceSortType sortType) {
    final sortedPlaces = List<Place>.from(places);
    
    switch (sortType) {
      case PlaceSortType.name:
        sortedPlaces.sort((a, b) => a.name.compareTo(b.name));
        break;
      case PlaceSortType.distance:
        if (_userLatitude != null && _userLongitude != null) {
          sortedPlaces.sort((a, b) {
            final distanceA = a.calculateDistance(_userLatitude!, _userLongitude!);
            final distanceB = b.calculateDistance(_userLatitude!, _userLongitude!);
            return distanceA.compareTo(distanceB);
          });
        }
        break;
      case PlaceSortType.popularity:
        sortedPlaces.sort((a, b) => b.visitCount.compareTo(a.visitCount));
        break;
      case PlaceSortType.rating:
        sortedPlaces.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case PlaceSortType.newest:
        sortedPlaces.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case PlaceSortType.oldest:
        sortedPlaces.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    
    return sortedPlaces;
  }

  void _validatePlaceData(String name, String description, String address) {
    _validatePlaceName(name);
    _validatePlaceDescription(description);
    _validatePlaceAddress(address);
  }

  void _validatePlaceName(String name) {
    if (name.trim().isEmpty) {
      throw const ValidationException('Place name is required');
    }
    
    if (name.trim().length < 2) {
      throw const ValidationException('Place name must be at least 2 characters');
    }
    
    if (name.trim().length > 100) {
      throw const ValidationException('Place name cannot exceed 100 characters');
    }
  }

  void _validatePlaceDescription(String description) {
    if (description.trim().isEmpty) {
      throw const ValidationException('Place description is required');
    }
    
    if (description.trim().length < 10) {
      throw const ValidationException('Description must be at least 10 characters');
    }
    
    if (description.trim().length > 500) {
      throw const ValidationException('Description cannot exceed 500 characters');
    }
  }

  void _validatePlaceAddress(String address) {
    if (address.trim().isEmpty) {
      throw const ValidationException('Place address is required');
    }
    
    if (address.trim().length < 5) {
      throw const ValidationException('Address must be at least 5 characters');
    }
  }

  Map<String, String> _extractFieldErrors(String message) {
    final fieldErrors = <String, String>{};
    
    if (message.contains('name')) {
      fieldErrors['name'] = message;
    } else if (message.contains('description')) {
      fieldErrors['description'] = message;
    } else if (message.contains('address')) {
      fieldErrors['address'] = message;
    }
    
    return fieldErrors;
  }

  String _getErrorMessage(dynamic error) {
    if (error is PlaceException) {
      return error.message;
    } else if (error is DatabaseException) {
      return 'Database error: ${error.message}';
    } else if (error is AuthenticationException) {
      return 'Authentication error: ${error.message}';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Future<void> close() {
    AppLogger.info('PlaceBloc disposed');
    return super.close();
  }
}