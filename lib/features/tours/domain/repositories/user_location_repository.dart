import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserLocation {
  final String userId;
  final String tourInstanceId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  UserLocation({
    required this.userId,
    required this.tourInstanceId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  factory UserLocation.fromMap(Map<String, dynamic> map) {
    return UserLocation(
      userId: map['userId'] ?? '',
      tourInstanceId: map['tourInstanceId'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tourInstanceId': tourInstanceId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

abstract class UserLocationRepository {
  /// Start tracking user location during an active tour
  Future<void> startLocationTracking(String userId, String tourInstanceId);
  
  /// Stop tracking user location
  Future<void> stopLocationTracking(String userId);
  
  /// Update user's current location
  Future<void> updateLocation({
    required String userId,
    required String tourInstanceId,
    required double latitude,
    required double longitude,
    required double accuracy,
  });
  
  /// Get current location for a user in a specific tour
  Future<UserLocation?> getCurrentLocation(String userId, String tourInstanceId);
  
  /// Stream of location updates for a user
  Stream<UserLocation?> watchUserLocation(String userId, String tourInstanceId);
  
  /// Get all active user locations for a tour instance
  Stream<List<UserLocation>> watchTourParticipantLocations(String tourInstanceId);
  
  /// Clean up inactive location records
  Future<void> cleanupInactiveLocations();
}

class FirebaseUserLocationRepository implements UserLocationRepository {
  final FirebaseFirestore firestore;
  
  FirebaseUserLocationRepository({required this.firestore});

  @override
  Future<void> startLocationTracking(String userId, String tourInstanceId) async {
    await firestore
        .collection('user_locations')
        .doc('${userId}_$tourInstanceId')
        .set({
      'userId': userId,
      'tourInstanceId': tourInstanceId,
      'isTracking': true,
      'startedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> stopLocationTracking(String userId) async {
    // Update all tracking sessions for this user
    final querySnapshot = await firestore
        .collection('user_locations')
        .where('userId', isEqualTo: userId)
        .where('isTracking', isEqualTo: true)
        .get();
    
    final batch = firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {
        'isTracking': false,
        'stoppedAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> updateLocation({
    required String userId,
    required String tourInstanceId,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    final locationData = UserLocation(
      userId: userId,
      tourInstanceId: tourInstanceId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: DateTime.now(),
    );

    await firestore
        .collection('user_locations')
        .doc('${userId}_$tourInstanceId')
        .set(locationData.toMap(), SetOptions(merge: true));
  }

  @override
  Stream<UserLocation?> watchUserLocation(String userId, String tourInstanceId) {
    return firestore
        .collection('user_locations')
        .doc('${userId}_$tourInstanceId')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      
      final data = doc.data()!;
      if (data['isTracking'] != true) return null;
      
      return UserLocation.fromMap(data);
    });
  }

  @override
  Future<UserLocation?> getCurrentLocation(String userId, String tourInstanceId) async {
    final doc = await firestore
        .collection('user_locations')
        .doc('${userId}_$tourInstanceId')
        .get();
    
    if (!doc.exists || doc.data() == null) return null;
    
    return UserLocation.fromMap(doc.data()!);
  }

  @override
  Stream<List<UserLocation>> watchTourParticipantLocations(String tourInstanceId) {
    return firestore
        .collection('user_locations')
        .where('tourInstanceId', isEqualTo: tourInstanceId)
        .where('isTracking', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserLocation.fromMap(doc.data()!))
          .toList();
    });
  }

  @override
  Future<void> cleanupInactiveLocations() async {
    final threshold = DateTime.now().subtract(Duration(days: 7));
    
    final querySnapshot = await firestore
        .collection('user_locations')
        .where('isTracking', isEqualTo: false)
        .where('stoppedAt', isLessThan: Timestamp.fromDate(threshold))
        .get();
    
    final batch = firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}