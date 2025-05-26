import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../models/place.dart';

class PlaceServiceException implements Exception {
  final String message;
  final String? code;
  
  const PlaceServiceException(this.message, [this.code]);
  
  @override
  String toString() => 'PlaceServiceException: $message';
}

class PlaceException implements Exception {
  final String message;
  const PlaceException(this.message);
  
  @override
  String toString() => 'PlaceException: $message';
}

class PlaceValidationException implements Exception {
  final String message;
  const PlaceValidationException(this.message);
  
  @override
  String toString() => 'PlaceValidationException: $message';
}

class PlaceService {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  
  PlaceService({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  Future<List<Place>> getPlacesByTourPlan(String tourPlanId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.place('Getting places by tour plan', tourPlanId);

    try {
      final querySnapshot = await _firestore
          .collection('tourPlans')
          .doc(tourPlanId)
          .collection('places')
          .orderBy('order')
          .get();

      final places = querySnapshot.docs
          .map((doc) => Place.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      AppLogger.performance('Get Places By Tour Plan', stopwatch.elapsed);
      AppLogger.place('Places retrieved successfully', '${places.length} places for $tourPlanId');

      return places;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting places by tour plan', e);
      throw DatabaseException('Failed to get places: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error getting places by tour plan', e);
      throw PlaceServiceException('Failed to retrieve places');
    }
  }

  Future<Place?> getPlaceById(String placeId, [String? userId]) async {
    try {
      final doc = await _firestore.collection('places').doc(placeId).get();
      if (doc.exists) {
        return Place.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw PlaceException('Failed to get place: $e');
    }
  }

  Future<Place> addPlaceToTourPlan({
    required String tourPlanId,
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    String? imageUrl,
    int? visitDuration,
    List<String>? categories,
  }) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.place('Adding place to tour plan', '$name to $tourPlanId');

    try {
      // Verify tour plan ownership
      await _verifyTourPlanOwnership(tourPlanId, currentUser.uid);

      // Validate place data
      _validatePlaceData(name, description, latitude, longitude, address);

      // Get current places count for order
      final existingPlaces = await getPlacesByTourPlan(tourPlanId);
      final order = existingPlaces.length;

      // Create place document
      final placeData = {
        'name': name.trim(),
        'description': description.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'address': address.trim(),
        'imageUrl': imageUrl ?? '',
        'visitDuration': visitDuration ?? 30, // Default 30 minutes
        'categories': categories ?? <String>[],
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('tourPlans')
          .doc(tourPlanId)
          .collection('places')
          .add(placeData);

      // Get the created place
      final createdDoc = await docRef.get();
      final place = Place.fromMap(createdDoc.data()!, docRef.id);

      stopwatch.stop();
      AppLogger.performance('Add Place To Tour Plan', stopwatch.elapsed);
      AppLogger.place('Place added successfully', place.id);

      return place;

    } on ValidationException catch (e) {
      AppLogger.warning('Validation error during place creation: ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error adding place to tour plan', e);
      throw PlaceServiceException('Failed to add place: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error adding place to tour plan', e);
      throw PlaceServiceException('Failed to add place');
    }
  }

  Future<Place> updatePlace({
    required String tourPlanId,
    required String placeId,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    String? imageUrl,
    int? visitDuration,
    List<String>? categories,
  }) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.place('Updating place', placeId);

    try {
      // Verify tour plan ownership
      await _verifyTourPlanOwnership(tourPlanId, currentUser.uid);

      // Validate inputs if provided
      if (name != null || description != null || latitude != null || 
          longitude != null || address != null) {
        _validatePlaceUpdateData(name, description, latitude, longitude, address);
      }

      // Build update data
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name.trim();
      if (description != null) updateData['description'] = description.trim();
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (address != null) updateData['address'] = address.trim();
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (visitDuration != null) updateData['visitDuration'] = visitDuration;
      if (categories != null) updateData['categories'] = categories;

      // Update place document
      await _firestore
          .collection('tourPlans')
          .doc(tourPlanId)
          .collection('places')
          .doc(placeId)
          .update(updateData);

      // Get updated place
      final updatedDoc = await _firestore
          .collection('tourPlans')
          .doc(tourPlanId)
          .collection('places')
          .doc(placeId)
          .get();

      final place = Place.fromMap(updatedDoc.data()!, placeId);

      stopwatch.stop();
      AppLogger.performance('Update Place', stopwatch.elapsed);
      AppLogger.place('Place updated successfully', placeId);

      return place;

    } on ValidationException catch (e) {
      AppLogger.warning('Validation error during place update: ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error updating place', e);
      throw PlaceServiceException('Failed to update place: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error updating place', e);
      throw PlaceServiceException('Failed to update place');
    }
  }

  Future<void> removePlaceFromTourPlan(String tourPlanId, String placeId) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.place('Removing place from tour plan', placeId);

    try {
      // Verify tour plan ownership
      await _verifyTourPlanOwnership(tourPlanId, currentUser.uid);

      // Get the place to be deleted to get its order
      final placeDoc = await _firestore
          .collection('tourPlans')
          .doc(tourPlanId)
          .collection('places')
          .doc(placeId)
          .get();

      if (!placeDoc.exists) {
        throw const PlaceException('Place not found');
      }

      final deletedOrder = placeDoc.data()!['order'] as int;

      // Delete the place
      await _firestore
          .collection('tourPlans')
          .doc(tourPlanId)
          .collection('places')
          .doc(placeId)
          .delete();

      // Reorder remaining places
      await _reorderPlacesAfterDeletion(tourPlanId, deletedOrder);

      stopwatch.stop();
      AppLogger.performance('Remove Place From Tour Plan', stopwatch.elapsed);
      AppLogger.place('Place removed successfully', placeId);

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error removing place from tour plan', e);
      throw PlaceServiceException('Failed to remove place: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error removing place from tour plan', e);
      throw PlaceServiceException('Failed to remove place');
    }
  }

  Future<List<Place>> reorderPlaces(String tourPlanId, List<Place> reorderedPlaces) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.place('Reordering places in tour plan', tourPlanId);

    try {
      // Verify tour plan ownership
      await _verifyTourPlanOwnership(tourPlanId, currentUser.uid);

      // Update order for each place
      final batch = _firestore.batch();
      
      for (int i = 0; i < reorderedPlaces.length; i++) {
        final placeRef = _firestore
            .collection('tourPlans')
            .doc(tourPlanId)
            .collection('places')
            .doc(reorderedPlaces[i].id);
        
        batch.update(placeRef, {
          'order': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Return updated places
      final updatedPlaces = await getPlacesByTourPlan(tourPlanId);

      stopwatch.stop();
      AppLogger.performance('Reorder Places', stopwatch.elapsed);
      AppLogger.place('Places reordered successfully', '${reorderedPlaces.length} places');

      return updatedPlaces;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error reordering places', e);
      throw PlaceServiceException('Failed to reorder places: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error reordering places', e);
      throw PlaceServiceException('Failed to reorder places');
    }
  }

  Future<List<Place>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? category,
    String? query,
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.place('Searching nearby places', '$latitude,$longitude');

    try {
      // Note: This would typically integrate with Google Places API or similar
      // For now, returning mock data or places from database
      
      // You would implement actual places search here
      // This is a placeholder implementation
      final places = <Place>[];

      stopwatch.stop();
      AppLogger.performance('Search Nearby Places', stopwatch.elapsed);
      AppLogger.place('Nearby places search completed', '${places.length} places found');

      return places;

    } catch (e) {
      AppLogger.error('Error searching nearby places', e);
      throw PlaceServiceException('Failed to search nearby places');
    }
  }

  Future<List<Place>> getPopularPlaces({int limit = 20}) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.place('Getting popular places', 'limit: $limit');

    try {
      // This would aggregate places from multiple tour plans
      // and rank by usage frequency
      final places = <Place>[];

      stopwatch.stop();
      AppLogger.performance('Get Popular Places', stopwatch.elapsed);
      AppLogger.place('Popular places retrieved', '${places.length} places');

      return places;

    } catch (e) {
      AppLogger.error('Error getting popular places', e);
      throw PlaceServiceException('Failed to get popular places');
    }
  }

  /// Get places by category
  Future<List<Place>> getPlacesByCategory(PlaceCategory category) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.place('Getting places by category', category.name);

    try {
      final querySnapshot = await _firestore
          .collection('places')
          .where('category', isEqualTo: category.name)
          .orderBy('averageRating', descending: true)
          .limit(50)
          .get();

      final places = querySnapshot.docs
          .map((doc) => Place.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      AppLogger.performance('Get Places By Category', stopwatch.elapsed);
      AppLogger.place('Places by category retrieved', '${places.length} places');

      return places;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting places by category', e);
      throw DatabaseException('Failed to get places: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error getting places by category', e);
      throw PlaceServiceException('Failed to retrieve places');
    }
  }

  /// Search places with optional filters
  Future<List<Place>> searchPlaces({
    required String query,
    PlaceCategory? category,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.place('Searching places', 'query: $query');

    try {
      Query<Map<String, dynamic>> placesQuery = _firestore.collection('places');

      // Add category filter if specified
      if (category != null) {
        placesQuery = placesQuery.where('category', isEqualTo: category.name);
      }

      // Execute the query
      final querySnapshot = await placesQuery
          .orderBy('name')
          .limit(50)
          .get();

      var places = querySnapshot.docs
          .map((doc) => Place.fromMap(doc.data(), doc.id))
          .toList();

      // Filter by search query (client-side for now)
      places = places.where((place) =>
          place.name.toLowerCase().contains(query.toLowerCase()) ||
          place.description.toLowerCase().contains(query.toLowerCase()) ||
          place.address.toLowerCase().contains(query.toLowerCase())
      ).toList();

      // Filter by distance if location provided
      if (latitude != null && longitude != null && radiusKm != null) {
        places = places.where((place) {
          final distance = place.calculateDistance(latitude, longitude);
          return distance <= radiusKm;
        }).toList();
      }

      stopwatch.stop();
      AppLogger.performance('Search Places', stopwatch.elapsed);
      AppLogger.place('Places search completed', '${places.length} places found');

      return places;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error searching places', e);
      throw DatabaseException('Failed to search places: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error searching places', e);
      throw PlaceServiceException('Failed to search places');
    }
  }

  /// Get nearby places
  Future<List<Place>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
    PlaceCategory? category,
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.place('Getting nearby places', '$latitude,$longitude within ${radiusKm}km');

    try {
      Query<Map<String, dynamic>> placesQuery = _firestore.collection('places');

      // Add category filter if specified
      if (category != null) {
        placesQuery = placesQuery.where('category', isEqualTo: category.name);
      }

      final querySnapshot = await placesQuery
          .limit(100) // Get more results to filter by distance
          .get();

      var places = querySnapshot.docs
          .map((doc) => Place.fromMap(doc.data(), doc.id))
          .toList();

      // Filter by distance and sort by proximity
      places = places.where((place) {
        final distance = place.calculateDistance(latitude, longitude);
        return distance <= radiusKm;
      }).toList();

      // Sort by distance
      places.sort((a, b) {
        final distanceA = a.calculateDistance(latitude, longitude);
        final distanceB = b.calculateDistance(latitude, longitude);
        return distanceA.compareTo(distanceB);
      });

      stopwatch.stop();
      AppLogger.performance('Get Nearby Places', stopwatch.elapsed);
      AppLogger.place('Nearby places retrieved', '${places.length} places');

      return places;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting nearby places', e);
      throw DatabaseException('Failed to get nearby places: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error getting nearby places', e);
      throw PlaceServiceException('Failed to get nearby places');
    }
  }

  /// Create a new place
  Future<Place> createPlace({
    required String name,
    required String description,
    required PlaceCategory category,
    required double latitude,
    required double longitude,
    required String address,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.place('Creating place', name);

    try {
      // Validate place data
      _validatePlaceData(name, description, latitude, longitude, address);

      // Create place document
      final placeData = {
        'name': name.trim(),
        'description': description.trim(),
        'category': category.name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address.trim(),
        'imageUrl': imageUrl ?? '',
        'averageRating': 0.0,
        'reviewCount': 0,
        'visitCount': 0,
        'createdBy': currentUser.uid,
        'metadata': metadata ?? <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('places')
          .add(placeData);

      // Get the created place
      final createdDoc = await docRef.get();
      final place = Place.fromMap(createdDoc.data()!, docRef.id);

      stopwatch.stop();
      AppLogger.performance('Create Place', stopwatch.elapsed);
      AppLogger.place('Place created successfully', place.id);

      return place;

    } on ValidationException catch (e) {
      AppLogger.warning('Validation error during place creation: ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error creating place', e);
      throw PlaceServiceException('Failed to create place: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error creating place', e);
      throw PlaceServiceException('Failed to create place');
    }
  }

  /// Delete a place
  Future<void> deletePlace(String placeId) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.place('Deleting place', placeId);

    try {
      // Verify place ownership or admin permissions
      final placeDoc = await _firestore.collection('places').doc(placeId).get();
      if (!placeDoc.exists) {
        throw const PlaceException('Place not found');
      }

      final placeData = placeDoc.data()!;
      if (placeData['createdBy'] != currentUser.uid) {
        throw const PlaceException('You do not have permission to delete this place');
      }

      // Delete the place
      await _firestore.collection('places').doc(placeId).delete();

      stopwatch.stop();
      AppLogger.performance('Delete Place', stopwatch.elapsed);
      AppLogger.place('Place deleted successfully', placeId);

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error deleting place', e);
      throw PlaceServiceException('Failed to delete place: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error deleting place', e);
      throw PlaceServiceException('Failed to delete place');
    }
  }

  /// Add place to user's favorites
  Future<Place?> addToFavorites(String placeId) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.place('Adding place to favorites', placeId);

    try {
      // Add to user's favorites collection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .doc(placeId)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Get and return the place
      final place = await getPlaceById(placeId);

      stopwatch.stop();
      AppLogger.performance('Add To Favorites', stopwatch.elapsed);
      AppLogger.place('Place added to favorites', placeId);

      return place;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error adding to favorites', e);
      throw PlaceServiceException('Failed to add to favorites: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error adding to favorites', e);
      throw PlaceServiceException('Failed to add to favorites');
    }
  }

  /// Remove place from user's favorites
  Future<Place?> removeFromFavorites(String placeId) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.place('Removing place from favorites', placeId);

    try {
      // Remove from user's favorites collection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .doc(placeId)
          .delete();

      // Get and return the place
      final place = await getPlaceById(placeId);

      stopwatch.stop();
      AppLogger.performance('Remove From Favorites', stopwatch.elapsed);
      AppLogger.place('Place removed from favorites', placeId);

      return place;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error removing from favorites', e);
      throw PlaceServiceException('Failed to remove from favorites: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error removing from favorites', e);
      throw PlaceServiceException('Failed to remove from favorites');
    }
  }

  /// Get user's favorite places
  Future<List<Place>> getFavoritePlaces(String userId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.place('Getting favorite places for user', userId);

    try {
      // Get user's favorite place IDs
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      final favoriteIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();
      
      if (favoriteIds.isEmpty) {
        return <Place>[];
      }

      // Get place details for each favorite
      final places = <Place>[];
      for (final placeId in favoriteIds) {
        try {
          final place = await getPlaceById(placeId);
          places.add(place!);
        } catch (e) {
          // Skip places that don't exist anymore
          AppLogger.warning('Favorite place not found: $placeId');
        }
      }

      stopwatch.stop();
      AppLogger.performance('Get Favorite Places', stopwatch.elapsed);
      AppLogger.place('Favorite places retrieved', '${places.length} places');

      return places;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting favorite places', e);
      throw PlaceServiceException('Failed to get favorite places: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error getting favorite places', e);
      throw PlaceServiceException('Failed to get favorite places');
    }
  }

  /// Check if place is in user's favorites
  Future<bool> isPlaceInFavorites(String placeId) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      return false;
    }

    AppLogger.place('Checking if place is in favorites', placeId);

    try {
      final favoriteDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .doc(placeId)
          .get();

      final isFavorite = favoriteDoc.exists;

      stopwatch.stop();
      AppLogger.performance('Check Place In Favorites', stopwatch.elapsed);
      AppLogger.place('Place favorite status checked', '$placeId: $isFavorite');

      return isFavorite;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error checking favorite status', e);
      return false;
    } catch (e) {
      AppLogger.error('Unexpected error checking favorite status', e);
      return false;
    }
  }

  /// Get places by region
  Future<List<Place>> getPlacesByRegion(String region, {PlaceCategory? category}) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.place('Getting places by region', region);

    try {
      Query<Map<String, dynamic>> placesQuery = _firestore.collection('places');

      // Add category filter if specified
      if (category != null) {
        placesQuery = placesQuery.where('category', isEqualTo: category.name);
      }

      // For now, filter by address containing the region
      // In a real app, you'd have more sophisticated region filtering
      final querySnapshot = await placesQuery
          .orderBy('averageRating', descending: true)
          .limit(50)
          .get();

      var places = querySnapshot.docs
          .map((doc) => Place.fromMap(doc.data(), doc.id))
          .toList();

      // Filter by region (client-side for now)
      places = places.where((place) =>
          place.address.toLowerCase().contains(region.toLowerCase())
      ).toList();

      stopwatch.stop();
      AppLogger.performance('Get Places By Region', stopwatch.elapsed);
      AppLogger.place('Places by region retrieved', '${places.length} places');

      return places;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting places by region', e);
      throw PlaceServiceException('Failed to get places by region: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error getting places by region', e);
      throw PlaceServiceException('Failed to get places by region');
    }
  }

  /// Get trending places
  Future<List<Place>> getTrendingPlaces({int limit = 20, Duration? timeWindow}) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.place('Getting trending places', 'limit: $limit');

    try {
      // For now, return places sorted by recent activity
      // In a real app, you'd track visit counts, ratings, etc. within the time window
      final querySnapshot = await _firestore
          .collection('places')
          .orderBy('visitCount', descending: true)
          .limit(limit)
          .get();

      final places = querySnapshot.docs
          .map((doc) => Place.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      AppLogger.performance('Get Trending Places', stopwatch.elapsed);
      AppLogger.place('Trending places retrieved', '${places.length} places');

      return places;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting trending places', e);
      throw PlaceServiceException('Failed to get trending places: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error getting trending places', e);
      throw PlaceServiceException('Failed to get trending places');
    }
  }

  /// Get place recommendations for user
  Future<PlaceRecommendations> getPlaceRecommendations(String userId, {int limit = 10}) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.place('Getting place recommendations', 'user: $userId, limit: $limit');

    try {
      // Simple recommendation logic - get highly rated places
      // In a real app, you'd use user preferences, history, etc.
      final querySnapshot = await _firestore
          .collection('places')
          .where('averageRating', isGreaterThan: 4.0)
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get();

      final places = querySnapshot.docs
          .map((doc) => Place.fromMap(doc.data(), doc.id))
          .toList();

      final recommendations = PlaceRecommendations(
        places: places,
        reason: 'Based on high ratings and popularity',
      );

      stopwatch.stop();
      AppLogger.performance('Get Place Recommendations', stopwatch.elapsed);
      AppLogger.place('Place recommendations retrieved', '${places.length} places');

      return recommendations;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting place recommendations', e);
      throw PlaceServiceException('Failed to get recommendations: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error getting place recommendations', e);
      throw PlaceServiceException('Failed to get recommendations');
    }
  }

  /// Upload place image
  Future<String> uploadPlaceImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.place('Uploading place image', imagePath);

    try {
      // This would integrate with Firebase Storage
      // For now, return a placeholder URL
      final imageUrl = 'https://placeholder.com/place-image-${DateTime.now().millisecondsSinceEpoch}.jpg';

      stopwatch.stop();
      AppLogger.performance('Upload Place Image', stopwatch.elapsed);
      AppLogger.place('Place image uploaded', imageUrl);

      return imageUrl;

    } catch (e) {
      AppLogger.error('Error uploading place image', e);
      throw PlaceServiceException('Failed to upload image');
    }
  }

  Future<void> _verifyTourPlanOwnership(String tourPlanId, String userId) async {
    final tourPlanDoc = await _firestore
        .collection('tourPlans')
        .doc(tourPlanId)
        .get();

    if (!tourPlanDoc.exists) {
      throw const PlaceException('Tour plan not found');
    }

    final tourPlanData = tourPlanDoc.data()!;
    if (tourPlanData['guideId'] != userId) {
      throw const PlaceException('You do not have permission to modify this tour plan');
    }
  }

  Future<void> _reorderPlacesAfterDeletion(String tourPlanId, int deletedOrder) async {
    final placesSnapshot = await _firestore
        .collection('tourPlans')
        .doc(tourPlanId)
        .collection('places')
        .where('order', isGreaterThan: deletedOrder)
        .get();

    final batch = _firestore.batch();
    
    for (final doc in placesSnapshot.docs) {
      final currentOrder = doc.data()['order'] as int;
      batch.update(doc.reference, {
        'order': currentOrder - 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    AppLogger.place('Places reordered after deletion', '${placesSnapshot.docs.length} places updated');
  }

  void _validatePlaceData(
    String name,
    String description,
    double latitude,
    double longitude,
    String address,
  ) {
    if (name.trim().isEmpty) {
      throw const PlaceValidationException('Place name cannot be empty');
    }
    if (name.trim().length > 100) {
      throw const PlaceValidationException('Place name cannot exceed 100 characters');
    }
    if (description.trim().isEmpty) {
      throw const PlaceValidationException('Place description cannot be empty');
    }
    if (description.trim().length > 300) {
      throw const PlaceValidationException('Place description cannot exceed 300 characters');
    }
    if (latitude < -90 || latitude > 90) {
      throw const PlaceValidationException('Invalid latitude value');
    }
    if (longitude < -180 || longitude > 180) {
      throw const PlaceValidationException('Invalid longitude value');
    }
    if (address.trim().isEmpty) {
      throw const PlaceValidationException('Address cannot be empty');
    }
    if (address.trim().length > 200) {
      throw const PlaceValidationException('Address cannot exceed 200 characters');
    }
  }

  void _validatePlaceUpdateData(
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
  ) {
    if (name != null) {
      if (name.trim().isEmpty) {
        throw const PlaceValidationException('Place name cannot be empty');
      }
      if (name.trim().length > 100) {
        throw const PlaceValidationException('Place name cannot exceed 100 characters');
      }
    }
    if (description != null) {
      if (description.trim().isEmpty) {
        throw const PlaceValidationException('Place description cannot be empty');
      }
      if (description.trim().length > 300) {
        throw const PlaceValidationException('Place description cannot exceed 300 characters');
      }
    }
    if (latitude != null) {
      if (latitude < -90 || latitude > 90) {
        throw const PlaceValidationException('Invalid latitude value');
      }
    }
    if (longitude != null) {
      if (longitude < -180 || longitude > 180) {
        throw const PlaceValidationException('Invalid longitude value');
      }
    }
    if (address != null) {
      if (address.trim().isEmpty) {
        throw const PlaceValidationException('Address cannot be empty');
      }
      if (address.trim().length > 200) {
        throw const PlaceValidationException('Address cannot exceed 200 characters');
      }
    }
  }
}

/// Place recommendations response
class PlaceRecommendations {
  final List<Place> places;
  final String reason;
  
  const PlaceRecommendations({
    required this.places,
    required this.reason,
  });
}