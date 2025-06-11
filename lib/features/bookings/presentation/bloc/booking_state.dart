import 'package:equatable/equatable.dart';
import '../../../../models/booking.dart';

/// Base class for all booking states
abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the BLoC is first created
class BookingInitial extends BookingState {
  const BookingInitial();
}

/// State when booking operation is in progress
class BookingLoading extends BookingState {
  const BookingLoading();
}

/// State when booking is successfully created
class BookingSuccess extends BookingState {
  final Booking booking;

  const BookingSuccess({required this.booking});

  @override
  List<Object> get props => [booking];
}

/// State when bookings are successfully loaded
class BookingsLoaded extends BookingState {
  final List<Booking> bookings;

  const BookingsLoaded({required this.bookings});

  @override
  List<Object> get props => [bookings];
}

/// State when booking details are loaded
class BookingDetailsLoaded extends BookingState {
  final Booking booking;

  const BookingDetailsLoaded({required this.booking});

  @override
  List<Object> get props => [booking];
}

/// State when booking is confirmed
class BookingConfirmed extends BookingState {
  final Booking booking;

  const BookingConfirmed({required this.booking});

  @override
  List<Object> get props => [booking];
}

/// State when booking is cancelled
class BookingCancelled extends BookingState {
  final String bookingId;

  const BookingCancelled({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// State when booking operation fails
class BookingError extends BookingState {
  final String message;

  const BookingError({required this.message});

  @override
  List<Object> get props => [message];
}