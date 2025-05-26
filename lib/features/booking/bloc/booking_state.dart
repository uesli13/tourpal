import 'package:equatable/equatable.dart';
import '../../../models/booking.dart';

abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingsLoaded extends BookingState {
  final List<Booking> bookings;

  const BookingsLoaded({required this.bookings});

  @override
  List<Object> get props => [bookings];
}

class BookingCreated extends BookingState {
  final String bookingId;

  const BookingCreated({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class BookingUpdated extends BookingState {}

class BookingError extends BookingState {
  final String message;

  const BookingError({required this.message});

  @override
  List<Object> get props => [message];
}