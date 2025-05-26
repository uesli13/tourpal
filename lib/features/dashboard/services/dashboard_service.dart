import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/logger.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../models/tour_plan.dart';
import '../../../models/booking.dart';
import '../presentation/bloc/dashboard_state.dart';

/// Dashboard service following TourPal service layer rules
/// 
/// Handles Firebase operations for dashboard data aggregation:
/// - Recent tours for user
/// - Favorite tours
/// - User statistics and metrics
/// - Performance tracking
class DashboardService {
  final FirebaseFirestore _firestore;
  
  DashboardService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get recent tours for a user (based on booking history)
  Future<List<TourPlan>> getRecentTours(String userId, {int limit = 5}) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Getting recent tours for user: $userId');

    try {
      // Get user's recent bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      if (bookingsSnapshot.docs.isEmpty) {
        AppLogger.info('No recent bookings found for user: $userId');
        return <TourPlan>[];
      }

      // Get tour plan IDs from bookings
      final tourPlanIds = bookingsSnapshot.docs
          .map((doc) => doc.data()['tourPlanId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();

      if (tourPlanIds.isEmpty) {
        return <TourPlan>[];
      }

      // Get tour plans
      final tourPlansSnapshot = await _firestore
          .collection('tourPlans')
          .where(FieldPath.documentId, whereIn: tourPlanIds)
          .get();

      final tourPlans = tourPlansSnapshot.docs
          .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      AppLogger.performance('Get Recent Tours', stopwatch.elapsed);
      AppLogger.serviceOperation('DashboardService', 'getRecentTours', true);

      return tourPlans;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting recent tours', e);
      AppLogger.serviceOperation('DashboardService', 'getRecentTours', false);
      throw DashboardException('Failed to get recent tours: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error getting recent tours', e);
      AppLogger.serviceOperation('DashboardService', 'getRecentTours', false);
      throw const DashboardException('Failed to retrieve recent tours');
    }
  }

  /// Get favorite tours for a user
  Future<List<TourPlan>> getFavoriteTours(String userId, {int limit = 5}) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Getting favorite tours for user: $userId');

    try {
      // Get user's profile to access favorite tours
      final userSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userSnapshot.exists) {
        AppLogger.warning('User not found: $userId');
        return <TourPlan>[];
      }

      final userData = userSnapshot.data()!;
      final favoriteTourIds = List<String>.from(userData['favoriteTours'] ?? []);

      if (favoriteTourIds.isEmpty) {
        AppLogger.info('No favorite tours found for user: $userId');
        return <TourPlan>[];
      }

      // Limit the number of IDs to query
      final limitedIds = favoriteTourIds.take(limit).toList();

      // Get favorite tour plans
      final tourPlansSnapshot = await _firestore
          .collection('tourPlans')
          .where(FieldPath.documentId, whereIn: limitedIds)
          .get();

      final tourPlans = tourPlansSnapshot.docs
          .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      AppLogger.performance('Get Favorite Tours', stopwatch.elapsed);
      AppLogger.serviceOperation('DashboardService', 'getFavoriteTours', true);

      return tourPlans;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting favorite tours', e);
      AppLogger.serviceOperation('DashboardService', 'getFavoriteTours', false);
      throw DashboardException('Failed to get favorite tours: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error getting favorite tours', e);
      AppLogger.serviceOperation('DashboardService', 'getFavoriteTours', false);
      throw const DashboardException('Failed to retrieve favorite tours');
    }
  }

  /// Get user statistics for dashboard
  Future<DashboardStats> getUserStats(String userId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Getting user stats for: $userId');

    try {
      // Get all user bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      // Get user reviews
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      // Calculate statistics
      final bookings = bookingsSnapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();

      final totalBookings = bookings.length;
      final completedTours = bookings
          .where((booking) => booking.status == BookingStatus.completed)
          .length;
      final upcomingBookings = bookings
          .where((booking) => booking.status == BookingStatus.confirmed && 
                 booking.tourDate.isAfter(DateTime.now()))
          .length;
      final totalSpent = bookings
          .where((booking) => booking.status == BookingStatus.completed)
          .fold<double>(0.0, (sum, booking) => sum + (booking.totalPrice ?? 0.0));
      final reviewsGiven = reviewsSnapshot.docs.length;

      final stats = DashboardStats(
        totalBookings: totalBookings,
        completedTours: completedTours,
        upcomingBookings: upcomingBookings,
        totalSpent: totalSpent,
        reviewsGiven: reviewsGiven,
      );

      stopwatch.stop();
      AppLogger.performance('Get User Stats', stopwatch.elapsed);
      AppLogger.serviceOperation('DashboardService', 'getUserStats', true);

      return stats;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting user stats', e);
      AppLogger.serviceOperation('DashboardService', 'getUserStats', false);
      throw DashboardException('Failed to get user statistics: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error getting user stats', e);
      AppLogger.serviceOperation('DashboardService', 'getUserStats', false);
      throw const DashboardException('Failed to retrieve user statistics');
    }
  }

  /// Get quick overview data for dashboard
  Future<Map<String, dynamic>> getDashboardOverview(String userId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Getting dashboard overview for user: $userId');

    try {
      final results = await Future.wait([
        getRecentTours(userId, limit: 3),
        getFavoriteTours(userId, limit: 3),
        getUserStats(userId),
      ]);

      final overview = {
        'recentTours': results[0],
        'favoriteTours': results[1],
        'stats': results[2],
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      stopwatch.stop();
      AppLogger.performance('Get Dashboard Overview', stopwatch.elapsed);
      AppLogger.serviceOperation('DashboardService', 'getDashboardOverview', true);

      return overview;

    } catch (e) {
      AppLogger.error('Error getting dashboard overview', e);
      AppLogger.serviceOperation('DashboardService', 'getDashboardOverview', false);
      rethrow;
    }
  }
}