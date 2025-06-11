import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/tour_session.dart';
import '../../domain/repositories/tour_session_repository.dart';

class FirebaseTourSessionRepository implements TourSessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Future<TourSession> createSession({
    required String tourInstanceId,
    required String guideId,
    required String travelerId,
  }) async {
    final now = Timestamp.now();
    final sessionData = {
      'bookingId': tourInstanceId,
      'tourPlanId': '',
      'guideId': guideId,
      'travelerId': travelerId,
      'status': 'waiting',
      'currentPlaceIndex': 0,
      'guideReady': false,
      'travelerReady': false,
      'startTime': now,
      'createdAt': now,
      'visitedPlaces': <String>[],
    };
    
    final docRef = await _firestore.collection('tour_sessions').add(sessionData);
    return TourSession.fromMap(sessionData, docRef.id);
  }

  @override
  Future<TourSession?> getSessionByTourInstance(String tourInstanceId) async {
    final querySnapshot = await _firestore
        .collection('tour_sessions')
        .where('bookingId', isEqualTo: tourInstanceId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) return null;
    return TourSession.fromMap(querySnapshot.docs.first.data(), querySnapshot.docs.first.id);
  }

  @override
  Future<TourSession?> getSessionByBookingId(String bookingId) async {
    return await getSessionByTourInstance(bookingId);
  }

  @override
  Future<void> updateReadyStatus(String sessionId, bool isGuide, bool isReady) async {
    final field = isGuide ? 'guideReady' : 'travelerReady';
    await _firestore.collection('tour_sessions').doc(sessionId).update({field: isReady});
  }

  @override
  Future<void> startTour(String sessionId) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'status': 'active',
      'actualStartTime': Timestamp.now(),
    });
  }

  @override
  Future<void> confirmSession(String sessionId) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({'status': 'confirmed'});
  }

  @override
  Future<void> updateMeetingPoint(String sessionId, String meetingPoint) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({'meetingPoint': meetingPoint});
  }

  @override
  Future<void> updateSpecialInstructions(String sessionId, String instructions) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({'specialInstructions': instructions});
  }

  @override
  Future<void> updateTourProgress(String sessionId, int currentPlaceIndex, List<String> visitedPlaces) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'currentPlaceIndex': currentPlaceIndex,
      'visitedPlaces': visitedPlaces,
    });
  }

  @override
  Future<void> markPlaceVisited(String sessionId, String placeId) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'visitedPlaces': FieldValue.arrayUnion([placeId]),
    });
  }

  @override
  Future<void> pauseTour(String sessionId) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({'status': 'paused'});
  }

  @override
  Future<void> resumeTour(String sessionId) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({'status': 'active'});
  }

  @override
  Future<void> cancelTour(String sessionId) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'status': 'cancelled',
      'endTime': Timestamp.now(),
    });
  }

  @override
  Future<void> completeTour(String sessionId) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'status': 'completed',
      'endTime': Timestamp.now(),
    });
  }

  @override
  Stream<TourSession?> watchSession(String sessionId) {
    return _firestore.collection('tour_sessions').doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TourSession.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<List<TourSession>> getActiveSessionsForUser(String userId) async {
    final guideQuery = await _firestore
        .collection('tour_sessions')
        .where('guideId', isEqualTo: userId)
        .where('status', whereIn: ['waiting', 'active', 'paused']).get();
    
    final travelerQuery = await _firestore
        .collection('tour_sessions')
        .where('travelerId', isEqualTo: userId)
        .where('status', whereIn: ['waiting', 'active', 'paused']).get();
    
    final sessions = <TourSession>[];
    for (final doc in [...guideQuery.docs, ...travelerQuery.docs]) {
      sessions.add(TourSession.fromMap(doc.data(), doc.id));
    }
    return sessions;
  }

  @override
  Future<void> updateProgress(String sessionId, int currentPlaceIndex) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({'currentPlaceIndex': currentPlaceIndex});
  }

  @override
  Future<void> addTourNote(String sessionId, String note, String authorId) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'metadata.notes': FieldValue.arrayUnion([{
        'note': note,
        'authorId': authorId,
        'timestamp': Timestamp.now(),
      }]),
    });
  }

  @override
  Future<void> updateLocation(String sessionId, bool isGuide, double latitude, double longitude) async {
    final field = isGuide ? 'guideLocation' : 'travelerLocation';
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      field: {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': Timestamp.now(),
      },
    });
  }
}