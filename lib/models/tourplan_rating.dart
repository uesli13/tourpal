import 'package:cloud_firestore/cloud_firestore.dart';

class TourplanRating {
  final String id;
  // final String creatorId;
  // final String tourPlanId;
  final DocumentReference creatorRef;
  final DocumentReference tourPlanRef;

  final double ratingScore;
  final String reviewText;

  TourplanRating({
    required this.id,
    // required this.creatorId,
    // required this.tourPlanId,
    required this.creatorRef,
    required this.tourPlanRef,

    required this.ratingScore,
    required this.reviewText,
  });

  factory TourplanRating.fromJson(String id, Map<String, dynamic> json) {
    return TourplanRating(
      id: id,
      // creatorId: (json['creatorid'] as String?) ?? '',
      // tourPlanId: json['tourplanid_str'] ?? '',
      creatorRef: json['creatorid'] as DocumentReference,
      tourPlanRef: json['tourplanid'] as DocumentReference,

      ratingScore: (json['ratingscore'] ?? 0).toDouble(),
      reviewText: json['reviewtext'] ?? '',
    );
  }

  String get creatorId => creatorRef.id;
  String get tourPlanId => tourPlanRef.id;

  Map<String, dynamic> toJson() {
    return {
      'creatorid': creatorRef,  
      'tourplanid': tourPlanRef,
      'ratingscore': ratingScore,
      'reviewtext': reviewText,
    };
  }
}
