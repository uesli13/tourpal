import 'package:cloud_firestore/cloud_firestore.dart';

class UserLocation {
  final String id;
  final String userId;
  final String tourInstanceId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final Timestamp timestamp;
  final bool isActive;

  UserLocation({
    required this.id,
    required this.userId,
    required this.tourInstanceId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.isActive,
  });

  factory UserLocation.fromMap(Map<String, dynamic> map, String documentId) {
    return UserLocation(
      id: documentId,
      userId: map['userId'] as String,
      tourInstanceId: map['tourInstanceId'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      timestamp: map['timestamp'] as Timestamp,
      isActive: map['isActive'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tourInstanceId': tourInstanceId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp,
      'isActive': isActive,
    };
  }

  UserLocation copyWith({
    String? id,
    String? userId,
    String? tourInstanceId,
    double? latitude,
    double? longitude,
    double? accuracy,
    Timestamp? timestamp,
    bool? isActive,
  }) {
    return UserLocation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tourInstanceId: tourInstanceId ?? this.tourInstanceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'UserLocation(id: $id, userId: $userId, lat: $latitude, lng: $longitude, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserLocation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}