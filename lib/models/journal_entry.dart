import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String placeId;
  final String type; // 'check_in', 'note', 'photo'
  final String content;
  final List<String> imageUrls;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  JournalEntry({
    required this.id,
    required this.placeId,
    required this.type,
    required this.content,
    this.imageUrls = const [],
    required this.timestamp,
    this.metadata = const {},
  });

  // Add compatibility getters for existing code
  String get note => content;
  List<String> get photos => imageUrls;

  factory JournalEntry.fromMap(Map<String, dynamic> map, String id) {
    return JournalEntry(
      id: id,
      placeId: map['placeId'] ?? '',
      type: map['type'] ?? 'note',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : map['timestamp'] is DateTime
          ? map['timestamp']
          : DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'type': type,
      'content': content,
      'imageUrls': imageUrls,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}

// Create an alias for compatibility with TourJournal
typedef IndividualJournalEntry = JournalEntry;