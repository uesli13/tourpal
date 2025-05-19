import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourpal/models/destination.dart';
import '../models/tourplan.dart';

class TourPlanRepository {
  final _db = FirebaseFirestore.instance;
  final String _collection = 'tourplan';

  Future<List<TourPlan>> fetchAllTourPlans() async {
    final snapshot = await _db.collection(_collection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return TourPlan.fromJson(data);
    }).toList();
  }

  Future<int> getDestinationCount(String tourPlanId) async {
    final snap = await _db
        .collection(_collection)
        .doc(tourPlanId)
        .collection('destination')
        .get();
    return snap.docs.length;
  }

    Future<List<Destination>> fetchDestinations(String tourPlanId) async {
    final snap = await _db
      .collection(_collection)
      .doc(tourPlanId)
      .collection('destination')
      .orderBy('order') 
      .get();

    return snap.docs.map((doc) {
      final data = doc.data()..['id'] = doc.id;
      return Destination.fromJson(data);
    }).toList();
  }
}
