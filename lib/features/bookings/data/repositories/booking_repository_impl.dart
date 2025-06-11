import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/booking.dart';
import '../../domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Booking> createBooking({
    required String tourInstanceId,
    required String tourPlanId, // NEW: Add tourPlanId parameter
    required String travelerId,
    required DateTime startTime,
  }) async {
    try {
      final now = Timestamp.now();
      final startTimeTimestamp = Timestamp.fromDate(startTime);
      
      final bookingData = {
        'tourInstanceId': tourInstanceId,
        'tourPlanId': tourPlanId, // NEW: Include tourPlanId in booking data
        'travelerId': travelerId,
        'bookedAt': now,
        'startTime': startTimeTimestamp,
        'status': 'pending',
      };

      final docRef = await _firestore
          .collection(FirebaseCollections.bookings)
          .add(bookingData);

      return Booking.fromMap(bookingData, docRef.id);
    } catch (e) {
      AppLogger.error('Failed to create booking', e);
      throw Exception('Failed to create booking: $e');
    }
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.bookings)
          .doc(bookingId)
          .get();

      if (!doc.exists) return null;

      return Booking.fromMap(doc.data()!, doc.id);
    } catch (e) {
      AppLogger.error('Failed to get booking by ID', e);
      throw Exception('Failed to get booking: $e');
    }
  }

  @override
  Future<List<Booking>> getBookingsForTraveler(String travelerId) async {
    try {
      final query = await _firestore
          .collection(FirebaseCollections.bookings)
          .where('travelerId', isEqualTo: travelerId)
          .orderBy('bookedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get bookings for traveler', e);
      throw Exception('Failed to get traveler bookings: $e');
    }
  }

  @override
  Future<List<Booking>> getBookingsForGuide(String guideId) async {
    try {
      // TODO: For now, let's get bookings that reference tour plans directly
      // This is a temporary solution until tour instances are fully implemented
      
      // Method 1: Try to get bookings via tour instances
      final tourInstancesQuery = await _firestore
          .collection(FirebaseCollections.tourInstances)
          .where('guideId', isEqualTo: guideId)
          .get();

      List<String> tourInstanceIds = tourInstancesQuery.docs.map((doc) => doc.id).toList();
      
      List<Booking> bookings = [];
      
      if (tourInstanceIds.isNotEmpty) {
        // Get bookings for tour instances
        final bookingsQuery = await _firestore
            .collection(FirebaseCollections.bookings)
            .where('tourInstanceId', whereIn: tourInstanceIds)
            .orderBy('bookedAt', descending: true)
            .get();

        bookings.addAll(bookingsQuery.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .toList());
      }

      // Method 2: Also check for bookings that might reference tour plans directly
      // (temporary fallback for current system)
      final tourPlansQuery = await _firestore
          .collection(FirebaseCollections.tourPlans)
          .where('guideId', isEqualTo: guideId)
          .get();

      final tourPlanIds = tourPlansQuery.docs.map((doc) => doc.id).toList();
      
      if (tourPlanIds.isNotEmpty) {
        // Check if any bookings reference tour plans directly
        final planBookingsQuery = await _firestore
            .collection(FirebaseCollections.bookings)
            .where('tourInstanceId', whereIn: tourPlanIds)
            .orderBy('bookedAt', descending: true)
            .get();

        final planBookings = planBookingsQuery.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .toList();
        
        // Add unique bookings (avoid duplicates)
        for (final booking in planBookings) {
          if (!bookings.any((b) => b.id == booking.id)) {
            bookings.add(booking);
          }
        }
      }

      // Sort by booking date
      bookings.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
      
      return bookings;
    } catch (e) {
      AppLogger.error('Failed to get bookings for guide', e);
      throw Exception('Failed to get guide bookings: $e');
    }
  }

  @override
  Future<List<Booking>> getBookingsForTourInstance(String tourInstanceId) async {
    try {
      final query = await _firestore
          .collection(FirebaseCollections.bookings)
          .where('tourInstanceId', isEqualTo: tourInstanceId)
          .orderBy('bookedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get bookings for tour instance', e);
      throw Exception('Failed to get tour instance bookings: $e');
    }
  }

  @override
  Future<Booking> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore
          .collection(FirebaseCollections.bookings)
          .doc(bookingId)
          .update({
        'status': status,
      });

      final updatedDoc = await _firestore
          .collection(FirebaseCollections.bookings)
          .doc(bookingId)
          .get();

      return Booking.fromMap(updatedDoc.data()!, updatedDoc.id);
    } catch (e) {
      AppLogger.error('Failed to update booking status', e);
      throw Exception('Failed to update booking status: $e');
    }
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.bookings)
          .doc(bookingId)
          .update({
        'status': 'cancelled',
      });
    } catch (e) {
      AppLogger.error('Failed to cancel booking', e);
      throw Exception('Failed to cancel booking: $e');
    }
  }

  @override
  Future<bool> hasExistingBooking(String travelerId, String tourInstanceId) async {
    try {
      final query = await _firestore
          .collection(FirebaseCollections.bookings)
          .where('travelerId', isEqualTo: travelerId)
          .where('tourInstanceId', isEqualTo: tourInstanceId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Failed to check existing booking', e);
      throw Exception('Failed to check existing booking: $e');
    }
  }
}