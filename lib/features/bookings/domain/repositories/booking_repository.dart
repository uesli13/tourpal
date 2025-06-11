import '../../../../models/booking.dart';

/// Repository interface for booking operations
abstract class BookingRepository {
  /// Create a new booking
  Future<Booking> createBooking({
    required String tourInstanceId,
    required String tourPlanId, // NEW: Add tourPlanId parameter
    required String travelerId,
    required DateTime startTime,
  });

  /// Get booking by ID
  Future<Booking?> getBookingById(String bookingId);

  /// Get all bookings for a traveler
  Future<List<Booking>> getBookingsForTraveler(String travelerId);

  /// Get all bookings for a guide
  Future<List<Booking>> getBookingsForGuide(String guideId);

  /// Get all bookings for a specific tour instance
  Future<List<Booking>> getBookingsForTourInstance(String tourInstanceId);

  /// Update booking status
  Future<Booking> updateBookingStatus(String bookingId, String status);

  /// Cancel booking
  Future<void> cancelBooking(String bookingId);

  /// Check if user already has a booking for this tour instance
  Future<bool> hasExistingBooking(String travelerId, String tourInstanceId);
}