import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourpal/models/tourplan_rating.dart';

class TourplanRatingRepository {
  final _db = FirebaseFirestore.instance;

  Future<double> getAverageRating(String tourPlanId) async {
    final snapshot = await _db
        .collection('tourplanrating')
        // .where('tourplanid_str', isEqualTo: 'tourplan/$tourPlanId')
        .where('tourplanid', isEqualTo: _db.doc('tourplan/$tourPlanId'))
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

  Future<List<TourplanRating>> fetchRatingsForTourplan(String tourPlanId) async {
    final snap = await _db
      .collection('tourplanrating')
      .where('tourplanid', isEqualTo: _db.doc('tourplan/$tourPlanId'))
      .get();
    return snap.docs
        .map((doc) => TourplanRating.fromJson(doc.id, doc.data()))
        .toList();
  }
}
