import 'package:equatable/equatable.dart';
import 'package:tourpal/features/tours/domain/entities/tour.dart';

/// Tour Creation States following TourPal BLoC architecture rules
abstract class TourCreationState extends Equatable {
  const TourCreationState();

  @override
  List<Object?> get props => [];
}

/// Initial state when TourCreationBloc is first created
class TourCreationInitial extends TourCreationState {
  const TourCreationInitial();
}

/// Loading state during tour creation operations
class TourCreationLoading extends TourCreationState {
  const TourCreationLoading();
}

/// State when tour is successfully created and published
class TourCreationSuccess extends TourCreationState {
  final Tour tour;
  final String message;

  const TourCreationSuccess({
    required this.tour,
    this.message = 'Tour published successfully',
  });

  @override
  List<Object> get props => [tour, message];
}

/// State when tour is successfully saved as draft
class TourDraftSaved extends TourCreationState {
  final Tour tour;
  final String message;

  const TourDraftSaved({
    required this.tour,
    this.message = 'Tour saved as draft',
  });

  @override
  List<Object> get props => [tour, message];
}

/// Error state when tour creation fails
class TourCreationError extends TourCreationState {
  final String message;
  final String? errorCode;

  const TourCreationError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}