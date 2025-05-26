import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/exceptions/tour_plan_exceptions.dart';
import '../../../models/requests/tour_plan_update_request.dart';
import '../../../models/requests/tour_plan_create_request.dart';
import '../../../models/requests/tour_plan_search_filters.dart';
import '../../../models/tour_plan.dart';
import '../../../core/utils/logger.dart';

/// TourPlan service for Firebase operations following BLoC architecture rules
class TourPlanService {
  static const String _collectionName = 'tourPlans';
  final FirebaseFirestore _firestore;

  TourPlanService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all TourPlans for a specific guide
  Future<List<TourPlan>> getTourPlansByGuide(String guideId) async {
    try {
      AppLogger.info('TourPlanService: Fetching TourPlans for guide $guideId');
      
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('guideId', isEqualTo: guideId)
          .orderBy('createdAt', descending: true)
          .get();

      final tourPlans = querySnapshot.docs
          .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
          .toList();

      AppLogger.info('TourPlanService: Found ${tourPlans.length} TourPlans for guide $guideId');
      AppLogger.serviceOperation('TourPlanService', 'getTourPlansByGuide', true);
      return tourPlans;
    } on FirebaseException catch (e) {
      AppLogger.error('TourPlanService: Firebase error fetching TourPlans for guide $guideId', e);
      AppLogger.serviceOperation('TourPlanService', 'getTourPlansByGuide', false);
      throw TourPlanServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('TourPlanService: Unexpected error fetching TourPlans for guide $guideId', e);
      AppLogger.serviceOperation('TourPlanService', 'getTourPlansByGuide', false);
      throw TourPlanServiceException('Failed to load tour plans: ${e.toString()}');
    }
  }

  /// Get a specific TourPlan by ID
  Future<TourPlan> getTourPlanById(String tourPlanId) async {
    try {
      AppLogger.info('TourPlanService: Fetching TourPlan $tourPlanId');
      
      final docSnapshot = await _firestore
          .collection(_collectionName)
          .doc(tourPlanId)
          .get();

      if (!docSnapshot.exists) {
        AppLogger.warning('TourPlanService: TourPlan $tourPlanId not found');
        AppLogger.serviceOperation('TourPlanService', 'getTourPlanById', false);
        throw TourPlanNotFoundException(tourPlanId);
      }

      final tourPlan = TourPlan.fromMap(docSnapshot.data()!, docSnapshot.id);
      AppLogger.info('TourPlanService: Successfully fetched TourPlan $tourPlanId');
      AppLogger.serviceOperation('TourPlanService', 'getTourPlanById', true);
      return tourPlan;
    } on TourPlanNotFoundException {
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('TourPlanService: Firebase error fetching TourPlan $tourPlanId', e);
      AppLogger.serviceOperation('TourPlanService', 'getTourPlanById', false);
      throw TourPlanServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('TourPlanService: Unexpected error fetching TourPlan $tourPlanId', e);
      AppLogger.serviceOperation('TourPlanService', 'getTourPlanById', false);
      throw TourPlanServiceException('Failed to load tour plan: ${e.toString()}');
    }
  }

  /// Create a new TourPlan
  Future<TourPlan> createTourPlan(TourPlanCreateRequest request) async {
    try {
      AppLogger.info('TourPlanService: Creating new TourPlan "${request.title}"');
      
      // Validate request
      _validateCreateRequest(request);
      
      final docRef = _firestore.collection(_collectionName).doc();
      final tourPlan = request.toTourPlan(docRef.id);
      
      await docRef.set(tourPlan.toMap());
      
      AppLogger.info('TourPlanService: Successfully created TourPlan ${tourPlan.id}');
      AppLogger.serviceOperation('TourPlanService', 'createTourPlan', true);
      return tourPlan;
    } on TourPlanValidationException {
      AppLogger.serviceOperation('TourPlanService', 'createTourPlan', false);
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('TourPlanService: Firebase error creating TourPlan', e);
      AppLogger.serviceOperation('TourPlanService', 'createTourPlan', false);
      throw TourPlanServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('TourPlanService: Unexpected error creating TourPlan', e);
      AppLogger.serviceOperation('TourPlanService', 'createTourPlan', false);
      throw TourPlanServiceException('Failed to create tour plan: ${e.toString()}');
    }
  }

  /// Update an existing TourPlan
  Future<TourPlan> updateTourPlan(String tourPlanId, TourPlanUpdateRequest request) async {
    try {
      AppLogger.info('TourPlanService: Updating TourPlan $tourPlanId');
      
      // Validate request
      _validateUpdateRequest(request);
      
      final docRef = _firestore.collection(_collectionName).doc(tourPlanId);
      
      // Check if document exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        AppLogger.warning('TourPlanService: TourPlan $tourPlanId not found for update');
        AppLogger.serviceOperation('TourPlanService', 'updateTourPlan', false);
        throw TourPlanNotFoundException(tourPlanId);
      }

      // Update the document
      await docRef.update(request.toUpdateMap());
      
      // Fetch and return updated TourPlan
      final updatedSnapshot = await docRef.get();
      final updatedTourPlan = TourPlan.fromMap(updatedSnapshot.data()!, updatedSnapshot.id);
      
      AppLogger.info('TourPlanService: Successfully updated TourPlan $tourPlanId');
      AppLogger.serviceOperation('TourPlanService', 'updateTourPlan', true);
      return updatedTourPlan;
    } on TourPlanNotFoundException {
      AppLogger.serviceOperation('TourPlanService', 'updateTourPlan', false);
      rethrow;
    } on TourPlanValidationException {
      AppLogger.serviceOperation('TourPlanService', 'updateTourPlan', false);
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('TourPlanService: Firebase error updating TourPlan $tourPlanId', e);
      AppLogger.serviceOperation('TourPlanService', 'updateTourPlan', false);
      throw TourPlanServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('TourPlanService: Unexpected error updating TourPlan $tourPlanId', e);
      AppLogger.serviceOperation('TourPlanService', 'updateTourPlan', false);
      throw TourPlanServiceException('Failed to update tour plan: ${e.toString()}');
    }
  }

  /// Delete a TourPlan
  Future<void> deleteTourPlan(String tourPlanId, String guideId) async {
    try {
      AppLogger.info('TourPlanService: Deleting TourPlan $tourPlanId by guide $guideId');
      
      final docRef = _firestore.collection(_collectionName).doc(tourPlanId);

      // Check if document exists and verify ownership
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        AppLogger.warning('TourPlanService: TourPlan $tourPlanId not found for deletion');
        AppLogger.serviceOperation('TourPlanService', 'deleteTourPlan', false);
        throw TourPlanNotFoundException(tourPlanId);
      }

      final tourPlan = TourPlan.fromMap(docSnapshot.data()!, docSnapshot.id);
      if (tourPlan.guideId != guideId) {
        AppLogger.warning('TourPlanService: Permission denied - guide $guideId cannot delete TourPlan $tourPlanId');
        AppLogger.serviceOperation('TourPlanService', 'deleteTourPlan', false);
        throw const TourPlanPermissionException('You do not have permission to delete this tour plan');
      }

      await docRef.delete();
      
      AppLogger.info('TourPlanService: Successfully deleted TourPlan $tourPlanId');
      AppLogger.serviceOperation('TourPlanService', 'deleteTourPlan', true);
    } on TourPlanNotFoundException {
      AppLogger.serviceOperation('TourPlanService', 'deleteTourPlan', false);
      rethrow;
    } on TourPlanPermissionException {
      AppLogger.serviceOperation('TourPlanService', 'deleteTourPlan', false);
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('TourPlanService: Firebase error deleting TourPlan $tourPlanId', e);
      AppLogger.serviceOperation('TourPlanService', 'deleteTourPlan', false);
      throw TourPlanServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('TourPlanService: Unexpected error deleting TourPlan $tourPlanId', e);
      AppLogger.serviceOperation('TourPlanService', 'deleteTourPlan', false);
      throw TourPlanServiceException('Failed to delete tour plan: ${e.toString()}');
    }
  }

  /// Search TourPlans with filters
  Future<List<TourPlan>> searchTourPlans(TourPlanSearchFilters filters) async {
    try {
      AppLogger.info('TourPlanService: Searching TourPlans with filters');
      
      Query query = _firestore.collection(_collectionName);
      
      // Apply filters
      if (filters.isPublic != null) {
        query = query.where('isPublic', isEqualTo: filters.isPublic);
      }
      
      if (filters.difficulty != null) {
        query = query.where('difficulty', isEqualTo: filters.difficulty);
      }
      
      if (filters.maxDuration != null) {
        query = query.where('duration', isLessThanOrEqualTo: filters.maxDuration);
      }
      
      if (filters.minDuration != null) {
        query = query.where('duration', isGreaterThanOrEqualTo: filters.minDuration);
      }
      
      if (filters.minRating != null) {
        query = query.where('averageRating', isGreaterThanOrEqualTo: filters.minRating);
      }
      
      // Order by creation date
      query = query.orderBy('createdAt', descending: true);
      
      final querySnapshot = await query.get();
      var tourPlans = querySnapshot.docs
          .map((doc) => TourPlan.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Apply client-side filtering for tags
      if (filters.tags != null && filters.tags!.isNotEmpty) {
        tourPlans = tourPlans.where((tourPlan) {
          return filters.tags!.any((filterTag) => 
            tourPlan.tags.any((tourTag) => 
              tourTag.toLowerCase().contains(filterTag.toLowerCase())
            )
          );
        }).toList();
      }

      AppLogger.info('TourPlanService: Found ${tourPlans.length} TourPlans matching filters');
      AppLogger.serviceOperation('TourPlanService', 'searchTourPlans', true);
      return tourPlans;
    } on FirebaseException catch (e) {
      AppLogger.error('TourPlanService: Firebase error searching TourPlans', e);
      AppLogger.serviceOperation('TourPlanService', 'searchTourPlans', false);
      throw TourPlanServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('TourPlanService: Unexpected error searching TourPlans', e);
      AppLogger.serviceOperation('TourPlanService', 'searchTourPlans', false);
      throw TourPlanServiceException('Failed to search tour plans: ${e.toString()}');
    }
  }

  // VALIDATION METHODS

  /// Validate TourPlan create request
  void _validateCreateRequest(TourPlanCreateRequest request) {
    if (request.title.trim().isEmpty) {
      throw const TourPlanValidationException('Tour title cannot be empty');
    }
    
    if (request.title.trim().length > 100) {
      throw const TourPlanValidationException('Tour title cannot exceed 100 characters');
    }
    
    if (request.description.trim().isEmpty) {
      throw const TourPlanValidationException('Tour description cannot be empty');
    }
    
    if (request.description.trim().length > 500) {
      throw const TourPlanValidationException('Tour description cannot exceed 500 characters');
    }
    
    if (request.duration < 30) {
      throw const TourPlanValidationException('Tour duration must be at least 30 minutes');
    }
    
    if (request.duration > 720) {
      throw const TourPlanValidationException('Tour duration cannot exceed 12 hours');
    }
    
    if (request.guideId.trim().isEmpty) {
      throw const TourPlanValidationException('Guide ID is required');
    }

    final validDifficulties = ['easy', 'moderate', 'challenging', 'extreme'];
    if (!validDifficulties.contains(request.difficulty.toLowerCase())) {
      throw const TourPlanValidationException('Invalid difficulty level');
    }
  }

  /// Validate TourPlan update request
  void _validateUpdateRequest(TourPlanUpdateRequest request) {
    if (!request.hasUpdates) {
      throw const TourPlanValidationException('No updates provided');
    }
    
    if (request.title != null && request.title!.trim().isEmpty) {
      throw const TourPlanValidationException('Tour title cannot be empty');
    }
    
    if (request.title != null && request.title!.trim().length > 100) {
      throw const TourPlanValidationException('Tour title cannot exceed 100 characters');
    }
    
    if (request.description != null && request.description!.trim().isEmpty) {
      throw const TourPlanValidationException('Tour description cannot be empty');
    }
    
    if (request.description != null && request.description!.trim().length > 500) {
      throw const TourPlanValidationException('Tour description cannot exceed 500 characters');
    }
    
    if (request.duration != null && request.duration! < 30) {
      throw const TourPlanValidationException('Tour duration must be at least 30 minutes');
    }
    
    if (request.duration != null && request.duration! > 720) {
      throw const TourPlanValidationException('Tour duration cannot exceed 12 hours');
    }
    
    if (request.difficulty != null) {
      final validDifficulties = ['easy', 'moderate', 'challenging', 'extreme'];
      if (!validDifficulties.contains(request.difficulty!.toLowerCase())) {
        throw const TourPlanValidationException('Invalid difficulty level');
      }
    }
  }
}

/// Custom exception for TourPlan service operations
class TourPlanServiceException implements Exception {
  final String message;
  
  const TourPlanServiceException(this.message);
  
  @override
  String toString() => 'TourPlanServiceException: $message';
}