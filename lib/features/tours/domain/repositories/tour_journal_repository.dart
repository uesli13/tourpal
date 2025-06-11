import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/tour_journal.dart';
import '../../../../models/journal_entry.dart';

abstract class TourJournalRepository {
  /// Create a new tour journal for a traveler
  Future<TourJournal> createTourJournal({
    required String sessionId,
    required String tourPlanId,
    required String guideId,
    required String travelerId,
  });
  
  /// Get tour journal by tour instance ID
  Future<TourJournal?> getTourJournal(String tourInstanceId);
  
  /// Get tour journal by journal ID
  Future<TourJournal?> getTourJournalById(String journalId);
  
  /// Get tour journal by booking ID (for completed tours)
  Future<TourJournal?> getTourJournalByBookingId(String bookingId);
  
  /// Get tour journal by tour plan ID (fallback method)
  Future<TourJournal?> getTourJournalByTourPlanId(String tourPlanId, String travelerId);
  
  /// Add an entry to the tour journal
  Future<void> addJournalEntry({
    required String journalId,
    required String placeId,
    required String type,
    required String content,
    required List<String> imageUrls,
  });
  
  /// Update an existing journal entry
  Future<void> updateJournalEntry({
    required String journalId,
    required String entryId,
    String? content,
    List<String>? imageUrls,
  });
  
  /// Delete a journal entry
  Future<void> deleteJournalEntry(String journalId, String entryId);
  
  /// Complete the tour journal
  Future<void> completeTourJournal(String journalId);
  
  /// Get all journal entries for a specific place
  Future<List<JournalEntry>> getEntriesForPlace(String journalId, String placeId);
  
  /// Stream of journal updates for real-time synchronization
  Stream<TourJournal?> watchJournal(String journalId);
}

class FirebaseTourJournalRepository implements TourJournalRepository {
  final FirebaseFirestore firestore;
  
  FirebaseTourJournalRepository({required this.firestore});

  @override
  Future<TourJournal> createTourJournal({
    required String sessionId,
    required String tourPlanId,
    required String guideId,
    required String travelerId,
  }) async {
    final now = DateTime.now();
    final journalData = {
      'sessionId': sessionId,
      'tourPlanId': tourPlanId,
      'guideId': guideId,
      'travelerId': travelerId,
      'entries': <Map<String, dynamic>>[],
      'createdAt': now,
      'updatedAt': now,
      'isCompleted': false,
      'metadata': <String, dynamic>{},
    };
    
    final docRef = await firestore.collection('tourJournals').add(journalData);
    return TourJournal.fromMap(journalData, docRef.id);
  }

  @override
  Future<TourJournal?> getTourJournal(String tourInstanceId) async {
    final querySnapshot = await firestore
        .collection('tourJournals')
        .where('sessionId', isEqualTo: tourInstanceId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) return null;
    
    final doc = querySnapshot.docs.first;
    return TourJournal.fromMap(doc.data(), doc.id);
  }

  @override
  Future<TourJournal?> getTourJournalById(String journalId) async {
    final doc = await firestore.collection('tourJournals').doc(journalId).get();
    
    if (!doc.exists) return null;
    
    return TourJournal.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<TourJournal?> getTourJournalByBookingId(String bookingId) async {
    try {
      // First, find the tour session associated with this booking
      final sessionQuery = await firestore
          .collection('tourSessions')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      
      if (sessionQuery.docs.isEmpty) {
        return null;
      }
      
      final sessionId = sessionQuery.docs.first.id;
      
      // Now find the journal by session ID
      return await getTourJournal(sessionId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<TourJournal?> getTourJournalByTourPlanId(String tourPlanId, String travelerId) async {
    try {
      final querySnapshot = await firestore
          .collection('tourJournals')
          .where('tourPlanId', isEqualTo: tourPlanId)
          .where('travelerId', isEqualTo: travelerId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      return TourJournal.fromMap(doc.data(), doc.id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addJournalEntry({
    required String journalId,
    required String placeId,
    required String type,
    required String content,
    required List<String> imageUrls,
  }) async {
    final entryData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'placeId': placeId,
      'type': type,
      'content': content,
      'imageUrls': imageUrls,
      'timestamp': DateTime.now(),
      'metadata': <String, dynamic>{},
    };
    
    await firestore.collection('tourJournals').doc(journalId).update({
      'entries': FieldValue.arrayUnion([entryData]),
      'updatedAt': DateTime.now(),
    });
  }

  @override
  Future<void> completeTourJournal(String journalId) async {
    await firestore.collection('tourJournals').doc(journalId).update({
      'isCompleted': true,
      'updatedAt': DateTime.now(),
    });
  }

  @override
  Future<List<JournalEntry>> getEntriesForPlace(String journalId, String placeId) async {
    final doc = await firestore.collection('tourJournals').doc(journalId).get();
    if (!doc.exists) return [];
    
    final journal = TourJournal.fromMap(doc.data()!, doc.id);
    return journal.entries.where((entry) => entry.placeId == placeId).toList();
  }

  @override
  Future<void> updateJournalEntry({
    required String journalId,
    required String entryId,
    String? content,
    List<String>? imageUrls,
  }) async {
    // Implementation would involve updating specific entry in the array
    // For simplicity, this is a placeholder
    await firestore.collection('tourJournals').doc(journalId).update({
      'updatedAt': DateTime.now(),
    });
  }

  @override
  Future<void> deleteJournalEntry(String journalId, String entryId) async {
    // Implementation would involve removing specific entry from the array
    // For simplicity, this is a placeholder
    await firestore.collection('tourJournals').doc(journalId).update({
      'updatedAt': DateTime.now(),
    });
  }

  @override
  Stream<TourJournal?> watchJournal(String journalId) {
    return firestore
        .collection('tourJournals')
        .doc(journalId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return TourJournal.fromMap(doc.data()!, doc.id);
    });
  }
}