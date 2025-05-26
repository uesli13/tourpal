import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../../../core/utils/logger.dart';
import '../../../tours/services/tour_service.dart';
import '../../../tours/data/models/tour_request.dart';
import '../../../tours/domain/entities/tour.dart';
import '../../../tours/domain/enums/tour_category.dart';
import '../../../tours/domain/enums/tour_difficulty.dart';
import 'tour_creation_event.dart';
import 'tour_creation_state.dart';

/// Tour Creation BLoC following TourPal architecture rules
/// Handles all tour creation business logic
class TourCreationBloc extends Bloc<TourCreationEvent, TourCreationState> {
  final TourService _tourService;
  final FirebaseAuth _auth;

  TourCreationBloc({
    required TourService tourService,
    required FirebaseAuth auth,
  })  : _tourService = tourService,
        _auth = auth,
        super(const TourCreationInitial()) {
    
    AppLogger.info('TourCreationBloc initialized');
    
    on<CreateTourEvent>(_onCreateTour);
    on<SaveTourAsDraftEvent>(_onSaveTourAsDraft);
    on<ResetTourCreationEvent>(_onResetTourCreation);
  }

  @override
  void onChange(Change<TourCreationState> change) {
    super.onChange(change);
    AppLogger.blocTransition(
      'TourCreationBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(TourCreationEvent event) {
    super.onEvent(event);
    AppLogger.blocEvent('TourCreationBloc', event.runtimeType.toString());
  }

  /// Handle tour creation and publishing
  Future<void> _onCreateTour(
    CreateTourEvent event,
    Emitter<TourCreationState> emit,
  ) async {
    try {
      AppLogger.info('🚀 Starting tour creation process');
      emit(const TourCreationLoading());

      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        AppLogger.error('❌ User not authenticated');
        emit(const TourCreationError(message: 'You must be logged in to create tours'));
        return;
      }

      AppLogger.info('✅ User authenticated: ${currentUser.uid}');

      // Validate input data
      if (event.title.trim().isEmpty) {
        emit(const TourCreationError(message: 'Tour title is required'));
        return;
      }

      if (event.description.trim().isEmpty) {
        emit(const TourCreationError(message: 'Tour description is required'));
        return;
      }

      if (event.places.length < 2) {
        emit(const TourCreationError(message: 'Tour must have at least 2 places'));
        return;
      }

      AppLogger.info('✅ Input validation passed');

      // Create tour request from UI data
      final tourRequest = await _createTourRequestFromEvent(event);
      AppLogger.info('✅ Tour request created');

      // Call TourService to publish tour
      AppLogger.info('🔥 Calling TourService.publishTour...');
      final tour = await _tourService.publishTour(tourRequest, currentUser.uid);
      
      AppLogger.info('🎉 Tour published successfully: ${tour.title}');
      AppLogger.info('🆔 Tour ID: ${tour.id}');
      
      emit(TourCreationSuccess(
        tour: tour,
        message: '🎉 Tour "${tour.title}" published successfully!',
      ));

    } catch (e) {
      AppLogger.error('❌ Tour creation failed', e);
      emit(TourCreationError(
        message: 'Failed to create tour: ${e.toString()}',
      ));
    }
  }

  /// Handle saving tour as draft
  Future<void> _onSaveTourAsDraft(
    SaveTourAsDraftEvent event,
    Emitter<TourCreationState> emit,
  ) async {
    try {
      AppLogger.info('💾 Starting tour draft save process');
      emit(const TourCreationLoading());

      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(const TourCreationError(message: 'You must be logged in to save drafts'));
        return;
      }

      // Create tour request (less strict validation for drafts)
      final tourRequest = await _createTourRequestFromEvent(CreateTourEvent(
        title: event.title,
        description: event.description,
        coverImage: event.coverImage,
        places: event.places,
      ));

      // Call TourService to save as draft
      final tour = await _tourService.saveAsDraft(tourRequest, currentUser.uid);
      
      AppLogger.info('💾 Tour draft saved successfully: ${tour.title}');
      
      emit(TourDraftSaved(
        tour: tour,
        message: '💾 Tour "${tour.title}" saved as draft',
      ));

    } catch (e) {
      AppLogger.error('❌ Tour draft save failed', e);
      emit(TourCreationError(
        message: 'Failed to save draft: ${e.toString()}',
      ));
    }
  }

  /// Reset tour creation state
  void _onResetTourCreation(
    ResetTourCreationEvent event,
    Emitter<TourCreationState> emit,
  ) {
    AppLogger.info('🔄 Resetting tour creation state');
    emit(const TourCreationInitial());
  }

  /// Convert UI event data to TourCreateRequest
  Future<TourCreateRequest> _createTourRequestFromEvent(CreateTourEvent event) async {
    AppLogger.info('🔄 Converting UI data to TourCreateRequest');
    
    // Extract location from first place (assuming it's the starting point)
    final firstPlace = event.places.isNotEmpty ? event.places.first : null;
    
    final location = TourLocation(
      id: firstPlace?['id'] ?? 'start-location',
      latitude: firstPlace?['latitude'] ?? 38.7223,
      longitude: firstPlace?['longitude'] ?? -9.1393,
      address: firstPlace?['address'] ?? 'Lisbon, Portugal',
      name: firstPlace?['name'] ?? 'Starting Point',
    );

    // Convert places to itinerary items
    final itinerary = event.places.asMap().entries.map((entry) {
      final index = entry.key;
      final place = entry.value;
      
      return TourItineraryItem(
        id: place['id'] ?? 'place-$index',
        title: place['name'] ?? 'Stop ${index + 1}',
        description: place['description'] ?? 'Tour stop at ${place['name'] ?? 'this location'}',
        duration: const Duration(minutes: 30), // Default duration
        order: index,
        location: TourLocation(
          id: place['id'] ?? 'place-$index',
          latitude: place['latitude'] ?? 0.0,
          longitude: place['longitude'] ?? 0.0,
          address: place['address'] ?? '',
          name: place['name'],
        ),
      );
    }).toList();

    // Prepare images list
    final images = event.coverImage != null ? [event.coverImage!] : <File>[];

    return TourCreateRequest(
      title: event.title.trim(),
      description: event.description.trim(),
      location: location,
      category: TourCategory.cultural, // Default category
      difficulty: TourDifficulty.easy, // Default difficulty
      estimatedDuration: 2.0, // Default 2 hours
      estimatedCost: 25.0, // Default €25
      maxGroupSize: 15, // Default group size
      highlights: [
        'Experience ${event.title}',
        'Visit ${event.places.length} amazing places',
      ],
      includes: [
        'Professional guide',
        'Tour of all locations',
      ],
      excludes: [
        'Transportation',
        'Food and drinks',
      ],
      requirements: [
        'Comfortable walking shoes',
        'Weather-appropriate clothing',
      ],
      itinerary: itinerary,
      images: images,
      tags: ['tour', 'guided', 'cultural'],
      currency: 'EUR',
      isPublic: true,
    );
  }
}