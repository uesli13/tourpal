import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class JournalEntry extends Equatable {
  final String id;
  final String placeId;
  final String note;
  final List<String> photos;
  final GeoPoint location;
  final DateTime createdAt;

  const JournalEntry({
    required this.id,
    required this.placeId,
    required this.note,
    required this.photos,
    required this.location,
    required this.createdAt,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] ?? '',
      placeId: map['placeId'] ?? '',
      note: map['note'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      location: map['location'] ?? const GeoPoint(0, 0),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'placeId': placeId,
      'note': note,
      'photos': photos,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  JournalEntry copyWith({
    String? id,
    String? placeId,
    String? note,
    List<String>? photos,
    GeoPoint? location,
    DateTime? createdAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      note: note ?? this.note,
      photos: photos ?? this.photos,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object> get props => [
        id,
        placeId,
        note,
        photos,
        location,
        createdAt,
      ];
}