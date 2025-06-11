import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../services/booking_service.dart';
import 'booking_event.dart';
import 'booking_state.dart';

/// BLoC to handle booking-related business logic
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingService _bookingService;

  BookingBloc({
    required BookingService bookingService,
  })  : _bookingService = bookingService,
        super(const BookingInitial()) {
    
    AppLogger.info('BookingBloc initialized');
    
    // Register event handlers
    on<BookTourEvent>(_onBookTour);
    on<LoadTravelerBookingsEvent>(_onLoadTravelerBookings);
    on<LoadGuideBookingsEvent>(_onLoadGuideBookings);
    on<ConfirmBookingEvent>(_onConfirmBooking);
    on<CancelBookingEvent>(_onCancelBooking);
    on<LoadBookingDetailsEvent>(_onLoadBookingDetails);
  }

  @override
  void onChange(Change<BookingState> change) {
    super.onChange(change);
    AppLogger.blocTransition(
      'BookingBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(BookingEvent event) {
    super.onEvent(event);
    AppLogger.blocEvent('BookingBloc', event.runtimeType.toString());
  }

  /// Handle booking a tour
  Future<void> _onBookTour(
    BookTourEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    
    try {
      final booking = await _bookingService.bookTour(
        tourInstanceId: event.tourInstanceId,
        travelerId: event.travelerId,
        startTime: event.startTime.toDate(), // Convert Timestamp to DateTime
      );
      
      emit(BookingSuccess(booking: booking));
    } on BookingValidationException catch (e) {
      AppLogger.error('Booking validation failed', e);
      emit(BookingError(message: e.message));
    } on BookingServiceException catch (e) {
      AppLogger.error('Booking service failed', e);
      emit(BookingError(message: e.message));
    } on BookingException catch (e) {
      AppLogger.error('Booking failed', e);
      emit(BookingError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected booking error', e);
      emit(const BookingError(message: 'An unexpected error occurred while booking'));
    }
  }

  /// Handle loading traveler bookings
  Future<void> _onLoadTravelerBookings(
    LoadTravelerBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    
    try {
      final bookings = await _bookingService.getTravelerBookings(event.travelerId);
      emit(BookingsLoaded(bookings: bookings));
    } on BookingServiceException catch (e) {
      AppLogger.error('Failed to load traveler bookings', e);
      emit(BookingError(message: e.message));
    } on BookingException catch (e) {
      AppLogger.error('Failed to load traveler bookings', e);
      emit(BookingError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error loading traveler bookings', e);
      emit(const BookingError(message: 'Failed to load your bookings'));
    }
  }

  /// Handle loading guide bookings
  Future<void> _onLoadGuideBookings(
    LoadGuideBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    
    try {
      final bookings = await _bookingService.getGuideBookings(event.guideId);
      emit(BookingsLoaded(bookings: bookings));
    } on BookingServiceException catch (e) {
      AppLogger.error('Failed to load guide bookings', e);
      emit(BookingError(message: e.message));
    } on BookingException catch (e) {
      AppLogger.error('Failed to load guide bookings', e);
      emit(BookingError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error loading guide bookings', e);
      emit(const BookingError(message: 'Failed to load bookings'));
    }
  }

  /// Handle confirming a booking
  Future<void> _onConfirmBooking(
    ConfirmBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    
    try {
      final booking = await _bookingService.confirmBooking(event.bookingId);
      emit(BookingConfirmed(booking: booking));
    } on BookingServiceException catch (e) {
      AppLogger.error('Failed to confirm booking', e);
      emit(BookingError(message: e.message));
    } on BookingException catch (e) {
      AppLogger.error('Failed to confirm booking', e);
      emit(BookingError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error confirming booking', e);
      emit(const BookingError(message: 'Failed to confirm booking'));
    }
  }

  /// Handle cancelling a booking
  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    
    try {
      await _bookingService.cancelBooking(event.bookingId);
      emit(BookingCancelled(bookingId: event.bookingId));
    } on BookingServiceException catch (e) {
      AppLogger.error('Failed to cancel booking', e);
      emit(BookingError(message: e.message));
    } on BookingException catch (e) {
      AppLogger.error('Failed to cancel booking', e);
      emit(BookingError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error cancelling booking', e);
      emit(const BookingError(message: 'Failed to cancel booking'));
    }
  }

  /// Handle loading booking details
  Future<void> _onLoadBookingDetails(
    LoadBookingDetailsEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    
    try {
      final booking = await _bookingService.getBookingDetails(event.bookingId);
      if (booking != null) {
        emit(BookingDetailsLoaded(booking: booking));
      } else {
        emit(const BookingError(message: 'Booking not found'));
      }
    } on BookingServiceException catch (e) {
      AppLogger.error('Failed to load booking details', e);
      emit(BookingError(message: e.message));
    } on BookingException catch (e) {
      AppLogger.error('Failed to load booking details', e);
      emit(BookingError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error loading booking details', e);
      emit(const BookingError(message: 'Failed to load booking details'));
    }
  }
}