import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/utils/logger.dart';
import '../domain/entities/tour.dart';
import '../data/models/tour_request.dart';

/// Service to handle tour-related Firebase operations
class TourService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  TourService(this._firestore, this._storage);

  /// Create a new tour
  Future<Tour> createTour(TourCreateRequest request, String guideId) async {
    try {
      AppLogger.info('🚀 Starting tour creation for guide: $guideId');
      AppLogger.info('📊 Tour data: ${request.title}');
      
      // Validate request
      final validationErrors = request.validate();
      if (validationErrors.isNotEmpty) {
        AppLogger.error('❌ Validation failed: ${validationErrors.join(', ')}');
        throw TourServiceException('Invalid tour data: ${validationErrors.join(', ')}');
      }
      AppLogger.info('✅ Validation passed');

      // Upload images first
      AppLogger.info('📸 Starting image upload...');
      final imageUrls = await _uploadImages(request.images, guideId);
      AppLogger.info('✅ Images uploaded: ${imageUrls.length} images');

      // Create tour document
      final tourRef = _firestore.collection('tours').doc();
      final now = DateTime.now();
      
      AppLogger.info('🆔 Generated tour ID: ${tourRef.id}');
      AppLogger.info('📅 Timestamp: ${now.toIso8601String()}');

      final tourData = {
        'id': tourRef.id,
        'title': request.title.trim(),
        'description': request.description.trim(),
        'summary': request.highlights.isNotEmpty ? request.highlights.first : request.description.trim().substring(0, request.description.length > 100 ? 100 : request.description.length),
        'category': request.category.name,
        'difficulty': request.difficulty.name,
        'duration_minutes': ((request.estimatedDuration ?? 1.0) * 60).round(),
        'price': request.estimatedCost ?? 0.0,
        'start_location': request.location.toJson(),
        'end_location': null,
        'highlights': request.highlights,
        'includes': request.includes,
        'excludes': request.excludes,
        'requirements': request.requirements,
        'itinerary': request.itinerary.map((item) => item.toJson()).toList(),
        'images': imageUrls,
        'metadata': {
          'currency': request.currency ?? 'EUR',
          'tags': request.tags,
          'created_by': 'app',
        },
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'guide_id': guideId,
        'is_active': request.isPublic,
        'is_published': true,
        'is_draft': false,
        'max_participants': request.maxGroupSize,
        'booking_count': 0,
        'rating': 0.0,
        'review_count': 0,
      };

      AppLogger.info('💾 About to save tour to Firebase...');
      AppLogger.info('📍 Collection: tours');
      AppLogger.info('🆔 Document ID: ${tourRef.id}');
      AppLogger.info('📦 Data size: ${tourData.toString().length} characters');
      
      // Check Firebase connection before attempting save
      try {
        AppLogger.info('🔍 Testing Firebase connection...');
        await _firestore.enableNetwork();
        AppLogger.info('✅ Firebase connection is active');
      } catch (e) {
        AppLogger.error('❌ Firebase connection test failed', e);
      }
      
      // Attempt to save to Firestore with timeout
      AppLogger.info('⏳ Setting document in Firestore...');
      await tourRef.set(tourData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          AppLogger.error('⏰ Firebase set operation timed out after 30 seconds');
          throw TourServiceException('Firebase operation timed out');
        },
      );
      
      AppLogger.info('🎉 Tour save operation completed!');
      AppLogger.info('🔍 Verifying save by reading back...');
      
      // Verify the document was actually saved
      final savedDoc = await tourRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.error('⏰ Firebase get operation timed out');
          throw TourServiceException('Failed to verify tour save');
        },
      );
      
      if (savedDoc.exists) {
        AppLogger.info('✅ VERIFICATION SUCCESSFUL: Tour exists in Firebase');
        AppLogger.info('📋 Saved data keys: ${savedDoc.data()?.keys.join(', ')}');
        final savedTitle = savedDoc.data()?['title'] ?? 'Unknown';
        AppLogger.info('📝 Saved tour title: $savedTitle');
      } else {
        AppLogger.error('❌ VERIFICATION FAILED: Tour not found in Firebase after save!');
        throw TourServiceException('Tour was not saved to Firebase - verification failed');
      }

      AppLogger.info('🏁 Tour creation completed successfully');
      return Tour.fromJson(tourData);
    } on FirebaseException catch (e) {
      AppLogger.error('🔥 Firebase error during tour creation', e);
      AppLogger.error('🔥 Firebase error code: ${e.code}');
      AppLogger.error('🔥 Firebase error message: ${e.message}');
      throw TourServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('💥 Tour creation failed with unexpected error', e);
      AppLogger.error('💥 Error type: ${e.runtimeType}');
      throw TourServiceException('Failed to create tour: ${e.toString()}');
    }
  }

  /// Save tour as draft
  Future<Tour> saveAsDraft(TourCreateRequest request, String guideId) async {
    try {
      AppLogger.info('Starting tour draft save for guide: $guideId');
      
      // For drafts, we're more lenient with validation
      if (request.title.trim().isEmpty) {
        throw TourServiceException('Title is required even for drafts');
      }

      final imageUrls = await _uploadImages(request.images, guideId);

      final tourRef = _firestore.collection('tour_drafts').doc();
      final now = DateTime.now();

      final draftData = {
        'id': tourRef.id,
        'title': request.title.trim(),
        'description': request.description.trim(),
        'summary': request.highlights.isNotEmpty ? request.highlights.first : request.description.trim(),
        'category': request.category.name,
        'difficulty': request.difficulty.name,
        'duration_minutes': ((request.estimatedDuration ?? 1.0) * 60).round(),
        'price': request.estimatedCost ?? 0.0,
        'start_location': request.location.toJson(),
        'end_location': null,
        'highlights': request.highlights,
        'includes': request.includes,
        'excludes': request.excludes,
        'requirements': request.requirements,
        'itinerary': request.itinerary.map((item) => item.toJson()).toList(),
        'images': imageUrls,
        'metadata': {
          'currency': request.currency ?? 'EUR',
          'tags': request.tags,
          'is_draft': true,
          'created_by': 'app',
        },
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'guide_id': guideId,
        'is_active': false,
        'is_published': false,
        'is_draft': true,
        'max_participants': request.maxGroupSize,
      };

      AppLogger.info('Saving draft to Firebase with ID: ${tourRef.id}');
      await tourRef.set(draftData);
      AppLogger.info('Draft saved successfully to Firebase');

      return Tour.fromJson(draftData);
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error during draft save', e);
      throw TourServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('Draft save failed', e);
      throw TourServiceException('Failed to save draft: ${e.toString()}');
    }
  }

  /// Publish tour (same as create for now)
  Future<Tour> publishTour(TourCreateRequest request, String guideId) async {
    AppLogger.info('🚀 Publishing tour as live tour for guide: $guideId');
    AppLogger.info('📝 Tour title: ${request.title}');
    AppLogger.info('🔍 Request validation status: ${request.validate().isEmpty ? "Valid" : "Invalid"}');
    
    try {
      final result = await createTour(request, guideId);
      AppLogger.info('✅ Tour published successfully: ${result.title}');
      AppLogger.info('🆔 Published tour ID: ${result.id}');
      return result;
    } catch (e) {
      AppLogger.error('❌ Tour publishing failed', e);
      rethrow;
    }
  }

  /// Upload images to Firebase Storage
  Future<List<String>> _uploadImages(List<File> images, String guideId) async {
    if (images.isEmpty) {
      AppLogger.info('No images to upload');
      return [];
    }

    AppLogger.info('Uploading ${images.length} images');
    final List<String> imageUrls = [];

    for (int i = 0; i < images.length; i++) {
      final file = images[i];
      final fileName = 'tour_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = _storage.ref().child('tours/$guideId/$fileName');

      try {
        AppLogger.info('Uploading image $i: $fileName');
        final uploadTask = await ref.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
        AppLogger.info('Image $i uploaded successfully');
      } catch (e) {
        AppLogger.error('Failed to upload image $i', e);
        // Continue with other images
      }
    }

    AppLogger.info('Successfully uploaded ${imageUrls.length} images');
    return imageUrls;
  }

  /// Get tours by guide ID
  Future<List<Tour>> getToursByGuide(String guideId) async {
    try {
      AppLogger.info('Loading tours for guide: $guideId');
      
      final snapshot = await _firestore
          .collection('tours')
          .where('guide_id', isEqualTo: guideId)
          .orderBy('created_at', descending: true)
          .get();

      final tours = snapshot.docs
          .map((doc) => Tour.fromJson(doc.data()))
          .toList();
          
      AppLogger.info('Loaded ${tours.length} tours for guide');
      return tours;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error loading tours', e);
      throw TourServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('Failed to load tours', e);
      throw TourServiceException('Failed to load tours: ${e.toString()}');
    }
  }

  /// Get tour by ID
  Future<Tour?> getTourById(String tourId) async {
    try {
      AppLogger.info('Loading tour by ID: $tourId');
      
      final doc = await _firestore.collection('tours').doc(tourId).get();

      if (!doc.exists) {
        AppLogger.warning('Tour not found: $tourId');
        return null;
      }

      final tour = Tour.fromJson(doc.data()!);
      AppLogger.info('Tour loaded successfully: ${tour.title}');
      return tour;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error loading tour', e);
      throw TourServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('Failed to load tour', e);
      throw TourServiceException('Failed to load tour: ${e.toString()}');
    }
  }

  /// Search tours by address - simple string matching
  Future<List<Tour>> searchTours(String searchQuery) async {
    try {
      AppLogger.info('🔍 Searching tours with query: "$searchQuery"');
      
      if (searchQuery.trim().isEmpty) {
        AppLogger.info('Empty search query, returning empty results');
        return [];
      }
      
      final lowercaseQuery = searchQuery.toLowerCase().trim();
      
      // Get all published tours
      final snapshot = await _firestore
          .collection('tours')
          .where('is_published', isEqualTo: true)
          .where('is_active', isEqualTo: true)
          .get();

      AppLogger.info('📊 Found ${snapshot.docs.length} published tours to search');

      // Simple client-side filtering for address matching
      final matchingTours = <Tour>[];
      
      for (final doc in snapshot.docs) {
        try {
          final tourData = doc.data();
          final tour = Tour.fromJson(tourData);
          
          // Check if address contains the search query (case insensitive)
          final address = tour.startLocation.address.toLowerCase();
          final locationName = tour.startLocation.name?.toLowerCase();
          
          if (address.contains(lowercaseQuery) || locationName!.contains(lowercaseQuery)) {
            matchingTours.add(tour);
            AppLogger.debug('✅ Match found: ${tour.title} at ${tour.startLocation.address}');
          }
        } catch (e) {
          AppLogger.warning('Failed to parse tour document: ${doc.id}', e);
          // Continue with other tours
        }
      }
      
      AppLogger.info('🎯 Search completed: ${matchingTours.length} tours match "$searchQuery"');
      return matchingTours;
      
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error during tour search', e);
      throw TourServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('Tour search failed', e);
      throw TourServiceException('Failed to search tours: ${e.toString()}');
    }
  }
}

/// Custom exception for tour service operations
class TourServiceException implements Exception {
  final String message;

  const TourServiceException(this.message);

  @override
  String toString() => 'TourServiceException: $message';
}