import 'package:equatable/equatable.dart';
import '../../../models/booking.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class LoadUserBookingsEvent extends BookingEvent {}

class LoadGuideBookingsEvent extends BookingEvent {}

class CreateBookingEvent extends BookingEvent {
  final String tourId;
  final String guideId;
  final String tourTitle;
  final DateTime tourDate;
  final int numberOfPeople;
  final double totalPrice;

  const CreateBookingEvent({
    required this.tourId,
    required this.guideId,
    required this.tourTitle,
    required this.tourDate,
    required this.numberOfPeople,
    required this.totalPrice,
  });

  @override
  List<Object> get props => [tourId, guideId, tourTitle, tourDate, numberOfPeople, totalPrice];
}

class UpdateBookingStatusEvent extends BookingEvent {
  final String bookingId;
  final BookingStatus status;
  final String? message;

  const UpdateBookingStatusEvent({
    required this.bookingId,
    required this.status,
    this.message,
  });

  @override
  List<Object?> get props => [bookingId, status, message];
}