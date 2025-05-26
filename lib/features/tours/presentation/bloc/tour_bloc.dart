import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../services/tour_service.dart';
import 'tour_event.dart';
import 'tour_state.dart';

/// BLoC to handle tour-related business logic
class TourBloc extends Bloc<TourEvent, TourState> {
  final TourService _tourService;
  final AuthBloc _authBloc;

  TourBloc({
    required TourService tourService,
    required AuthBloc authBloc,
  })  : _tourService = tourService,
        _authBloc = authBloc,
        super(const TourInitial()) {
    
    // Log BLoC initialization
    AppLogger.info('TourBloc initialized');
    
    // Register event handlers
    on<CreateTourEvent>(_onCreateTour);
    on<SaveAsDraftTourEvent>(_onSaveAsDraft);
    on<PublishTourEvent>(_onPublishTour);
    on<LoadToursEvent>(_onLoadTours);
    on<LoadTourByIdEvent>(_onLoadTourById);
    on<UpdateTourEvent>(_onUpdateTour);
    on<DeleteTourEvent>(_onDeleteTour);
    on<SearchToursEvent>(_onSearchTours);
  }

  @override
  void onChange(Change<TourState> change) {
    super.onChange(change);
    // Log state transitions
    AppLogger.blocTransition(
      'TourBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(TourEvent event) {
    super.onEvent(event);
    // Log events
    AppLogger.blocEvent('TourBloc', event.runtimeType.toString());
  }

  /// Handle tour creation
  Future<void> _onCreateTour(
    CreateTourEvent event,
    Emitter<TourState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Starting tour creation');
    
    emit(const TourLoading());
    
    try {
      // Get current user ID
      final userId = _getCurrentUserId();
      if (userId == null) {
        emit(const TourError(message: 'User not authenticated'));
        return;
      }

      // Validate request
      _validateTourRequest(event.request);

      // Create tour
      final tour = await _tourService.createTour(event.request, userId);
      
      stopwatch.stop();
      AppLogger.performance('Tour Creation', stopwatch.elapsed);
      AppLogger.serviceOperation('TourService', 'createTour', true);
      
      emit(TourCreateSuccess(tour: tour));
    } on TourValidationException catch (e) {
      AppLogger.error('Tour validation failed', e);
      emit(TourValidationError(errors: [e.message]));
    } on TourServiceException catch (e) {
      AppLogger.error('Tour service error', e);
      emit(TourError(message: e.message));
    } catch (e) {
      AppLogger.error('Tour creation failed', e);
      AppLogger.serviceOperation('TourService', 'createTour', false);
      emit(TourError(message: 'An unexpected error occurred while creating the tour'));
    }
  }

  /// Handle saving tour as draft
  Future<void> _onSaveAsDraft(
    SaveAsDraftTourEvent event,
    Emitter<TourState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Starting tour draft save');
    
    emit(const TourLoading());
    
    try {
      // Get current user ID
      final userId = _getCurrentUserId();
      if (userId == null) {
        emit(const TourError(message: 'User not authenticated'));
        return;
      }

      // For drafts, we're more lenient with validation
      _validateBasicTourRequest(event.request);

      // Save as draft
      final tour = await _tourService.saveAsDraft(event.request, userId);
      
      stopwatch.stop();
      AppLogger.performance('Tour Draft Save', stopwatch.elapsed);
      AppLogger.serviceOperation('TourService', 'saveAsDraft', true);
      
      emit(TourDraftSaved(tour: tour));
    } on TourValidationException catch (e) {
      AppLogger.error('Tour draft validation failed', e);
      emit(TourValidationError(errors: [e.message]));
    } on TourServiceException catch (e) {
      AppLogger.error('Tour draft service error', e);
      emit(TourError(message: e.message));
    } catch (e) {
      AppLogger.error('Tour draft save failed', e);
      AppLogger.serviceOperation('TourService', 'saveAsDraft', false);
      emit(TourError(message: 'An unexpected error occurred while saving the draft'));
    }
  }

  /// Handle tour publishing
  Future<void> _onPublishTour(
    PublishTourEvent event,
    Emitter<TourState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Starting tour publish');
    
    emit(const TourLoading());
    
    try {
      // Get current user ID
      final userId = _getCurrentUserId();
      if (userId == null) {
        emit(const TourError(message: 'User not authenticated'));
        return;
      }

      // Full validation for publishing
      _validateTourRequest(event.request);

      // Publish tour
      final tour = await _tourService.publishTour(event.request, userId);
      
      stopwatch.stop();
      AppLogger.performance('Tour Publish', stopwatch.elapsed);
      AppLogger.serviceOperation('TourService', 'publishTour', true);
      
      emit(TourPublished(tour: tour));
    } on TourValidationException catch (e) {
      AppLogger.error('Tour publish validation failed', e);
      emit(TourValidationError(errors: [e.message]));
    } on TourServiceException catch (e) {
      AppLogger.error('Tour publish service error', e);
      emit(TourError(message: e.message));
    } catch (e) {
      AppLogger.error('Tour publish failed', e);
      AppLogger.serviceOperation('TourService', 'publishTour', false);
      emit(TourError(message: 'An unexpected error occurred while publishing the tour'));
    }
  }

  /// Handle loading tours
  Future<void> _onLoadTours(
    LoadToursEvent event,
    Emitter<TourState> emit,
  ) async {
    emit(const TourLoading());
    
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        emit(const TourError(message: 'User not authenticated'));
        return;
      }

      final tours = await _tourService.getToursByGuide(userId);
      emit(ToursLoaded(tours: tours));
    } catch (e) {
      AppLogger.error('Tours loading failed', e);
      emit(TourError(message: 'Failed to load tours'));
    }
  }

  /// Handle loading tour by ID
  Future<void> _onLoadTourById(
    LoadTourByIdEvent event,
    Emitter<TourState> emit,
  ) async {
    emit(const TourLoading());
    
    try {
      final tour = await _tourService.getTourById(event.tourId);
      if (tour != null) {
        emit(TourLoaded(tour: tour));
      } else {
        emit(const TourError(message: 'Tour not found'));
      }
    } catch (e) {
      AppLogger.error('Tour loading failed', e);
      emit(TourError(message: 'Failed to load tour'));
    }
  }

  /// Handle tour update (placeholder)
  Future<void> _onUpdateTour(
    UpdateTourEvent event,
    Emitter<TourState> emit,
  ) async {
    // TODO: Implement tour update logic
    emit(const TourError(message: 'Tour update not implemented yet'));
  }

  /// Handle tour deletion (placeholder)
  Future<void> _onDeleteTour(
    DeleteTourEvent event,
    Emitter<TourState> emit,
  ) async {
    // TODO: Implement tour deletion logic
    emit(const TourError(message: 'Tour deletion not implemented yet'));
  }

  /// Handle tour search
  Future<void> _onSearchTours(
    SearchToursEvent event,
    Emitter<TourState> emit,
  ) async {
    emit(const TourLoading());
    
    try {
      final tours = await _tourService.searchTours(event.searchQuery);
      emit(TourSearchResults(tours: tours, searchQuery: event.searchQuery));
    } catch (e) {
      AppLogger.error('Tour search failed', e);
      emit(TourError(message: 'Failed to search tours'));
    }
  }

  /// Get current authenticated user ID
  String? _getCurrentUserId() {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  /// Validate tour request for full operations (create/publish)
  void _validateTourRequest(dynamic request) {
    if (request.title.trim().length < 3) {
      throw TourValidationException('Title must be at least 3 characters');
    }
    if (request.description.trim().length < 20) {
      throw TourValidationException('Description must be at least 20 characters');
    }
    if (!request.location.isValid) {
      throw TourValidationException('Valid location is required');
    }
  }

  /// Basic validation for drafts
  void _validateBasicTourRequest(dynamic request) {
    if (request.title.trim().isEmpty) {
      throw TourValidationException('Title is required');
    }
    if (request.description.trim().isEmpty) {
      throw TourValidationException('Description is required');
    }
  }
}

/// Custom exception for tour validation
class TourValidationException implements Exception {
  final String message;

  const TourValidationException(this.message);

  @override
  String toString() => 'TourValidationException: $message';
}