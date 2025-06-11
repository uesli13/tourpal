import 'package:equatable/equatable.dart';

abstract class TourCreationState extends Equatable {
  const TourCreationState();

  @override
  List<Object?> get props => [];
}

class TourCreationInitial extends TourCreationState {}

class TourCreationLoading extends TourCreationState {}

class TourCreationValidating extends TourCreationState {}

class TourPublishingState extends TourCreationState {}

class TourSavingDraftState extends TourCreationState {}

class TourCreationValid extends TourCreationState {
  final bool canProceedToStep2;
  final bool canPublish;

  const TourCreationValid({
    required this.canProceedToStep2,
    required this.canPublish,
  });

  @override
  List<Object?> get props => [canProceedToStep2, canPublish];
}

class TourCreationSuccess extends TourCreationState {
  final String message;
  final String tourId;

  const TourCreationSuccess({
    required this.message,
    required this.tourId,
  });

  @override
  List<Object?> get props => [message, tourId];
}

class TourDraftSavedState extends TourCreationState {
  final String message;
  final String tourId;

  const TourDraftSavedState({
    required this.message,
    required this.tourId,
  });

  @override
  List<Object?> get props => [message, tourId];
}

class TourCreationError extends TourCreationState {
  final String message;

  const TourCreationError({required this.message});

  @override
  List<Object?> get props => [message];
}