import 'package:equatable/equatable.dart';
import 'package:tourpal/features/tours/domain/enums/tour_status.dart';
import '../../../../models/tour_plan.dart';

/// Tour Plan BLoC States following TourPal development rules
/// 
/// All states extend Equatable for proper state comparison
/// and follow the naming convention: [Entity][State]
abstract class TourPlanState extends Equatable {
  const TourPlanState();

  @override
  List<Object?> get props => [];
}

/// Initial state when TourPlanBloc is first created
class TourPlanInitial extends TourPlanState {
  const TourPlanInitial();
}

/// Loading state during tour plan operations
class TourPlanLoading extends TourPlanState {
  const TourPlanLoading();
}

/// State when a single tour plan is loaded successfully
class TourPlanLoaded extends TourPlanState {
  final TourPlan tourPlan;

  const TourPlanLoaded({required this.tourPlan});

  @override
  List<Object> get props => [tourPlan];
}

// BLoC-compatible states (as expected by TourPlanBloc)
class TourPlanDetailLoaded extends TourPlanState {
  final TourPlan tourPlan;

  const TourPlanDetailLoaded({required this.tourPlan});

  @override
  List<Object> get props => [tourPlan];
}

class TourPlanCreated extends TourPlanState {
  final TourPlan tourPlan;

  const TourPlanCreated({required this.tourPlan});

  @override
  List<Object> get props => [tourPlan];
}

class TourPlanUpdated extends TourPlanState {
  final TourPlan tourPlan;

  const TourPlanUpdated({required this.tourPlan});

  @override
  List<Object> get props => [tourPlan];
}

class TourPlanDeleted extends TourPlanState {
  const TourPlanDeleted();
}

class TourPlanSearchResults extends TourPlanState {
  final List<TourPlan> tourPlans;

  const TourPlanSearchResults({required this.tourPlans});

  @override
  List<Object> get props => [tourPlans];
}

// Existing states
class TourPlansLoaded extends TourPlanState {
  final List<TourPlan> tourPlans;

  const TourPlansLoaded({required this.tourPlans});

  @override
  List<Object> get props => [tourPlans];
}

class TourPlanOperationSuccess extends TourPlanState {
  final String message;
  final TourPlan? tourPlan;

  const TourPlanOperationSuccess({
    required this.message,
    this.tourPlan,
  });

  @override
  List<Object?> get props => [message, tourPlan];
}

class TourPlanError extends TourPlanState {
  final String message;
  final String? errorCode;

  const TourPlanError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class TourPlanEmpty extends TourPlanState {
  final String message;

  const TourPlanEmpty({
    this.message = 'No tour plans found',
  });

  @override
  List<Object> get props => [message];
}

class TourPlanRefreshing extends TourPlanState {
  final List<TourPlan> currentTourPlans;

  const TourPlanRefreshing({required this.currentTourPlans});

  @override
  List<Object> get props => [currentTourPlans];
}

class TourPlanPublished extends TourPlanState {
  final String tourId;
  final String message;

  const TourPlanPublished({
    required this.tourId,
    this.message = 'Tour published successfully',
  });

  @override
  List<Object> get props => [tourId, message];
}

class TourPlanSavedAsDraft extends TourPlanState {
  final String tourId;
  final String message;

  const TourPlanSavedAsDraft({
    required this.tourId,
    this.message = 'Tour saved as draft',
  });

  @override
  List<Object> get props => [tourId, message];
}

class TourPlanStatusUpdated extends TourPlanState {
  final String tourId;
  final TourStatus status;
  final String message;

  const TourPlanStatusUpdated({
    required this.tourId,
    required this.status,
    required this.message,
  });

  @override
  List<Object> get props => [tourId, status, message];
}