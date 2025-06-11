import 'package:cloud_firestore/cloud_firestore.dart';

class TourInstance {
  final String id;
  final String tourPlanId;
  final String guideId;
  final Timestamp scheduledDate;
  final Timestamp startTime; // Specific start time for the tour
  final String status; // "scheduled", "waiting_start", "ongoing", "completed", "cancelled"
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  TourInstance({
    required this.id,
    required this.tourPlanId,
    required this.guideId,
    required this.scheduledDate,
    required this.startTime,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory TourInstance.fromMap(Map<String, dynamic> map, String documentId) {
    return TourInstance(
      id: documentId,
      tourPlanId: map['tourPlanId'] as String,
      guideId: map['guideId'] as String,
      scheduledDate: map['scheduledDate'] as Timestamp,
      startTime: map['startTime'] as Timestamp,
      status: map['status'] as String,
      createdAt: map['createdAt'] as Timestamp,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tourPlanId': tourPlanId,
      'guideId': guideId,
      'scheduledDate': scheduledDate,
      'startTime': startTime,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  TourInstance copyWith({
    String? id,
    String? tourPlanId,
    String? guideId,
    Timestamp? scheduledDate,
    Timestamp? startTime,
    String? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return TourInstance(
      id: id ?? this.id,
      tourPlanId: tourPlanId ?? this.tourPlanId,
      guideId: guideId ?? this.guideId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TourInstance(id: $id, tourPlanId: $tourPlanId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TourInstance && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}