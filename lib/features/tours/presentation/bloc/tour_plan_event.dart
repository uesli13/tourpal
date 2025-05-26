import 'package:equatable/equatable.dart';
import 'package:tourpal/features/tours/domain/enums/tour_status.dart';
import '../../../../models/requests/tour_plan_create_request.dart';
import '../../../../models/requests/tour_plan_update_request.dart';
import '../../../../models/requests/tour_plan_search_filters.dart';

/// Tour Plan BLoC Events following TourPal development rules
/// 
/// All events extend Equatable for proper state comparison
/// and follow the naming convention: [Action][Entity][Event]
abstract class TourPlanEvent extends Equatable {
  const TourPlanEvent();

  @override
  List<Object?> get props => [];
}

// BLoC-compatible event names (as expected by TourPlanBloc)
class LoadTourPlansEvent extends TourPlanEvent {
  final String userId;

  const LoadTourPlansEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LoadTourPlanDetailEvent extends TourPlanEvent {
  final String tourPlanId;

  const LoadTourPlanDetailEvent({required this.tourPlanId});

  @override
  List<Object> get props => [tourPlanId];
}

class CreateTourPlanEvent extends TourPlanEvent {
  final TourPlanCreateRequest request;

  const CreateTourPlanEvent({required this.request});

  @override
  List<Object> get props => [request];
}

class UpdateTourPlanEvent extends TourPlanEvent {
  final String tourPlanId;
  final TourPlanUpdateRequest request;

  const UpdateTourPlanEvent({
    required this.tourPlanId,
    required this.request,
  });

  @override
  List<Object> get props => [tourPlanId, request];
}

class DeleteTourPlanEvent extends TourPlanEvent {
  final String tourPlanId;
  final String guideId;

  const DeleteTourPlanEvent({
    required this.tourPlanId,
    required this.guideId,
  });

  @override
  List<Object> get props => [tourPlanId, guideId];
}

class SearchTourPlansEvent extends TourPlanEvent {
  final TourPlanSearchFilters filters;

  const SearchTourPlansEvent({required this.filters});

  @override
  List<Object> get props => [filters];
}

/// Load tour plans for a specific guide
class LoadTourPlans extends TourPlanEvent {
  final String guideId;

  const LoadTourPlans({required this.guideId});

  @override
  List<Object> get props => [guideId];
}

/// Load a specific tour plan by ID
class LoadTourPlanById extends TourPlanEvent {
  final String tourPlanId;

  const LoadTourPlanById({required this.tourPlanId});

  @override
  List<Object> get props => [tourPlanId];
}

/// Create a new tour plan
class CreateTourPlan extends TourPlanEvent {
  final TourPlanCreateRequest request;

  const CreateTourPlan({required this.request});

  @override
  List<Object> get props => [request];
}

/// Update an existing tour plan
class UpdateTourPlan extends TourPlanEvent {
  final String tourPlanId;
  final TourPlanUpdateRequest request;

  const UpdateTourPlan({
    required this.tourPlanId,
    required this.request,
  });

  @override
  List<Object> get props => [tourPlanId, request];
}

/// Delete a tour plan
class DeleteTourPlan extends TourPlanEvent {
  final String tourPlanId;
  final String guideId;

  const DeleteTourPlan({
    required this.tourPlanId,
    required this.guideId,
  });

  @override
  List<Object> get props => [tourPlanId, guideId];
}

/// Search tour plans with filters
class SearchTourPlans extends TourPlanEvent {
  final TourPlanSearchFilters filters;

  const SearchTourPlans({required this.filters});

  @override
  List<Object> get props => [filters];
}

/// Refresh tour plans
class RefreshTourPlans extends TourPlanEvent {
  final String? guideId;

  const RefreshTourPlans({this.guideId});

  @override
  List<Object?> get props => [guideId];
}

/// Clear tour plan state
class ClearTourPlanState extends TourPlanEvent {
  const ClearTourPlanState();
}

/// Reset tour plan error
class ResetTourPlanError extends TourPlanEvent {
  const ResetTourPlanError();
}

/// Publish a tour
class PublishTourEvent extends TourPlanEvent {
  final String tourId;

  const PublishTourEvent({required this.tourId});

  @override
  List<Object> get props => [tourId];
}

/// Save a tour as draft
class SaveAsDraftTourEvent extends TourPlanEvent {
  final String tourId;

  const SaveAsDraftTourEvent({required this.tourId});

  @override
  List<Object> get props => [tourId];
}

/// Update the status of a tour
class UpdateTourStatusEvent extends TourPlanEvent {
  final String tourId;
  final TourStatus status;

  const UpdateTourStatusEvent({
    required this.tourId,
    required this.status,
  });

  @override
  List<Object> get props => [tourId, status];
}