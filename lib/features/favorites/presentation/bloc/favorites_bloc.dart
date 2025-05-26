import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/user_service.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

/// Simple favorites BLoC following TourPal's KEEP THINGS SIMPLE principle
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final UserService _userService;

  FavoritesBloc({required UserService userService})
      : _userService = userService,
        super(const FavoritesInitial()) {
    on<LoadFavoritesEvent>(_onLoadFavorites);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    
    AppLogger.info('FavoritesBloc initialized');
  }

  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      AppLogger.info('Loading user favorites');
      emit(const FavoritesLoading());
      
      final user = await _userService.getCurrentUser();
      if (user != null) {
        emit(FavoritesLoaded(favoriteTourIds: user.favoriteTours));
        AppLogger.info('Loaded ${user.favoriteTours.length} favorites');
      } else {
        emit(const FavoritesLoaded(favoriteTourIds: []));
      }
    } catch (e) {
      AppLogger.error('Failed to load favorites: $e');
      emit(FavoritesError(message: 'Failed to load favorites: $e'));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! FavoritesLoaded) return;

      AppLogger.info('Toggling favorite for tour: ${event.tourId}');
      
      final currentFavorites = List<String>.from(currentState.favoriteTourIds);
      final isFavorite = currentFavorites.contains(event.tourId);
      
      if (isFavorite) {
        currentFavorites.remove(event.tourId);
        AppLogger.info('Removed from favorites: ${event.tourId}');
      } else {
        currentFavorites.add(event.tourId);
        AppLogger.info('Added to favorites: ${event.tourId}');
      }

      // Update state immediately for smooth UX
      emit(FavoritesLoaded(favoriteTourIds: currentFavorites));
      
      // Update in backend
      await _userService.updateFavorites(currentFavorites);
      
    } catch (e) {
      AppLogger.error('Failed to toggle favorite: $e');
      emit(FavoritesError(message: 'Failed to update favorite'));
      
      // Reload favorites to restore correct state
      add(const LoadFavoritesEvent());
    }
  }
}