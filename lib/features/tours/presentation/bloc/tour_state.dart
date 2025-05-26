import 'package:equatable/equatable.dart';
import '../../domain/entities/tour.dart';

/// Base class for all tour states
abstract class TourState extends Equatable {
  const TourState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the BLoC is first created
class TourInitial extends TourState {
  const TourInitial();

  @override
  String toString() => 'TourInitial()';
}

/// State when tour operation is in progress
class TourLoading extends TourState {
  const TourLoading();

  @override
  String toString() => 'TourLoading()';
}

/// State when tours are successfully loaded
class ToursLoaded extends TourState {
  final List<Tour> tours;

  const ToursLoaded({required this.tours});

  @override
  List<Object> get props => [tours];

  @override
  String toString() => 'ToursLoaded(tours: ${tours.length})';
}

/// State when a single tour is successfully loaded
class TourLoaded extends TourState {
  final Tour tour;

  const TourLoaded({required this.tour});

  @override
  List<Object> get props => [tour];

  @override
  String toString() => 'TourLoaded(tour: ${tour.title})';
}

/// State when a tour is successfully created
class TourCreateSuccess extends TourState {
  final Tour tour;

  const TourCreateSuccess({required this.tour});

  @override
  List<Object> get props => [tour];

  @override
  String toString() => 'TourCreateSuccess(tour: ${tour.title})';
}

/// State when a tour is successfully saved as draft
class TourDraftSaved extends TourState {
  final Tour tour;

  const TourDraftSaved({required this.tour});

  @override
  List<Object> get props => [tour];

  @override
  String toString() => 'TourDraftSaved(tour: ${tour.title})';
}

/// State when a tour is successfully published
class TourPublished extends TourState {
  final Tour tour;

  const TourPublished({required this.tour});

  @override
  List<Object> get props => [tour];

  @override
  String toString() => 'TourPublished(tour: ${tour.title})';
}

/// State when a tour is successfully updated
class TourUpdateSuccess extends TourState {
  final Tour tour;

  const TourUpdateSuccess({required this.tour});

  @override
  List<Object> get props => [tour];

  @override
  String toString() => 'TourUpdateSuccess(tour: ${tour.title})';
}

/// State when a tour is successfully deleted
class TourDeleteSuccess extends TourState {
  final String tourId;

  const TourDeleteSuccess({required this.tourId});

  @override
  List<Object> get props => [tourId];

  @override
  String toString() => 'TourDeleteSuccess(tourId: $tourId)';
}

/// State when tour validation fails
class TourValidationError extends TourState {
  final List<String> errors;

  const TourValidationError({required this.errors});

  @override
  List<Object> get props => [errors];

  @override
  String toString() => 'TourValidationError(errors: $errors)';
}

/// State when a tour operation fails
class TourError extends TourState {
  final String message;
  final String? errorCode;

  const TourError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];

  @override
  String toString() => 'TourError(message: $message, errorCode: $errorCode)';
}

/// State when tour search results are loaded
class TourSearchResults extends TourState {
  final List<Tour> tours;
  final String searchQuery;

  const TourSearchResults({
    required this.tours,
    required this.searchQuery,
  });

  @override
  List<Object> get props => [tours, searchQuery];

  @override
  String toString() => 'TourSearchResults(tours: ${tours.length}, query: $searchQuery)';
}