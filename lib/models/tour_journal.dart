import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'journal_entry.dart';

class TourJournal extends Equatable {
  final String id;
  final String userId;
  final String tourPlanId;
  final List<JournalEntry> entries;
  final DateTime startedAt;
  final DateTime? completedAt;

  const TourJournal({
    required this.id,
    required this.userId,
    required this.tourPlanId,
    required this.entries,
    required this.startedAt,
    this.completedAt,
  });

  factory TourJournal.fromMap(Map<String, dynamic> map, String id) {
    return TourJournal(
      id: id,
      userId: map['userId'] ?? '',
      tourPlanId: map['tourPlanId'] ?? '',
      entries: (map['entries'] as List<dynamic>?)
              ?.map((entry) => JournalEntry.fromMap(entry))
              .toList() ??
          [],
      startedAt: (map['startedAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tourPlanId': tourPlanId,
      'entries': entries.map((entry) => entry.toMap()).toList(),
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  TourJournal copyWith({
    String? id,
    String? userId,
    String? tourPlanId,
    List<JournalEntry>? entries,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return TourJournal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tourPlanId: tourPlanId ?? this.tourPlanId,
      entries: entries ?? this.entries,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        tourPlanId,
        entries,
        startedAt,
        completedAt,
      ];
}