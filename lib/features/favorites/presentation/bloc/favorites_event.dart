import 'package:equatable/equatable.dart';

/// Simple favorites events following TourPal's KEEP THINGS SIMPLE principle
abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object> get props => [];
}

/// Toggle favorite status for a tour
class ToggleFavoriteEvent extends FavoritesEvent {
  final String tourId;

  const ToggleFavoriteEvent({required this.tourId});

  @override
  List<Object> get props => [tourId];
}

/// Load user's favorite tours
class LoadFavoritesEvent extends FavoritesEvent {
  const LoadFavoritesEvent();
}