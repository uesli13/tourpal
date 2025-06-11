import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/tour_duration_calculator.dart';
import '../../../../models/tour_plan.dart';
import '../../../../models/place.dart';
import 'tour_creation_event.dart';
import 'tour_creation_state.dart';

class TourCreationBloc extends Bloc<TourCreationEvent, TourCreationState> {
  final StorageService _storageService;
  final FirebaseFirestore _firestore;

  TourCreationBloc({
    required StorageService storageService,
    FirebaseFirestore? firestore,
  })  : _storageService = storageService,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(TourCreationInitial()) {
    on<CreateTourEvent>(_onCreateTour);
    on<UpdateTourEvent>(_onUpdateTour);
    on<SaveDraftEvent>(_onSaveDraft);
    on<ValidateTourDataEvent>(_onValidateTourData);
    on<ResetTourCreationEvent>(_onResetTourCreation);
  }

  Future<void> _onCreateTour(
    CreateTourEvent event,
    Emitter<TourCreationState> emit,
  ) async {
    try {
      emit(TourPublishingState());

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        emit(const TourCreationError(message: 'You must be logged in to create a tour'));
        return;
      }

      // Validate price - ensure it's a positive number
      final tourPrice = event.price ?? 25.0; // Default to $25 if no price provided
      if (tourPrice < 0) {
        emit(const TourCreationError(message: 'Tour price must be a positive number'));
        return;
      }

      AppLogger.info('Creating tour: ${event.title} with price: \$${tourPrice}');

      // Generate tour ID first so we can use it for storage path
      final tourPlanRef = _firestore.collection('tourPlans').doc();
      final tourId = tourPlanRef.id;

      // Upload cover image if provided
      String? coverImageUrl;
      if (event.coverImage != null) {
        AppLogger.info('Uploading cover image...');
        coverImageUrl = await _storageService.uploadFile(
          event.coverImage!,
          'tours/$tourId/cover.jpg',
        );
      }

      // Convert places data to Place objects
      final places = event.places.asMap().entries.map((entry) {
        final index = entry.key;
        final placeData = entry.value;
        return Place(
          id: placeData['id'] ?? 'place_$index',
          name: placeData['name'] ?? 'Place $index',
          location: placeData['location'] ?? const GeoPoint(0, 0),
          order: index,
          address: placeData['address'],
          description: placeData['description'],
          photoUrl: placeData['photoUrl'],
          stayingDuration: placeData['stayingDuration'] ?? 30,
        );
      }).toList();

      // Calculate total duration properly using walking time + staying time
      final totalDurationHours = await TourDurationCalculator.calculateTotalDuration(places);

      // Create tour plan document
      final tourPlan = TourPlan(
        id: tourId,
        guideId: currentUser.uid,
        title: event.title,
        description: event.description,
        duration: totalDurationHours, // Now includes walking time + staying time
        difficulty: event.difficulty ?? 'easy',
        price: tourPrice, // Use validated price
        tags: (event.tags != null && event.tags!.isNotEmpty) ? event.tags! : ['general'],
        category: 'general', // Default category
        location: places.isNotEmpty ? places.first.address ?? '' : '', // Use first place address or empty
        status: TourStatus.published,
        places: places,
        coverImageUrl: coverImageUrl,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        averageRating: 0.0,
      );

      // Save tour plan to Firestore
      await tourPlanRef.set(tourPlan.toMap());

      AppLogger.info('Tour created successfully: ${tourPlan.id} with duration: ${totalDurationHours}h (including walking time)');

      emit(TourCreationSuccess(
        message: '🎉 Tour "${event.title}" created successfully!',
        tourId: tourPlan.id,
      ));
    } catch (e) {
      AppLogger.error('Failed to create tour', e);
      emit(TourCreationError(message: 'Failed to create tour: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTour(
    UpdateTourEvent event,
    Emitter<TourCreationState> emit,
  ) async {
    try {
      emit(TourPublishingState());

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        emit(const TourCreationError(message: 'You must be logged in to update a tour'));
        return;
      }

      AppLogger.info('Updating tour: ${event.tourId}');

      // Get existing tour to preserve certain fields
      final existingTourDoc = await _firestore.collection('tourPlans').doc(event.tourId).get();
      if (!existingTourDoc.exists) {
        emit(const TourCreationError(message: 'Tour not found'));
        return;
      }

      final existingTour = TourPlan.fromMap(existingTourDoc.data()!, existingTourDoc.id);

      // Verify ownership
      if (existingTour.guideId != currentUser.uid) {
        emit(const TourCreationError(message: 'You can only edit your own tours'));
        return;
      }

      // Upload new cover image if provided, otherwise keep existing
      String? coverImageUrl = existingTour.coverImageUrl;
      if (event.coverImage != null) {
        AppLogger.info('Uploading new cover image...');
        coverImageUrl = await _storageService.uploadFile(
          event.coverImage!,
          'tours/${event.tourId}/cover.jpg',
        );
      }

      // Process places and handle image uploads
      final places = <Place>[];
      for (int index = 0; index < event.places.length; index++) {
        final placeData = event.places[index];
        
        // Handle place image upload/preservation
        String? photoUrl;
        
        // Check if there's a new local image file to upload
        final imageField = placeData['image'];
        if (imageField != null && !imageField.toString().startsWith('http')) {
          // This is a local file path, upload it
          AppLogger.info('Uploading place image for ${placeData['name']}...');
          try {
            photoUrl = await _storageService.uploadFile(
              File(imageField.toString()),
              'tours/${event.tourId}/places/place_$index.jpg',
            );
          } catch (e) {
            AppLogger.warning('Failed to upload place image: $e');
            // Keep existing photoUrl if upload fails
            photoUrl = placeData['photoUrl']?.toString();
          }
        } else if (imageField != null && imageField.toString().startsWith('http')) {
          // This is already a URL, keep it
          photoUrl = imageField.toString();
        } else {
          // No image field, check photoUrl
          photoUrl = placeData['photoUrl']?.toString();
        }
        
        final place = Place(
          id: placeData['id'] ?? 'place_$index',
          name: placeData['name'] ?? 'Place $index',
          location: placeData['location'] ?? const GeoPoint(0, 0),
          order: index,
          address: placeData['address'],
          description: placeData['description'],
          photoUrl: photoUrl,
          stayingDuration: placeData['stayingDuration'] ?? 30,
        );
        
        places.add(place);
      }

      // Calculate total duration properly using walking time + staying time
      final totalDurationHours = await TourDurationCalculator.calculateTotalDuration(places);

      // Create updated tour plan while preserving certain fields
      final updatedTourPlan = existingTour.copyWith(
        title: event.title,
        description: event.description,
        duration: totalDurationHours, // Now includes walking time + staying time
        difficulty: event.difficulty,
        price: event.price,
        tags: (event.tags != null && event.tags!.isNotEmpty) ? event.tags! : ['general'],
        status: event.status, // Allow status changes (draft <-> published)
        places: places,
        coverImageUrl: coverImageUrl,
        updatedAt: Timestamp.now(),
      );

      // Update tour plan in Firestore
      await _firestore.collection('tourPlans').doc(event.tourId).update(updatedTourPlan.toMap());

      AppLogger.info('Tour updated successfully: ${event.tourId} with duration: ${totalDurationHours}h (including walking time)');

      emit(TourCreationSuccess(
        message: '🎉 Tour "${event.title}" updated successfully!',
        tourId: event.tourId,
      ));
    } catch (e) {
      AppLogger.error('Failed to update tour', e);
      emit(TourCreationError(message: 'Failed to update tour: ${e.toString()}'));
    }
  }

  Future<void> _onSaveDraft(
    SaveDraftEvent event,
    Emitter<TourCreationState> emit,
  ) async {
    try {
      emit(TourSavingDraftState());

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        emit(const TourCreationError(message: 'You must be logged in to save a draft'));
        return;
      }

      // For drafts, we allow price to be 0 since it's still being worked on
      final tourPrice = event.price ?? 0.0; // Drafts can have $0 price temporarily

      AppLogger.info('Saving tour draft: ${event.title} with price: \$${tourPrice}');

      // Generate tour ID first so we can use it for storage path
      final tourPlanRef = _firestore.collection('tourPlans').doc();
      final tourId = tourPlanRef.id;

      // Upload cover image if provided
      String? coverImageUrl;
      if (event.coverImage != null) {
        AppLogger.info('Uploading cover image...');
        coverImageUrl = await _storageService.uploadFile(
          event.coverImage!,
          'tours/$tourId/cover.jpg',
        );
      }

      // Convert places data to Place objects
      final places = event.places.asMap().entries.map((entry) {
        final index = entry.key;
        final placeData = entry.value;
        return Place(
          id: placeData['id'] ?? 'place_$index',
          name: placeData['name'] ?? 'Place $index',
          location: placeData['location'] ?? const GeoPoint(0, 0),
          order: index,
          address: placeData['address'],
          description: placeData['description'],
          photoUrl: placeData['photoUrl'],
          stayingDuration: placeData['stayingDuration'] ?? 30,
        );
      }).toList();

      // Calculate total duration properly using walking time + staying time
      final totalDurationHours = places.isNotEmpty 
          ? await TourDurationCalculator.calculateTotalDuration(places)
          : 1.0; // Default to 1 hour for drafts with no places

      // Create tour plan document
      final tourPlan = TourPlan(
        id: tourId,
        guideId: currentUser.uid,
        title: event.title,
        description: event.description,
        duration: totalDurationHours, // Now includes walking time + staying time
        difficulty: event.difficulty ?? 'easy',
        price: tourPrice, // Use the price variable for consistency
        tags: (event.tags != null && event.tags!.isNotEmpty) ? event.tags! : ['general'],
        category: 'general', // Default category
        location: places.isNotEmpty ? places.first.address ?? '' : '', // Use first place address or empty
        status: TourStatus.draft,
        places: places,
        coverImageUrl: coverImageUrl,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        averageRating: 0.0,
      );

      // Save tour plan to Firestore
      await tourPlanRef.set(tourPlan.toMap());

      AppLogger.info('Tour draft saved successfully: ${tourPlan.id} with duration: ${totalDurationHours}h (including walking time)');

      emit(TourDraftSavedState(
        message: '📝 Tour "${event.title}" saved as draft!',
        tourId: tourPlan.id,
      ));
    } catch (e) {
      AppLogger.error('Failed to save tour draft', e);
      emit(TourCreationError(message: 'Failed to save tour draft: ${e.toString()}'));
    }
  }

  Future<void> _onValidateTourData(
    ValidateTourDataEvent event,
    Emitter<TourCreationState> emit,
  ) async {
    emit(TourCreationValidating());

    final canProceedToStep2 = event.title.trim().isNotEmpty &&
        event.description.trim().isNotEmpty &&
        event.coverImage != null;

    final canPublish = canProceedToStep2 && event.places.length >= 2;

    emit(TourCreationValid(
      canProceedToStep2: canProceedToStep2,
      canPublish: canPublish,
    ));
  }

  Future<void> _onResetTourCreation(
    ResetTourCreationEvent event,
    Emitter<TourCreationState> emit,
  ) async {
    emit(TourCreationInitial());
  }
}