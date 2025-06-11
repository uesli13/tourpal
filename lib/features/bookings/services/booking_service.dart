import '../../../models/booking.dart';
import '../../../core/utils/logger.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../domain/repositories/booking_repository.dart';

/// Service class for booking business logic
class BookingService {
  final BookingRepository _bookingRepository;

  BookingService({required BookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  /// Book a tour instance
  Future<Booking> bookTour({
    required String tourInstanceId,
    required String travelerId,
    required DateTime startTime,
  }) async {
    try {
      // Check if user already has a booking for this tour instance
      final hasExisting = await _bookingRepository.hasExistingBooking(
        travelerId,
        tourInstanceId,
      );

      if (hasExisting) {
        throw const BookingValidationException('You already have a booking for this tour');
      }

      // Get the tour plan ID from the tour instance
      // For now, we'll assume tourInstanceId might be the tourPlanId directly
      // This is a temporary solution until tour instances are fully implemented
      String tourPlanId = tourInstanceId; // Temporary: assume they're the same
      
      // TODO: In the future, fetch the actual tour instance to get the tourPlanId
      // final tourInstance = await _tourInstanceRepository.getTourInstanceById(tourInstanceId);
      // tourPlanId = tourInstance.tourPlanId;

      // Create the booking
      final booking = await _bookingRepository.createBooking(
        tourInstanceId: tourInstanceId,
        tourPlanId: tourPlanId, // NEW: Pass the tourPlanId
        travelerId: travelerId,
        startTime: startTime,
      );

      AppLogger.info('Booking created successfully: ${booking.id}');
      return booking;
    } catch (e) {
      AppLogger.error('Failed to book tour', e);
      if (e is BookingException) rethrow;
      throw BookingServiceException('Failed to book tour: $e');
    }
  }

  /// Get bookings for a traveler
  Future<List<Booking>> getTravelerBookings(String travelerId) async {
    try {
      return await _bookingRepository.getBookingsForTraveler(travelerId);
    } catch (e) {
      AppLogger.error('Failed to get traveler bookings', e);
      throw BookingServiceException('Failed to load your bookings: $e');
    }
  }

  /// Get bookings for a guide
  Future<List<Booking>> getGuideBookings(String guideId) async {
    try {
      return await _bookingRepository.getBookingsForGuide(guideId);
    } catch (e) {
      AppLogger.error('Failed to get guide bookings', e);
      throw BookingServiceException('Failed to load guide bookings: $e');
    }
  }

  /// Confirm a booking (guide action)
  Future<Booking> confirmBooking(String bookingId) async {
    try {
      return await _bookingRepository.updateBookingStatus(bookingId, 'confirmed');
    } catch (e) {
      AppLogger.error('Failed to confirm booking', e);
      throw BookingServiceException('Failed to confirm booking: $e');
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _bookingRepository.cancelBooking(bookingId);
      AppLogger.info('Booking cancelled: $bookingId');
    } catch (e) {
      AppLogger.error('Failed to cancel booking', e);
      throw BookingServiceException('Failed to cancel booking: $e');
    }
  }

  /// Get booking details by ID
  Future<Booking?> getBookingDetails(String bookingId) async {
    try {
      return await _bookingRepository.getBookingById(bookingId);
    } catch (e) {
      AppLogger.error('Failed to get booking details', e);
      throw BookingServiceException('Failed to load booking details: $e');
    }
  }

  /// Get all bookings for a specific tour instance
  Future<List<Booking>> getTourInstanceBookings(String tourInstanceId) async {
    try {
      return await _bookingRepository.getBookingsForTourInstance(tourInstanceId);
    } catch (e) {
      AppLogger.error('Failed to get tour instance bookings', e);
      throw BookingServiceException('Failed to load tour bookings: $e');
    }
  }
}