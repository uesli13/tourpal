import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import '../core/errors/error_handler.dart';

/// Simple booking service following TourPal's KEEP THINGS SIMPLE principle
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'bookings';

  /// Create a new booking
  Future<String> createBooking({
    required String tourId,
    required String guideId, 
    required String tourTitle,
    required DateTime tourDate,
    required int numberOfPeople,
    required double totalPrice,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw AppException('User not authenticated');

      final bookingRef = _firestore.collection(_collection).doc();
      final now = DateTime.now();

      final booking = Booking(
        id: bookingRef.id,
        userId: user.uid,
        tourId: tourId,
        guideId: guideId,
        tourTitle: tourTitle,
        bookingDate: now,
        tourDate: tourDate,
        numberOfPeople: numberOfPeople,
        totalPrice: totalPrice,
        status: BookingStatus.pending,
        createdAt: now,
      );

      await bookingRef.set(booking.toMap());
      AppErrorHandler.logInfo('Booking created: ${bookingRef.id}');
      return bookingRef.id;
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Failed to create booking');
    }
  }

  /// Get user's bookings
  Future<List<Booking>> getUserBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Failed to load bookings');
    }
  }

  /// Get guide's bookings
  Future<List<Booking>> getGuideBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(_collection)
          .where('guideId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Failed to load guide bookings');
    }
  }

  /// Update booking status (for guides)
  Future<void> updateBookingStatus(String bookingId, BookingStatus status, {String? message}) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };
      
      if (message != null) {
        updateData['guideMessage'] = message;
      }

      await _firestore.collection(_collection).doc(bookingId).update(updateData);
      AppErrorHandler.logInfo('Booking status updated: $bookingId -> ${status.name}');
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Failed to update booking');
    }
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await updateBookingStatus(bookingId, BookingStatus.cancelled);
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Failed to cancel booking');
    }
  }
}