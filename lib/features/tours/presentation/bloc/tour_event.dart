import 'package:equatable/equatable.dart';
import '../../data/models/tour_request.dart';

/// Base class for all tour events
abstract class TourEvent extends Equatable {
  const TourEvent();

  @override
  List<Object?> get props => [];
}

/// Event to create a new tour
class CreateTourEvent extends TourEvent {
  final TourCreateRequest request;

  const CreateTourEvent({required this.request});

  @override
  List<Object> get props => [request];

  @override
  String toString() => 'CreateTourEvent(request: $request)';
}

/// Event to save a tour as draft
class SaveAsDraftTourEvent extends TourEvent {
  final TourCreateRequest request;

  const SaveAsDraftTourEvent({required this.request});

  @override
  List<Object> get props => [request];

  @override
  String toString() => 'SaveAsDraftTourEvent(request: $request)';
}

/// Event to publish a tour
class PublishTourEvent extends TourEvent {
  final TourCreateRequest request;

  const PublishTourEvent({required this.request});

  @override
  List<Object> get props => [request];

  @override
  String toString() => 'PublishTourEvent(request: $request)';
}

/// Event to load tours
class LoadToursEvent extends TourEvent {
  const LoadToursEvent();

  @override
  String toString() => 'LoadToursEvent()';
}

/// Event to load a specific tour by ID
class LoadTourByIdEvent extends TourEvent {
  final String tourId;

  const LoadTourByIdEvent({required this.tourId});

  @override
  List<Object> get props => [tourId];

  @override
  String toString() => 'LoadTourByIdEvent(tourId: $tourId)';
}

/// Event to update an existing tour
class UpdateTourEvent extends TourEvent {
  final String tourId;
  final TourUpdateRequest request;

  const UpdateTourEvent({
    required this.tourId,
    required this.request,
  });

  @override
  List<Object> get props => [tourId, request];

  @override
  String toString() => 'UpdateTourEvent(tourId: $tourId, request: $request)';
}

/// Event to delete a tour
class DeleteTourEvent extends TourEvent {
  final String tourId;

  const DeleteTourEvent({required this.tourId});

  @override
  List<Object> get props => [tourId];

  @override
  String toString() => 'DeleteTourEvent(tourId: $tourId)';
}

/// Event to search tours by address
class SearchToursEvent extends TourEvent {
  final String searchQuery;

  const SearchToursEvent({required this.searchQuery});

  @override
  List<Object> get props => [searchQuery];

  @override
  String toString() => 'SearchToursEvent(searchQuery: $searchQuery)';
}