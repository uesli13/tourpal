import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Base class for all booking events
abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to book a tour
class BookTourEvent extends BookingEvent {
  final String tourInstanceId;
  final String travelerId;
  final Timestamp startTime;

  const BookTourEvent({
    required this.tourInstanceId,
    required this.travelerId,
    required this.startTime,
  });

  @override
  List<Object> get props => [tourInstanceId, travelerId, startTime];
}

/// Event to load traveler's bookings
class LoadTravelerBookingsEvent extends BookingEvent {
  final String travelerId;

  const LoadTravelerBookingsEvent({required this.travelerId});

  @override
  List<Object> get props => [travelerId];
}

/// Event to load guide's bookings
class LoadGuideBookingsEvent extends BookingEvent {
  final String guideId;

  const LoadGuideBookingsEvent({required this.guideId});

  @override
  List<Object> get props => [guideId];
}

/// Event to confirm a booking
class ConfirmBookingEvent extends BookingEvent {
  final String bookingId;

  const ConfirmBookingEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// Event to cancel a booking
class CancelBookingEvent extends BookingEvent {
  final String bookingId;

  const CancelBookingEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// Event to load booking details
class LoadBookingDetailsEvent extends BookingEvent {
  final String bookingId;

  const LoadBookingDetailsEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}