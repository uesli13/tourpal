import 'package:equatable/equatable.dart';
import 'package:tourpal/core/utils/bloc_error_handler.dart';
import 'package:tourpal/core/exceptions/app_exceptions.dart';
import 'package:tourpal/core/utils/error_handler.dart';
import 'package:tourpal/models/tour_plan.dart';

abstract class TourState extends Equatable {
  const TourState();

  @override
  List<Object?> get props => [];
}

class TourInitial extends TourState {
  const TourInitial();
}

class TourLoading extends TourState {
  const TourLoading();
}

class TourLoaded extends TourState {
  final List<TourPlan> tours;
  final List<TourPlan> filteredTours;
  final String? searchQuery;
  final TourStatus? statusFilter;

  const TourLoaded({
    required this.tours,
    required this.filteredTours,
    this.searchQuery,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [tours, filteredTours, searchQuery, statusFilter];

  TourLoaded copyWith({
    List<TourPlan>? tours,
    List<TourPlan>? filteredTours,
    String? searchQuery,
    TourStatus? statusFilter,
  }) {
    return TourLoaded(
      tours: tours ?? this.tours,
      filteredTours: filteredTours ?? this.filteredTours,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class TourError extends TourState implements BaseErrorState {
  @override
  final String message;
  @override
  final String? errorCode;
  @override
  final ErrorSeverity severity;
  @override
  final bool canRetry;
  @override
  final Map<String, dynamic>? context;

  const TourError({
    required this.message,
    this.errorCode,
    this.severity = ErrorSeverity.error,
    this.canRetry = true,
    this.context,
  });

  /// Factory constructor for creating TourError from AppException
  factory TourError.fromException(AppException exception) {
    return TourError(
      message: exception.userMessage,
      errorCode: exception.code,
      severity: exception.severity,
      canRetry: ErrorHandler.shouldRetry(exception),
      context: exception.context,
    );
  }

  @override
  List<Object?> get props => [message, errorCode, severity, canRetry, context];
}

class TourDetailsLoading extends TourState {
  const TourDetailsLoading();
}

class TourDetailsLoaded extends TourState {
  final TourPlan tour;

  const TourDetailsLoaded(this.tour);

  @override
  List<Object> get props => [tour];
}

class TourActionSuccess extends TourState {
  final String message;

  const TourActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}