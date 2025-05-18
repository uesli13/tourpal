import 'package:cloud_firestore/cloud_firestore.dart';

class TourplanRatingRepository {
  final _db = FirebaseFirestore.instance;

  Future<double> getAverageRating(String tourPlanId) async {
    final snapshot = await _db
        .collection('tourplanrating')
        .where('tourplanid_str', isEqualTo: 'tourplan/$tourPlanId')
        .get();

    if (snapshot.docs.isEmpty) return 0.0;

    // Explicitly convert each ratingscore to int
    final totalScore = snapshot.docs.fold<int>(0, (sum, doc) {
      final data = doc.data();
      final scoreNum = data['ratingscore'] as num? ?? 0;
      return sum + scoreNum.toInt();
    });

    return totalScore / snapshot.docs.length;
  }
}
