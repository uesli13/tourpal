import 'package:equatable/equatable.dart';

/// Simple favorites states following TourPal's KEEP THINGS SIMPLE principle
abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object> get props => [];
}

/// Initial state
class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

/// Loading favorites
class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

/// Favorites loaded successfully
class FavoritesLoaded extends FavoritesState {
  final List<String> favoriteTourIds;

  const FavoritesLoaded({required this.favoriteTourIds});

  @override
  List<Object> get props => [favoriteTourIds];

  /// Check if tour is favorited
  bool isFavorite(String tourId) => favoriteTourIds.contains(tourId);
}

/// Error state
class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError({required this.message});

  @override
  List<Object> get props => [message];
}