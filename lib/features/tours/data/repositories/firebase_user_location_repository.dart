import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/user_location_repository.dart';

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
    await firestore
        .collection('user_locations')
        .doc('${userId}_$tourInstanceId')
        .set({
      'userId': userId,
      'tourInstanceId': tourInstanceId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': Timestamp.now(),
      'isTracking': true,
    }, SetOptions(merge: true));
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
          .map((doc) => UserLocation.fromMap(doc.data()))
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