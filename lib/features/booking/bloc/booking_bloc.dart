import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/booking_service.dart';
import '../../../core/utils/logger.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingService _bookingService;

  BookingBloc({required BookingService bookingService})
      : _bookingService = bookingService,
        super(BookingInitial()) {
    
    AppLogger.info('BookingBloc initialized');
    
    on<LoadUserBookingsEvent>(_onLoadUserBookings);
    on<LoadGuideBookingsEvent>(_onLoadGuideBookings);
    on<CreateBookingEvent>(_onCreateBooking);
    on<UpdateBookingStatusEvent>(_onUpdateBookingStatus);
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

  Future<void> _onLoadUserBookings(
    LoadUserBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      final bookings = await _bookingService.getUserBookings();
      emit(BookingsLoaded(bookings: bookings));
      AppLogger.info('User bookings loaded: ${bookings.length}');
    } catch (e) {
      AppLogger.error('Failed to load user bookings', e);
      emit(BookingError(message: 'Failed to load your bookings'));
    }
  }

  Future<void> _onLoadGuideBookings(
    LoadGuideBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      final bookings = await _bookingService.getGuideBookings();
      emit(BookingsLoaded(bookings: bookings));
      AppLogger.info('Guide bookings loaded: ${bookings.length}');
    } catch (e) {
      AppLogger.error('Failed to load guide bookings', e);
      emit(BookingError(message: 'Failed to load guide bookings'));
    }
  }

  Future<void> _onCreateBooking(
    CreateBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      
      // Simple validation
      if (event.tourDate.isBefore(DateTime.now())) {
        emit(BookingError(message: 'Tour date must be in the future'));
        return;
      }
      
      if (event.numberOfPeople < 1 || event.numberOfPeople > 20) {
        emit(BookingError(message: 'Number of people must be between 1 and 20'));
        return;
      }

      final bookingId = await _bookingService.createBooking(
        tourId: event.tourId,
        guideId: event.guideId,
        tourTitle: event.tourTitle,
        tourDate: event.tourDate,
        numberOfPeople: event.numberOfPeople,
        totalPrice: event.totalPrice,
      );

      emit(BookingCreated(bookingId: bookingId));
      AppLogger.info('Booking created: $bookingId');
    } catch (e) {
      AppLogger.error('Failed to create booking', e);
      emit(BookingError(message: 'Failed to create booking'));
    }
  }

  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatusEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      await _bookingService.updateBookingStatus(
        event.bookingId,
        event.status,
        message: event.message,
      );
      emit(BookingUpdated());
      AppLogger.info('Booking status updated: ${event.bookingId}');
    } catch (e) {
      AppLogger.error('Failed to update booking status', e);
      emit(BookingError(message: 'Failed to update booking'));
    }
  }
}