import 'package:cloud_firestore/cloud_firestore.dart';

import 'journal_entry.dart';

class TourJournal {
  final String id;
  final String sessionId;
  final String tourPlanId;
  final String guideId;
  final String travelerId;
  final List<JournalEntry> entries;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final Map<String, dynamic> metadata;

  // Additional properties for UI compatibility
  String get title => metadata['title'] as String? ?? 'Tour Journal';
  DateTime? get completedAt => isCompleted ? updatedAt : null;

  TourJournal({
    required this.id,
    required this.sessionId,
    required this.tourPlanId,
    required this.guideId,
    required this.travelerId,
    this.entries = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.metadata = const {},
  });

  factory TourJournal.fromMap(Map<String, dynamic> map, String id) {
    return TourJournal(
      id: id,
      sessionId: map['sessionId'] ?? '',
      tourPlanId: map['tourPlanId'] ?? '',
      guideId: map['guideId'] ?? '',
      travelerId: map['travelerId'] ?? '',
      entries: (map['entries'] as List<dynamic>?)
          ?.map((entry) => JournalEntry.fromMap(entry as Map<String, dynamic>, entry['id'] ?? ''))
          .toList() ?? [],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isCompleted: map['isCompleted'] ?? false,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'tourPlanId': tourPlanId,
      'guideId': guideId,
      'travelerId': travelerId,
      'entries': entries.map((entry) => entry.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isCompleted': isCompleted,
      'metadata': metadata,
    };
  }

  TourJournal copyWith({
    String? sessionId,
    String? tourPlanId,
    String? guideId,
    String? travelerId,
    List<JournalEntry>? entries,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    Map<String, dynamic>? metadata,
  }) {
    return TourJournal(
      id: id,
      sessionId: sessionId ?? this.sessionId,
      tourPlanId: tourPlanId ?? this.tourPlanId,
      guideId: guideId ?? this.guideId,
      travelerId: travelerId ?? this.travelerId,
      entries: entries ?? this.entries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      metadata: metadata ?? this.metadata,
    );
  }
}