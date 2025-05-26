import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourpal/features/tours/domain/enums/tour_status.dart';
import 'package:tourpal/models/requests/tour_plan_update_request.dart';
import '../../services/tour_plan_service.dart';
import '../../../../core/exceptions/tour_plan_exceptions.dart';
import 'tour_plan_event.dart';
import 'tour_plan_state.dart';

/// Handles all tour plan state management
/// 
/// This BLoC manages tour plan operations and communicates with
/// [TourPlanService] to perform CRUD operations on tour plans.
class TourPlanBloc extends Bloc<TourPlanEvent, TourPlanState> {
  final TourPlanService _tourPlanService;

  TourPlanBloc({
    required TourPlanService tourPlanService,
  })  : _tourPlanService = tourPlanService,
        super(const TourPlanInitial()) {
    
    on<LoadTourPlansEvent>(_onLoadTourPlans);
    on<LoadTourPlanDetailEvent>(_onLoadTourPlanDetail);
    on<CreateTourPlanEvent>(_onCreateTourPlan);
    on<UpdateTourPlanEvent>(_onUpdateTourPlan);
    on<DeleteTourPlanEvent>(_onDeleteTourPlan);
    on<SearchTourPlansEvent>(_onSearchTourPlans);
    on<PublishTourEvent>(_onPublishTour);
    on<SaveAsDraftTourEvent>(_onSaveAsDraft);
    on<UpdateTourStatusEvent>(_onUpdateTourStatus);
  }

  Future<void> _onLoadTourPlans(
    LoadTourPlansEvent event,
    Emitter<TourPlanState> emit,
  ) async {
    emit(const TourPlanLoading());
    
    try {
      final tourPlans = await _tourPlanService.getTourPlansByGuide(event.userId);
      emit(TourPlansLoaded(tourPlans: tourPlans));
    } on TourPlanValidationException catch (e) {
      emit(TourPlanError(message: e.message));
    } catch (e) {
      emit(TourPlanError(message: 'Failed to load tour plans: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTourPlanDetail(
    LoadTourPlanDetailEvent event,
    Emitter<TourPlanState> emit,
  ) async {
    emit(const TourPlanLoading());
    
    try {
      final tourPlan = await _tourPlanService.getTourPlanById(event.tourPlanId);
      emit(TourPlanDetailLoaded(tourPlan: tourPlan));
    } on TourPlanNotFoundException catch (e) {
      emit(TourPlanError(message: e.toString()));
    } catch (e) {
      emit(TourPlanError(message: 'Failed to load tour plan: ${e.toString()}'));
    }
  }

  Future<void> _onCreateTourPlan(
    CreateTourPlanEvent event,
    Emitter<TourPlanState> emit,
  ) async {
    emit(const TourPlanLoading());
    
    try {
      final tourPlan = await _tourPlanService.createTourPlan(event.request);
      emit(TourPlanCreated(tourPlan: tourPlan));
    } on TourPlanValidationException catch (e) {
      emit(TourPlanError(message: e.message));
    } catch (e) {
      emit(TourPlanError(message: 'Failed to create tour plan: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTourPlan(
    UpdateTourPlanEvent event,
    Emitter<TourPlanState> emit,
  ) async {
    emit(const TourPlanLoading());
    
    try {
      final tourPlan = await _tourPlanService.updateTourPlan(
        event.tourPlanId,
        event.request,
      );
      emit(TourPlanUpdated(tourPlan: tourPlan));
    } on TourPlanNotFoundException catch (e) {
      emit(TourPlanError(message: e.toString()));
    } on TourPlanValidationException catch (e) {
      emit(TourPlanError(message: e.message));
    } catch (e) {
      emit(TourPlanError(message: 'Failed to update tour plan: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTourPlan(
    DeleteTourPlanEvent event,
    Emitter<TourPlanState> emit,
  ) async {
    emit(const TourPlanLoading());
    
    try {
      await _tourPlanService.deleteTourPlan(event.tourPlanId, event.guideId);
      emit(const TourPlanDeleted());
    } on TourPlanNotFoundException catch (e) {
      emit(TourPlanError(message: e.toString()));
    } catch (e) {
      emit(TourPlanError(message: 'Failed to delete tour plan: ${e.toString()}'));
    }
  }

  Future<void> _onSearchTourPlans(
    SearchTourPlansEvent event,
    Emitter<TourPlanState> emit,
  ) async {
    emit(const TourPlanLoading());
    
    try {
      final tourPlans = await _tourPlanService.searchTourPlans(event.filters);
      emit(TourPlanSearchResults(tourPlans: tourPlans));
    } on TourPlanValidationException catch (e) {
      emit(TourPlanError(message: e.message));
    } catch (e) {
      emit(TourPlanError(message: 'Failed to search tour plans: ${e.toString()}'));
    }
  }

  Future<void> _onPublishTour(
    PublishTourEvent event,
    Emitter<TourPlanState> emit,
  ) async {
    try {
      emit(const TourPlanLoading());

      // Get current tour to validate it can be published
      final currentTour = await _tourPlanService.getTourPlanById(event.tourId);

      // Validate tour can be published
      if (!currentTour.isValidForPublication) {
        final errors = currentTour.validationErrors.join(', ');
        emit(TourPlanError(message: 'Cannot publish tour: $errors'));
        return;
      }

      // Update tour status to published
      final updatedTour = currentTour.copyWith(
        status: TourStatus.published,
        isPublic: true, // Make sure it's public when published
        updatedAt: DateTime.now(),
      );

      // Create update request and call service
      final updateRequest = TourPlanUpdateRequest.fromTourPlan(updatedTour);
      await _tourPlanService.updateTourPlan(event.tourId, updateRequest);
      
      emit(TourPlanPublished(
        tourId: event.tourId,
        message: 'Tour "${currentTour.title}" published successfully!',
      ));
    } catch (e) {
      emit(TourPlanError(
        message: 'Failed to publish tour: ${e.toString()}',
        errorCode: 'PUBLISH_FAILED',
      ));
    }
  }

  Future<void> _onSaveAsDraft(
    SaveAsDraftTourEvent event,
    Emitter<TourPlanState> emit,
  ) async {
    try {
      emit(const TourPlanLoading());

      // Get current tour
      final currentTour = await _tourPlanService.getTourPlanById(event.tourId);

      // Update tour status to draft
      final updatedTour = currentTour.copyWith(
        status: TourStatus.draft,
        isPublic: false, // Make sure it's private when saved as draft
        updatedAt: DateTime.now(),
      );

      // Create update request and call service
      final updateRequest = TourPlanUpdateRequest.fromTourPlan(updatedTour);
      await _tourPlanService.updateTourPlan(event.tourId, updateRequest);
      
      emit(TourPlanSavedAsDraft(
        tourId: event.tourId,
        message: 'Tour "${currentTour.title}" saved as draft',
      ));
    } catch (e) {
      emit(TourPlanError(
        message: 'Failed to save tour as draft: ${e.toString()}',
        errorCode: 'SAVE_DRAFT_FAILED',
      ));
    }
  }

  Future<void> _onUpdateTourStatus(
    UpdateTourStatusEvent event,
    Emitter<TourPlanState> emit,
  ) async {
    try {
      emit(const TourPlanLoading());

      // Get current tour
      final currentTour = await _tourPlanService.getTourPlanById(event.tourId);

      // Validate status change
      if (event.status == TourStatus.published && !currentTour.isValidForPublication) {
        final errors = currentTour.validationErrors.join(', ');
        emit(TourPlanError(message: 'Cannot publish tour: $errors'));
        return;
      }

      // Update tour status
      final updatedTour = currentTour.copyWith(
        status: event.status,
        isPublic: event.status == TourStatus.published,
        updatedAt: DateTime.now(),
      );

      // Create update request and call service
      final updateRequest = TourPlanUpdateRequest.fromTourPlan(updatedTour);
      await _tourPlanService.updateTourPlan(event.tourId, updateRequest);
      
      emit(TourPlanStatusUpdated(
        tourId: event.tourId,
        status: event.status,
        message: 'Tour status updated to ${event.status.displayName}',
      ));
    } catch (e) {
      emit(TourPlanError(
        message: 'Failed to update tour status: ${e.toString()}',
        errorCode: 'STATUS_UPDATE_FAILED',
      ));
    }
  }
}