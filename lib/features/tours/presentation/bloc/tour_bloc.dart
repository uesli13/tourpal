import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:tourpal/core/utils/logger.dart';
import 'package:tourpal/core/utils/bloc_error_handler.dart';
import 'package:tourpal/core/exceptions/app_exceptions.dart';
import 'package:tourpal/models/tour_plan.dart';

import '../../../auth/services/auth_service.dart';
import '../../domain/usecases/get_tours_usecase.dart';
import '../../domain/usecases/update_tour_usecase.dart';
import 'tour_event.dart';
import 'tour_state.dart';

class TourBloc extends Bloc<TourEvent, TourState> {
  final GetToursUsecase _getToursUsecase;
  final UpdateTourUsecase _updateTourUsecase;
  final AuthService _authService;

  TourBloc({
    required GetToursUsecase getToursUsecase,
    required UpdateTourUsecase updateTourUsecase,
    required AuthService authService,
  })  : _getToursUsecase = getToursUsecase,
        _updateTourUsecase = updateTourUsecase,
        _authService = authService,
        super(const TourInitial()) {
    
    AppLogger.info('TourBloc initialized with Clean Architecture usecases');
    
    on<LoadToursEvent>(_onLoadTours);
    on<LoadToursByGuideEvent>(_onLoadToursByGuide);
    on<LoadAllPublishedToursEvent>(_onLoadAllPublishedTours);
    on<LoadTourDetailsEvent>(_onLoadTourDetails);
    on<RefreshToursEvent>(_onRefreshTours);
    on<FilterToursEvent>(_onFilterTours);
    on<DeleteTourEvent>(_onDeleteTour);
    on<UpdateTourEvent>(_onUpdateTour);
  }

  @override
  void onChange(Change<TourState> change) {
    super.onChange(change);
    BlocErrorHandler.logTransition(
      'TourBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(TourEvent event) {
    super.onEvent(event);
    BlocErrorHandler.logEvent('TourBloc', event.runtimeType.toString());
  }

  Future<void> _onLoadTours(
    LoadToursEvent event,
    Emitter<TourState> emit,
  ) async {
    BlocErrorHandler.logEvent('TourBloc', 'LoadToursEvent');
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(const TourLoading());
        
        final currentUser = _authService.currentUser;
        if (currentUser == null) {
          throw const AuthenticationException('User not authenticated');
        }

        return await _getToursUsecase.getToursByGuideId(currentUser.uid);
      },
      onSuccess: (tours) => emit(TourLoaded(
        tours: tours,
        filteredTours: tours,
      )),
      onError: (error) => emit(TourError.fromException(error)),
      operationName: 'loadTours',
      serviceName: 'GetToursUsecase',
    );
  }

  Future<void> _onLoadToursByGuide(
    LoadToursByGuideEvent event,
    Emitter<TourState> emit,
  ) async {
    BlocErrorHandler.logEvent('TourBloc', 'LoadToursByGuideEvent', {'guideId': event.guideId});
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(const TourLoading());
        return await _getToursUsecase.getToursByGuideId(event.guideId);
      },
      onSuccess: (tours) => emit(TourLoaded(
        tours: tours,
        filteredTours: tours,
      )),
      onError: (error) => emit(TourError.fromException(error)),
      operationName: 'loadToursByGuide',
      serviceName: 'GetToursUsecase',
      context: {'guideId': event.guideId},
    );
  }

  Future<void> _onLoadAllPublishedTours(
    LoadAllPublishedToursEvent event,
    Emitter<TourState> emit,
  ) async {
    BlocErrorHandler.logEvent('TourBloc', 'LoadAllPublishedToursEvent');
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(const TourLoading());
        return await _getToursUsecase();
      },
      onSuccess: (tours) {
        // Filter out current user's tours for explore screen
        final currentUser = _authService.currentUser;
        final filteredTours = currentUser != null 
            ? tours.where((tour) => tour.guideId != currentUser.uid).toList()
            : tours;
        
        emit(TourLoaded(
          tours: filteredTours,
          filteredTours: filteredTours,
        ));
      },
      onError: (error) => emit(TourError.fromException(error)),
      operationName: 'loadAllPublishedTours',
      serviceName: 'GetToursUsecase',
    );
  }

  Future<void> _onLoadTourDetails(
    LoadTourDetailsEvent event,
    Emitter<TourState> emit,
  ) async {
    BlocErrorHandler.logEvent('TourBloc', 'LoadTourDetailsEvent', {'tourId': event.tourId});
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(const TourDetailsLoading());
        final tour = await _getToursUsecase.getTourById(event.tourId);
        if (tour == null) {
          throw const DatabaseException('Tour not found');
        }
        return tour;
      },
      onSuccess: (tour) => emit(TourDetailsLoaded(tour)),
      onError: (error) => emit(TourError.fromException(error)),
      operationName: 'loadTourDetails',
      serviceName: 'GetToursUsecase',
      context: {'tourId': event.tourId},
    );
  }

  Future<void> _onRefreshTours(
    RefreshToursEvent event,
    Emitter<TourState> emit,
  ) async {
    BlocErrorHandler.logEvent('TourBloc', 'RefreshToursEvent', {'guideId': event.guideId});
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        if (event.guideId != null) {
          return await _getToursUsecase.getToursByGuideId(event.guideId!);
        } else {
          return await _getToursUsecase();
        }
      },
      onSuccess: (tours) {
        if (event.guideId != null) {
          emit(TourLoaded(
            tours: tours,
            filteredTours: tours,
          ));
        } else {
          // Refresh all published tours for explore screen
          final currentUser = _authService.currentUser;
          final filteredTours = currentUser != null 
              ? tours.where((tour) => tour.guideId != currentUser.uid).toList()
              : tours;
          
          emit(TourLoaded(
            tours: filteredTours,
            filteredTours: filteredTours,
          ));
        }
      },
      onError: (error) => emit(TourError.fromException(error)),
      operationName: 'refreshTours',
      serviceName: 'GetToursUsecase',
      context: {'guideId': event.guideId},
    );
  }

  Future<void> _onFilterTours(
    FilterToursEvent event,
    Emitter<TourState> emit,
  ) async {
    BlocErrorHandler.logEvent('TourBloc', 'FilterToursEvent', {
      'status': event.status?.value,
      'searchQuery': event.searchQuery,
    });
    
    final currentState = state;
    if (currentState is TourLoaded) {
      List<TourPlan> filteredTours = currentState.tours;

      // Apply status filter
      if (event.status != null) {
        filteredTours = filteredTours
            .where((tour) => tour.status == event.status)
            .toList();
      }

      // Apply search filter
      if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        final query = event.searchQuery!.toLowerCase();
        filteredTours = filteredTours.where((tour) {
          return tour.title.toLowerCase().contains(query) ||
              (tour.description?.toLowerCase().contains(query) ?? false) ||
              tour.places.any((place) => place.name.toLowerCase().contains(query));
        }).toList();
      }

      emit(currentState.copyWith(
        filteredTours: filteredTours,
        searchQuery: event.searchQuery,
        statusFilter: event.status,
      ));
    }
  }

  Future<void> _onDeleteTour(
    DeleteTourEvent event,
    Emitter<TourState> emit,
  ) async {
    BlocErrorHandler.logEvent('TourBloc', 'DeleteTourEvent', {'tourId': event.tourId});
    
    // TODO: Implement DeleteTourUsecase when available
    emit(const TourError(
      message: 'Delete tour functionality not yet implemented',
      errorCode: 'NOT_IMPLEMENTED',
    ));
  }

  Future<void> _onUpdateTour(
    UpdateTourEvent event,
    Emitter<TourState> emit,
  ) async {
    BlocErrorHandler.logEvent('TourBloc', 'UpdateTourEvent', {'tourId': event.tour.id});
    
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        return await _updateTourUsecase(event.tour);
      },
      onSuccess: (updatedTour) {
        emit(const TourActionSuccess('Tour updated successfully'));
        // Refresh tours after update
        add(const RefreshToursEvent());
      },
      onError: (error) => emit(TourError.fromException(error)),
      operationName: 'updateTour',
      serviceName: 'UpdateTourUsecase',
      context: {'tourId': event.tour.id},
    );
  }
}