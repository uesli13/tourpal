class TourplanRating {
  final String id;
  final String creatorId;
  final String tourPlanId;
  final int ratingScore;
  final String reviewText;

  TourplanRating({
    required this.id,
    required this.creatorId,
    required this.tourPlanId,
    required this.ratingScore,
    required this.reviewText,
  });

  factory TourplanRating.fromJson(String id, Map<String, dynamic> json) {
    return TourplanRating(
      id: id,
      creatorId: json['creatorid'] ?? '',
      tourPlanId: json['tourplanid_str'] ?? '',
      ratingScore: (json['ratingscore'] ?? 0).toInt(),
      reviewText: json['reviewtext'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creatorid': creatorId,
      'tourplanid_str': tourPlanId,
      'ratingscore': ratingScore,
      'reviewtext': reviewText,
    };
  }
}
