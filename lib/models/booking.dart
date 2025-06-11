import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String tourInstanceId;
  final String tourPlanId;
  final String travelerId;
  final Timestamp bookedAt;
  final String status; // "pending", "confirmed", "cancelled"
  final Timestamp startTime; // Exact tour start date and time

  Booking({
    required this.id,
    required this.tourInstanceId,
    required this.tourPlanId,
    required this.travelerId,
    required this.bookedAt,
    required this.status,
    required this.startTime,
  });

  String get userId => travelerId;
  String get userName => 'User'; // Placeholder - would need proper user lookup

  factory Booking.fromMap(Map<String, dynamic> map, String documentId) {
    return Booking(
      id: documentId,
      tourInstanceId: map['tourInstanceId'] as String,
      tourPlanId: map['tourPlanId'] as String, // NEW: Parse from map
      travelerId: map['travelerId'] as String,
      bookedAt: map['bookedAt'] as Timestamp,
      status: map['status'] as String,
      startTime: map['startTime'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tourInstanceId': tourInstanceId,
      'tourPlanId': tourPlanId,
      'travelerId': travelerId,
      'bookedAt': bookedAt,
      'status': status,
      'startTime': startTime,
    };
  }

  Booking copyWith({
    String? id,
    String? tourInstanceId,
    String? tourPlanId,
    String? travelerId,
    Timestamp? bookedAt,
    String? status,
    Timestamp? startTime,
  }) {
    return Booking(
      id: id ?? this.id,
      tourInstanceId: tourInstanceId ?? this.tourInstanceId,
      tourPlanId: tourPlanId ?? this.tourPlanId,
      travelerId: travelerId ?? this.travelerId,
      bookedAt: bookedAt ?? this.bookedAt,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
    );
  }

  @override
  String toString() {
    return 'Booking(id: $id, status: $status, travelerId: $travelerId, tourPlanId: $tourPlanId, startTime: $startTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}