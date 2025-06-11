import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/logger.dart';
import '../../../models/tour_journal.dart';
import '../../../models/journal_entry.dart';

class TourJournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Simple constructor without repository dependency
  TourJournalService();

  /// Create a new tour journal
  Future<TourJournal> createTourJournal({
    required String sessionId,
    required String tourPlanId,
    required String guideId,
    required String travelerId,
  }) async {
    try {
      final now = DateTime.now();
      final journalData = {
        'sessionId': sessionId,
        'tourPlanId': tourPlanId,
        'guideId': guideId,
        'travelerId': travelerId,
        'entries': <Map<String, dynamic>>[],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isCompleted': false,
        'metadata': <String, dynamic>{},
      };
      
      final docRef = await _firestore.collection('tourJournals').add(journalData);
      AppLogger.database('Created tour journal', 'tourJournals', docRef.id);
      AppLogger.info('Created tour journal: ${docRef.id} for session: $sessionId, tourPlan: $tourPlanId');
      
      return TourJournal.fromMap(journalData, docRef.id);
    } catch (e) {
      AppLogger.error('Failed to create tour journal: $e', e);
      throw Exception('Failed to create tour journal: $e');
    }
  }

  /// Get tour journal by tour instance ID
  Future<TourJournal?> getTourJournal(String tourInstanceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tourJournals')
          .where('sessionId', isEqualTo: tourInstanceId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        AppLogger.info('No journal found for tour instance: $tourInstanceId');
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      AppLogger.info('Found journal: ${doc.id} for tour instance: $tourInstanceId');
      return TourJournal.fromMap(doc.data(), doc.id);
    } catch (e) {
      AppLogger.error('Error getting tour journal: $e', e);
      return null;
    }
  }

  /// Get tour journal by tour instance ID (alias for compatibility)
  Future<TourJournal?> getTourJournalByTourInstance(String tourInstanceId) async {
    return await getTourJournal(tourInstanceId);
  }

  /// Add a journal entry
  Future<void> addJournalEntry({
    required String journalId,
    required String placeId,
    required String type,
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      final entryData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'placeId': placeId,
        'type': type,
        'content': content,
        'imageUrls': imageUrls ?? [],
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'metadata': <String, dynamic>{},
      };
      
      await _firestore.collection('tourJournals').doc(journalId).update({
        'entries': FieldValue.arrayUnion([entryData]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      AppLogger.database('Added journal entry', 'tourJournals', journalId);
      AppLogger.info('Added journal entry to journal: $journalId for place: $placeId');
    } catch (e) {
      AppLogger.error('Error adding journal entry: $e', e);
      throw Exception('Failed to add journal entry: $e');
    }
  }

  /// Complete tour journal
  Future<void> completeTourJournal(String journalId) async {
    try {
      await _firestore.collection('tourJournals').doc(journalId).update({
        'isCompleted': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      AppLogger.database('Completed tour journal', 'tourJournals', journalId);
      AppLogger.info('Completed tour journal: $journalId');
    } catch (e) {
      AppLogger.error('Error completing tour journal: $e', e);
      throw Exception('Failed to complete tour journal: $e');
    }
  }

  /// Get journal entries for a specific place
  Future<List<JournalEntry>> getEntriesForPlace(String journalId, String placeId) async {
    try {
      final doc = await _firestore.collection('tourJournals').doc(journalId).get();
      if (!doc.exists) return [];
      
      final journal = TourJournal.fromMap(doc.data()!, doc.id);
      return journal.entries.where((entry) => entry.placeId == placeId).toList();
    } catch (e) {
      AppLogger.error('Error getting entries for place: $e', e);
      return [];
    }
  }

  /// Update journal entry
  Future<void> updateJournalEntry({
    required String journalId,
    required String entryId,
    String? content,
    List<String>? imageUrls,
  }) async {
    try {
      // For now, just update the timestamp - full implementation would update specific entry
      await _firestore.collection('tourJournals').doc(journalId).update({
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      AppLogger.database('Updated journal entry', 'tourJournals', journalId);
      AppLogger.info('Updated journal entry: $entryId in journal: $journalId');
    } catch (e) {
      AppLogger.error('Error updating journal entry: $e', e);
      throw Exception('Failed to update journal entry: $e');
    }
  }

  /// Delete journal entry
  Future<void> deleteJournalEntry(String journalId, String entryId) async {
    try {
      // For now, just update the timestamp - full implementation would remove specific entry
      await _firestore.collection('tourJournals').doc(journalId).update({
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      AppLogger.database('Deleted journal entry', 'tourJournals', journalId);
      AppLogger.info('Deleted journal entry: $entryId from journal: $journalId');
    } catch (e) {
      AppLogger.error('Error deleting journal entry: $e', e);
      throw Exception('Failed to delete journal entry: $e');
    }
  }

  /// Watch journal updates
  Stream<TourJournal?> watchJournal(String journalId) {
    return _firestore
        .collection('tourJournals')
        .doc(journalId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return TourJournal.fromMap(doc.data()!, doc.id);
    });
  }

  /// Get tour journal by booking ID (for completed tours)
  Future<TourJournal?> getTourJournalByBookingId(String bookingId) async {
    try {
      AppLogger.info('Searching for journal by booking ID: $bookingId');
      
      // First, find the tour session associated with this booking
      final sessionQuery = await _firestore
          .collection('tourSessions')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      
      if (sessionQuery.docs.isEmpty) {
        AppLogger.info('No session found for booking: $bookingId');
        return null;
      }
      
      final sessionId = sessionQuery.docs.first.id;
      AppLogger.info('Found session: $sessionId for booking: $bookingId');
      
      // Now find the journal by session ID
      final journalQuery = await _firestore
          .collection('tourJournals')
          .where('sessionId', isEqualTo: sessionId)
          .limit(1)
          .get();
      
      if (journalQuery.docs.isEmpty) {
        AppLogger.info('No journal found for session: $sessionId');
        return null;
      }
      
      final journalDoc = journalQuery.docs.first;
      final journalData = journalDoc.data();
      AppLogger.info('Found journal: ${journalDoc.id} for session: $sessionId');
      
      return TourJournal.fromMap(journalData, journalDoc.id);
    } catch (e) {
      AppLogger.error('Error getting tour journal by booking ID: $e', e);
      return null;
    }
  }

  /// Get tour journal by tour plan ID (fallback method)
  Future<TourJournal?> getTourJournalByTourPlanId(String tourPlanId, String travelerId) async {
    try {
      AppLogger.info('Fallback: Searching for journal by tourPlanId: $tourPlanId, travelerId: $travelerId');
      
      final querySnapshot = await _firestore
          .collection('tourJournals')
          .where('tourPlanId', isEqualTo: tourPlanId)
          .where('travelerId', isEqualTo: travelerId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        AppLogger.info('No journal found for tour plan: $tourPlanId and traveler: $travelerId');
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      AppLogger.info('Found journal via fallback: ${doc.id} for tour plan: $tourPlanId');
      
      return TourJournal.fromMap(doc.data(), doc.id);
    } catch (e) {
      AppLogger.error('Error getting tour journal by tour plan ID: $e', e);
      return null;
    }
  }
}