class RatingStatistics {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  const RatingStatistics({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory RatingStatistics.fromMap(Map<String, dynamic> map) {
    return RatingStatistics(
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: map['totalReviews'] as int? ?? 0,
      ratingDistribution: Map<int, int>.from(map['ratingDistribution'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
    };
  }

  RatingStatistics copyWith({
    double? averageRating,
    int? totalReviews,
    Map<int, int>? ratingDistribution,
  }) {
    return RatingStatistics(
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RatingStatistics &&
        other.averageRating == averageRating &&
        other.totalReviews == totalReviews &&
        _mapEquals(other.ratingDistribution, ratingDistribution);
  }

  @override
  int get hashCode {
    return averageRating.hashCode ^
        totalReviews.hashCode ^
        ratingDistribution.hashCode;
  }

  bool _mapEquals(Map<int, int> map1, Map<int, int> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'RatingStatistics(averageRating: $averageRating, totalReviews: $totalReviews, ratingDistribution: $ratingDistribution)';
  }
}