import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/tour_session.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TourSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Simple constructor without repository dependency  
  TourSessionService();

  Future<TourSession> createSession({
    required String bookingId,
    required String guideId,
    required String travelerId,
  }) async {
    // Get booking details to extract tour plan info
    final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw Exception('Booking not found');
    }
    
    final bookingData = bookingDoc.data()!;
    final tourPlanId = bookingData['tourPlanId'] as String;
    final startTime = bookingData['startTime'] as Timestamp;
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCreatorGuide = currentUserId == guideId;
    
    final sessionData = {
      'tourPlanId': tourPlanId,
      'guideId': guideId,
      'travelerIds': [travelerId],
      'startTime': startTime,
      'endTime': null,
      'status': 'scheduled',
      'currentLocationId': null,
      'currentPlaceIndex': 0,
      'sessionData': null,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'bookingId': bookingId,
      'tourInstanceId': bookingData['tourInstanceId'] as String?,
      'guideReady': true,
      'travelerReady': false,
      'visitedPlaces': <String>[],
      'guideLocation': null,
      'travelerLocation': null,
      'guideOnline': isCreatorGuide,
      'travelerOnline': false,
      'guideLastSeen': isCreatorGuide ? Timestamp.now() : null,
      'travelerLastSeen': null,
    };
    
    final docRef = await _firestore.collection('tourSessions').add(sessionData);
    print('Created session via createSession with creator online: ${isCreatorGuide ? "Guide" : "Traveler"}');
    return TourSession.fromMap(sessionData, docRef.id);
  }

  // Enhanced tour session creation with proper confirmation flow
  Future<TourSession> createTourSession({
    required String bookingId,
    required String tourPlanId,
    required String guideId,
    required String travelerId,
    required DateTime scheduledStartTime,
    bool waitForTravelerConfirmation = true,
  }) async {
    try {
      final sessionId = _firestore.collection('tourSessions').doc().id;
      
      final session = TourSession(
        id: sessionId,
        bookingId: bookingId,
        tourPlanId: tourPlanId,
        guideId: guideId,
        travelerId: travelerId,
        status: waitForTravelerConfirmation 
            ? TourSessionStatus.waitingForTraveler 
            : TourSessionStatus.scheduled,
        scheduledStartTime: Timestamp.fromDate(scheduledStartTime),
        currentPlaceIndex: 0,
        visitedPlaces: [],
        guideOnline: false,
        travelerOnline: false,
        guideReady: false,
        travelerReady: false,
        canRejoin: true, // Enable exit/rejoin functionality
        lastHeartbeat: {
          guideId: Timestamp.now(),
          travelerId: Timestamp.now(),
        },
        metadata: {
      'createdAt': Timestamp.now(),
          'createdBy': _auth.currentUser?.uid ?? '',
          'version': '2.0', // Enhanced version
        },
      );

      await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .set(session.toMap());

      return session;
    } catch (e) {
      print('Error creating tour session: $e');
      throw Exception('Failed to create tour session: $e');
    }
  }

  Future<TourSession?> getSessionByTourInstance(String tourInstanceId) async {
    final querySnapshot = await _firestore
        .collection('tourSessions')
        .where('tourInstanceId', isEqualTo: tourInstanceId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) return null;
    return TourSession.fromMap(querySnapshot.docs.first.data(), querySnapshot.docs.first.id);
  }

  Future<TourSession?> getSessionByBookingId(String bookingId) async {
    final querySnapshot = await _firestore
        .collection('tourSessions')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) return null;
    return TourSession.fromMap(querySnapshot.docs.first.data(), querySnapshot.docs.first.id);
  }

  Future<void> startSession(String sessionId) async {
    await _firestore.collection('tourSessions').doc(sessionId).update({
      'status': 'active',
      'updatedAt': Timestamp.now(),
    });
  }

  // Enhanced guide start tour with proper confirmation flow
  Future<void> startTourAsGuide(String sessionId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('tourSessions').doc(sessionId).update({
        'guideReady': true,
        'guideOnline': true,
        'status': 'waitingForTraveler', // Guide ready, waiting for traveler
        'lastHeartbeat.$currentUserId': Timestamp.now(),
        'metadata.guideStartedAt': Timestamp.now(),
      });
      
    } catch (e) {
      print('Error starting tour as guide: $e');
      throw Exception('Failed to start tour as guide: $e');
    }
  }

  // Enhanced traveler confirmation with proper flow
  Future<void> confirmTravelerReady(String sessionId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get current session to verify guide is ready
      final sessionDoc = await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .get();
      
      if (!sessionDoc.exists) {
        throw Exception('Tour session not found');
      }

      final sessionData = sessionDoc.data()!;
      final guideReady = sessionData['guideReady'] ?? false;

      if (!guideReady) {
        throw Exception('Guide has not started the tour yet');
    }
    
      // Mark traveler as ready and start the tour
      await _firestore.collection('tourSessions').doc(sessionId).update({
        'travelerReady': true,
        'travelerOnline': true,
        'status': 'active', // Both are ready, start the tour
        'actualStartTime': Timestamp.now(),
        'lastHeartbeat.$currentUserId': Timestamp.now(),
        'metadata.travelerConfirmedAt': Timestamp.now(),
      });
      
    } catch (e) {
      print('Error confirming traveler ready: $e');
      throw Exception('Failed to confirm traveler ready: $e');
    }
  }

  // Enhanced rejoin functionality
  Future<TourSession?> rejoinTourSession(String sessionId, bool isGuide) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final sessionDoc = await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .get();
      
      if (!sessionDoc.exists) {
        throw Exception('Tour session not found');
      }

      final session = TourSession.fromMap(sessionDoc.data()!);
      
      // Verify user can rejoin
      if (!session.canRejoin) {
        throw Exception('Rejoining is not allowed for this session');
      }

      // Verify user is part of this session
      if (isGuide && session.guideId != currentUserId) {
        throw Exception('You are not the guide for this session');
      }
      if (!isGuide && session.travelerId != currentUserId) {
        throw Exception('You are not the traveler for this session');
      }

      // Mark user as online
      await markUserOnline(sessionId, isGuide);

      return session;
    } catch (e) {
      print('Error rejoining tour session: $e');
      throw Exception('Failed to rejoin tour session: $e');
    }
  }

  // Enhanced online/offline status management
  Future<void> markUserOnline(String sessionId, bool isGuide) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final updateData = <String, dynamic>{
        'lastHeartbeat.$currentUserId': Timestamp.now(),
      };

      if (isGuide) {
        updateData['guideOnline'] = true;
        updateData['metadata.guideLastOnline'] = Timestamp.now();
      } else {
        updateData['travelerOnline'] = true;
        updateData['metadata.travelerLastOnline'] = Timestamp.now();
      }

      await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .update(updateData);
    } catch (e) {
      print('Error marking user online: $e');
    }
  }

  Future<void> markUserOffline(String sessionId, bool isGuide) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final updateData = <String, dynamic>{
        'lastHeartbeat.$currentUserId': Timestamp.now(),
      };

      if (isGuide) {
        updateData['guideOnline'] = false;
        updateData['metadata.guideLastOffline'] = Timestamp.now();
      } else {
        updateData['travelerOnline'] = false;
        updateData['metadata.travelerLastOffline'] = Timestamp.now();
      }

      await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .update(updateData);
    } catch (e) {
      print('Error marking user offline: $e');
    }
  }

  // Enhanced heartbeat system
  Future<void> sendHeartbeat(String sessionId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore
        .collection('tourSessions')
          .doc(sessionId)
          .update({
        'lastHeartbeat.$currentUserId': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending heartbeat: $e');
    }
  }

  // Enhanced location tracking
  Future<void> updateUserLocation(
    String sessionId,
    double latitude,
    double longitude,
    bool isGuide,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

    final locationData = {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.now(),
        'accuracy': 10.0, // Default accuracy
    };
    
      await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .update({
      isGuide ? 'guideLocation' : 'travelerLocation': locationData,
        'lastHeartbeat.$currentUserId': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  // Enhanced place management
  Future<void> markPlaceAsVisited(String sessionId, String placeId) async {
    try {
      final sessionDoc = await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .get();
      
      if (!sessionDoc.exists) {
        throw Exception('Tour session not found');
      }

      final session = TourSession.fromMap(sessionDoc.data()!);
      final visitedPlaces = List<String>.from(session.visitedPlaces);
      
      if (!visitedPlaces.contains(placeId)) {
        visitedPlaces.add(placeId);
        
        await _firestore
            .collection('tourSessions')
            .doc(sessionId)
            .update({
          'visitedPlaces': visitedPlaces,
          'metadata.lastPlaceVisited': placeId,
          'metadata.lastPlaceVisitedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error marking place as visited: $e');
      throw Exception('Failed to mark place as visited: $e');
    }
  }

  // Update current place index
  Future<void> updateCurrentPlace(String sessionId, int placeIndex) async {
    try {
      await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .update({
        'currentPlaceIndex': placeIndex,
        'metadata.currentPlaceUpdatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating current place: $e');
      throw Exception('Failed to update current place: $e');
    }
  }

  // Complete tour
  Future<void> completeTour(String sessionId) async {
    try {
      // Get the session to find the booking ID
      final sessionDoc = await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .get();
      
      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final bookingId = sessionData['bookingId'] as String?;
        
        // Update tour session status
        await _firestore
            .collection('tourSessions')
            .doc(sessionId)
            .update({
          'status': 'completed',
          'endTime': Timestamp.now(),
          'metadata.completedAt': Timestamp.now(),
        });
        
        // Update booking status to completed
        if (bookingId != null) {
          await _firestore
              .collection('bookings')
              .doc(bookingId)
              .update({
            'status': 'completed',
            'completedAt': Timestamp.now(),
    });
          print('Updated booking status to completed: $bookingId');
  }

        // Complete the associated tour journal
        try {
          final journalQuery = await _firestore
              .collection('tourJournals')
              .where('sessionId', isEqualTo: sessionId)
              .limit(1)
              .get();
          
          if (journalQuery.docs.isNotEmpty) {
            final journalDoc = journalQuery.docs.first;
            await _firestore
                .collection('tourJournals')
                .doc(journalDoc.id)
                .update({
              'isCompleted': true,
      'updatedAt': Timestamp.now(),
    });
            print('Completed tour journal: ${journalDoc.id}');
          }
        } catch (e) {
          print('Error completing tour journal: $e');
          // Don't fail the tour completion if journal update fails
        }
        
        print('Tour completed successfully: $sessionId');
      }
    } catch (e) {
      print('Error completing tour: $e');
      throw Exception('Failed to complete tour: $e');
    }
  }

  // Enhanced tour control
  Future<void> pauseTourSession(String sessionId) async {
    try {
      await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .update({
        'status': 'paused',
        'metadata.pausedAt': Timestamp.now(),
        'metadata.pausedBy': _auth.currentUser?.uid,
    });
    } catch (e) {
      print('Error pausing tour session: $e');
      throw Exception('Failed to pause tour session: $e');
    }
  }

  Future<void> resumeTourSession(String sessionId) async {
    try {
      await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .update({
        'status': 'active',
        'metadata.resumedAt': Timestamp.now(),
        'metadata.resumedBy': _auth.currentUser?.uid,
    });
    } catch (e) {
      print('Error resuming tour session: $e');
      throw Exception('Failed to resume tour session: $e');
    }
  }

  Future<void> completeTourSession(String sessionId) async {
    try {
      await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .update({
        'status': 'completed',
        'actualEndTime': Timestamp.now(),
        'metadata.completedAt': Timestamp.now(),
        'metadata.completedBy': _auth.currentUser?.uid,
    });
    } catch (e) {
      print('Error completing tour session: $e');
      throw Exception('Failed to complete tour session: $e');
    }
  }

  // Enhanced session retrieval
  Future<TourSession?> getTourSession(String sessionId) async {
    try {
      final doc = await _firestore
          .collection('tourSessions')
          .doc(sessionId)
          .get();
      
      if (doc.exists) {
        return TourSession.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting tour session: $e');
      return null;
    }
  }

  // Enhanced session listening with better error handling
  Stream<TourSession?> listenToTourSession(String sessionId) {
    return _firestore
        .collection('tourSessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        try {
          return TourSession.fromMap(doc.data()!);
        } catch (e) {
          print('Error parsing tour session: $e');
          return null;
        }
      }
      return null;
    }).handleError((error) {
      print('Error listening to tour session: $error');
      return null;
    });
  }

  // Get active sessions for a user (for rejoining)
  Future<List<TourSession>> getActiveSessionsForUser(String userId) async {
    try {
      // Get sessions where user is guide
      final guideQuery = await _firestore
          .collection('tourSessions')
          .where('guideId', isEqualTo: userId)
          .where('status', whereIn: ['active', 'paused', 'waitingForTraveler'])
          .get();

      // Get sessions where user is traveler
      final travelerQuery = await _firestore
        .collection('tourSessions')
          .where('travelerId', isEqualTo: userId)
          .where('status', whereIn: ['active', 'paused', 'waitingForTraveler'])
        .get();
    
      final sessions = <TourSession>[];
      
      for (final doc in guideQuery.docs) {
        sessions.add(TourSession.fromMap(doc.data()));
      }
      
      for (final doc in travelerQuery.docs) {
        final session = TourSession.fromMap(doc.data());
        // Avoid duplicates (shouldn't happen but just in case)
        if (!sessions.any((s) => s.id == session.id)) {
          sessions.add(session);
        }
      }

      return sessions;
    } catch (e) {
      print('Error getting active sessions: $e');
      return [];
  }
  }

  // Check if user can rejoin a session
  Future<bool> canRejoinSession(String sessionId, String userId) async {
    try {
      final session = await getTourSession(sessionId);
      if (session == null) return false;
      
      // Check if session allows rejoining
      if (!session.canRejoin) return false;
      
      // Check if session is in a rejoinable state
      if (!['active', 'paused'].contains(session.status.toString().split('.').last)) {
        return false;
  }

      // Check if user is part of this session
      return session.guideId == userId || session.travelerId == userId;
    } catch (e) {
      print('Error checking rejoin eligibility: $e');
      return false;
    }
  }

  // Cleanup inactive sessions (would be called periodically)
  Future<void> cleanupInactiveSessions() async {
    try {
      final cutoffTime = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 24)),
      );

      final query = await _firestore
          .collection('tourSessions')
          .where('status', whereIn: ['waitingForTraveler', 'scheduled'])
          .where('scheduledStartTime', isLessThan: cutoffTime)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'status': 'expired',
          'metadata.expiredAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error cleaning up inactive sessions: $e');
    }
  }

  // Enhanced error handling and validation
  Future<bool> validateSessionAccess(String sessionId, String userId) async {
    try {
      final session = await getTourSession(sessionId);
      if (session == null) return false;
      
      return session.guideId == userId || session.travelerId == userId;
    } catch (e) {
      print('Error validating session access: $e');
      return false;
    }
  }

  // Get session statistics
  Future<Map<String, dynamic>> getSessionStatistics(String sessionId) async {
    try {
      final session = await getTourSession(sessionId);
      if (session == null) return {};

      final stats = <String, dynamic>{
        'totalPlaces': 0,
        'visitedPlaces': session.visitedPlaces.length,
        'currentPlace': session.currentPlaceIndex + 1,
        'progress': 0.0,
        'duration': null,
        'status': session.status.toString().split('.').last,
      };

      // Calculate duration if tour has started
      if (session.actualStartTime != null) {
        final startTime = session.actualStartTime!.toDate();
        final endTime = session.actualEndTime?.toDate() ?? DateTime.now();
        stats['duration'] = endTime.difference(startTime).inMinutes;
      }

      return stats;
    } catch (e) {
      print('Error getting session statistics: $e');
      return {};
    }
  }
}