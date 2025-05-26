import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tour_journal.dart';
import '../models/journal_entry.dart';
import '../core/exceptions/app_exceptions.dart';

class TourJournalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tour_journals';

  // Create tour journal
  Future<String> createTourJournal(TourJournal journal) async {
    try {
      final docRef = await _firestore.collection(_collection).add(journal.toMap());
      return docRef.id;
    } catch (e) {
      throw DatabaseException('Failed to create tour journal: ${e.toString()}');
    }
  }

  // Get journal by ID
  Future<TourJournal?> getTourJournalById(String journalId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(journalId).get();
      if (doc.exists && doc.data() != null) {
        return TourJournal.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get tour journal: ${e.toString()}');
    }
  }

  // Get journals for user
  Future<List<TourJournal>> getJournalsForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('startedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => TourJournal.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get user journals: ${e.toString()}');
    }
  }

  // Add journal entry
  Future<void> addJournalEntry(String journalId, JournalEntry entry) async {
    try {
      await _firestore.collection(_collection).doc(journalId).update({
        'entries': FieldValue.arrayUnion([entry.toMap()])
      });
    } catch (e) {
      throw DatabaseException('Failed to add journal entry: ${e.toString()}');
    }
  }

  // Complete tour journal
  Future<void> completeTourJournal(String journalId) async {
    try {
      await _firestore.collection(_collection).doc(journalId).update({
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      throw DatabaseException('Failed to complete tour journal: ${e.toString()}');
    }
  }
}