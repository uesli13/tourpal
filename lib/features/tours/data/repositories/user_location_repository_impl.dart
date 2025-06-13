import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/user_location_repository.dart';

class UserLocationRepositoryImpl implements UserLocationRepository {
  final FirebaseFirestore _firestore;

  UserLocationRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> startLocationTracking(String userId, String tourInstanceId) async {
    await _firestore.collection('userLocations').doc('${userId}_$tourInstanceId').update({
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> stopLocationTracking(String userId) async {
    final querySnapshot = await _firestore
        .collection('userLocations')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
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
    final locationData = {
      'userId': userId,
      'tourInstanceId': tourInstanceId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': FieldValue.serverTimestamp(),
      'isActive': true,
    };

    await _firestore
        .collection('userLocations')
        .doc('${userId}_$tourInstanceId')
        .set(locationData, SetOptions(merge: true));
  }

  @override
  Future<UserLocation?> getCurrentLocation(String userId, String tourInstanceId) async {
    final doc = await _firestore
        .collection('userLocations')
        .doc('${userId}_$tourInstanceId')
        .get();

    if (doc.exists && doc.data() != null) {
      return UserLocation.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Stream<UserLocation?> watchUserLocation(String userId, String tourInstanceId) {
    return _firestore
        .collection('userLocations')
        .doc('${userId}_$tourInstanceId')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserLocation.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  @override
  Stream<List<UserLocation>> watchTourParticipantLocations(String tourInstanceId) {
    return _firestore
        .collection('userLocations')
        .where('tourInstanceId', isEqualTo: tourInstanceId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserLocation.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<void> cleanupInactiveLocations() async {
    final oneHourAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 1)),
    );

    final querySnapshot = await _firestore
        .collection('userLocations')
        .where('timestamp', isLessThan: oneHourAgo)
        .where('isActive', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    await batch.commit();
  }
}