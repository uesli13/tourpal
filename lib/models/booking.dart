import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple booking model following TourPal's KEEP THINGS SIMPLE principle
class Booking extends Equatable {
  final String id;
  final String userId;
  final String tourId;
  final String guideId;
  final String tourTitle;
  final DateTime bookingDate;
  final DateTime tourDate;
  final int numberOfPeople;
  final double totalPrice;
  final BookingStatus status;
  final String? guideMessage;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.tourId,
    required this.guideId,
    required this.tourTitle,
    required this.bookingDate,
    required this.tourDate,
    required this.numberOfPeople,
    required this.totalPrice,
    required this.status,
    this.guideMessage,
    required this.createdAt,
  });

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      userId: map['userId'] as String? ?? '',
      tourId: map['tourId'] as String? ?? '',
      guideId: map['guideId'] as String? ?? '',
      tourTitle: map['tourTitle'] as String? ?? '',
      bookingDate: _parseDateTime(map['bookingDate']),
      tourDate: _parseDateTime(map['tourDate']),
      numberOfPeople: map['numberOfPeople'] as int? ?? 1,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: BookingStatus.values.firstWhere(
        (status) => status.name == (map['status'] as String? ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      guideMessage: map['guideMessage'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tourId': tourId,
      'guideId': guideId,
      'tourTitle': tourTitle,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'tourDate': Timestamp.fromDate(tourDate),
      'numberOfPeople': numberOfPeople,
      'totalPrice': totalPrice,
      'status': status.name,
      'guideMessage': guideMessage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Booking copyWith({
    BookingStatus? status,
    String? guideMessage,
  }) {
    return Booking(
      id: id,
      userId: userId,
      tourId: tourId,
      guideId: guideId,
      tourTitle: tourTitle,
      bookingDate: bookingDate,
      tourDate: tourDate,
      numberOfPeople: numberOfPeople,
      totalPrice: totalPrice,
      status: status ?? this.status,
      guideMessage: guideMessage ?? this.guideMessage,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id, userId, tourId, guideId, tourTitle, bookingDate, tourDate, 
    numberOfPeople, totalPrice, status, guideMessage, createdAt
  ];
}

/// Simple booking status enum
enum BookingStatus {
  pending('Pending', '⏳'),
  confirmed('Confirmed', '✅'),
  cancelled('Cancelled', '❌'),
  completed('Completed', '🎯');

  const BookingStatus(this.displayName, this.emoji);
  
  final String displayName;
  final String emoji;
}