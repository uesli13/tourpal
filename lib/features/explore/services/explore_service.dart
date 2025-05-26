import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourpal/features/tours/domain/entities/tour.dart';
import 'package:tourpal/features/tours/domain/enums/tour_category.dart';
import 'package:tourpal/features/tours/domain/enums/tour_difficulty.dart';
import '../../../../core/utils/logger.dart';

/// Service for explore functionality to fetch and manage tours for exploration
/// Follows TOURPAL service layer rules
class ExploreService {
  final FirebaseFirestore _firestore;

  ExploreService(this._firestore);

  /// Get all public tours for exploration
  Future<List<Tour>> getAllTours() async {
    try {
      AppLogger.info('Loading all public tours for exploration');
      
      final snapshot = await _firestore
          .collection('tours')
          .where('is_published', isEqualTo: true)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(100) // Limit for performance
          .get();

      final tours = snapshot.docs
          .map((doc) => Tour.fromJson(doc.data()))
          .toList();
          
      AppLogger.info('Loaded ${tours.length} tours for exploration');
      return tours;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error loading tours for exploration', e);
      throw ExploreServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('Failed to load tours for exploration', e);
      throw ExploreServiceException('Failed to load tours: ${e.toString()}');
    }
  }

  /// Get featured tours
  Future<List<Tour>> getFeaturedTours() async {
    try {
      AppLogger.info('Loading featured tours');
      
      final snapshot = await _firestore
          .collection('tours')
          .where('is_published', isEqualTo: true)
          .where('is_active', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(10)
          .get();

      final tours = snapshot.docs
          .map((doc) => Tour.fromJson(doc.data()))
          .toList();
          
      AppLogger.info('Loaded ${tours.length} featured tours');
      return tours;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error loading featured tours', e);
      throw ExploreServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('Failed to load featured tours', e);
      throw ExploreServiceException('Failed to load featured tours: ${e.toString()}');
    }
  }

  /// Get tours by location (nearby tours)
  Future<List<Tour>> getToursByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      AppLogger.info('Loading tours near location: $latitude, $longitude (radius: ${radiusKm}km)');
      
      // Note: For proper geo queries, you'd use Firestore's geo features
      // For now, we'll get all tours and filter client-side (not ideal for production)
      final snapshot = await _firestore
          .collection('tours')
          .where('is_published', isEqualTo: true)
          .where('is_active', isEqualTo: true)
          .limit(50)
          .get();

      final tours = snapshot.docs
          .map((doc) => Tour.fromJson(doc.data()))
          .toList();
          
      // Simple distance filtering (in production, use proper geo queries)
      final nearbyTours = tours.where((tour) {
        // Simple distance calculation (not precise, but sufficient for demo)
        final distance = _calculateDistance(
          latitude, longitude,
          tour.startLocation.latitude,
          tour.startLocation.longitude,
        );
        return distance <= radiusKm;
      }).toList();
          
      AppLogger.info('Found ${nearbyTours.length} tours within ${radiusKm}km');
      return nearbyTours;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error loading nearby tours', e);
      throw ExploreServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('Failed to load nearby tours', e);
      throw ExploreServiceException('Failed to load nearby tours: ${e.toString()}');
    }
  }

  /// Search tours by query
  Future<List<Tour>> searchTours(String query) async {
    try {
      AppLogger.info('Searching tours with query: "$query"');
      
      if (query.isEmpty) {
        return getAllTours();
      }

      // Note: Firestore doesn't have great text search capabilities
      // In production, you'd use Algolia or similar service
      final snapshot = await _firestore
          .collection('tours')
          .where('is_published', isEqualTo: true)
          .where('is_active', isEqualTo: true)
          .orderBy('title')
          .get();

      final tours = snapshot.docs
          .map((doc) => Tour.fromJson(doc.data()))
          .where((tour) {
            final searchLower = query.toLowerCase();
            return tour.title.toLowerCase().contains(searchLower) ||
                   tour.description.toLowerCase().contains(searchLower);
          })
          .toList();
          
      AppLogger.info('Found ${tours.length} tours matching "$query"');
      return tours;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error searching tours', e);
      throw ExploreServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('Failed to search tours', e);
      throw ExploreServiceException('Failed to search tours: ${e.toString()}');
    }
  }

  /// Get tours by category
  Future<List<Tour>> getToursByCategory(TourCategory category) async {
    try {
      AppLogger.info('Loading tours by category: ${category.displayName}');
      
      final snapshot = await _firestore
          .collection('tours')
          .where('is_published', isEqualTo: true)
          .where('is_active', isEqualTo: true)
          .where('category', isEqualTo: category.name)
          .orderBy('created_at', descending: true)
          .get();

      final tours = snapshot.docs
          .map((doc) => Tour.fromJson(doc.data()))
          .toList();
          
      AppLogger.info('Loaded ${tours.length} tours for category: ${category.displayName}');
      return tours;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error loading tours by category', e);
      throw ExploreServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('Failed to load tours by category', e);
      throw ExploreServiceException('Failed to load tours by category: ${e.toString()}');
    }
  }

  /// Get tours by difficulty
  Future<List<Tour>> getToursByDifficulty(TourDifficulty difficulty) async {
    try {
      AppLogger.info('Loading tours by difficulty: ${difficulty.displayName}');
      
      final snapshot = await _firestore
          .collection('tours')
          .where('is_published', isEqualTo: true)
          .where('is_active', isEqualTo: true)
          .where('difficulty', isEqualTo: difficulty.name)
          .orderBy('created_at', descending: true)
          .get();

      final tours = snapshot.docs
          .map((doc) => Tour.fromJson(doc.data()))
          .toList();
          
      AppLogger.info('Loaded ${tours.length} tours for difficulty: ${difficulty.displayName}');
      return tours;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error loading tours by difficulty', e);
      throw ExploreServiceException('Firebase error: ${e.message}');
    } catch (e) {
      AppLogger.error('Failed to load tours by difficulty', e);
      throw ExploreServiceException('Failed to load tours by difficulty: ${e.toString()}');
    }
  }

  /// Get popular destinations (simplified)
  Future<List<String>> getPopularDestinations() async {
    try {
      AppLogger.info('Loading popular destinations');
      
      // In production, this would be a more sophisticated query
      // For now, return some static popular destinations
      final destinations = [
        'Paris, France',
        'Tokyo, Japan',
        'New York, USA',
        'London, UK',
        'Rome, Italy',
        'Barcelona, Spain',
        'Amsterdam, Netherlands',
        'Bangkok, Thailand',
      ];
      
      AppLogger.info('Loaded ${destinations.length} popular destinations');
      return destinations;
    } catch (e) {
      AppLogger.error('Failed to load popular destinations', e);
      throw ExploreServiceException('Failed to load popular destinations: ${e.toString()}');
    }
  }

  /// Calculate simple distance between two points (not precise, for demo only)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple distance calculation (not using proper haversine formula)
    final dLat = (lat2 - lat1).abs();
    final dLon = (lon2 - lon1).abs();
    return (dLat + dLon) * 111; // Rough km conversion
  }
}

/// Custom exception for explore service operations
class ExploreServiceException implements Exception {
  final String message;

  const ExploreServiceException(this.message);

  @override
  String toString() => 'ExploreServiceException: $message';
}