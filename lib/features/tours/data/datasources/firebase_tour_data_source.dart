import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/tour_plan.dart';
import 'tour_data_source.dart';

class FirebaseTourDataSource implements TourDataSource {
  final FirebaseFirestore _firestore;
  
  FirebaseTourDataSource(this._firestore);
  
  @override
  Future<List<TourPlan>> getAllTours() async {
    final snapshot = await _firestore
        .collection('tourPlans')
        .where('status', isEqualTo: 'published')
        .get();
        
    return snapshot.docs
        .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
        .toList();
  }
  
  @override
  Future<TourPlan?> getTourById(String id) async {
    final doc = await _firestore.collection('tourPlans').doc(id).get();
    
    if (!doc.exists) return null;
    
    return TourPlan.fromMap(doc.data()!, doc.id);
  }
  
  @override
  Future<TourPlan> createTour(TourPlan tour) async {
    final docRef = await _firestore.collection('tourPlans').add(tour.toMap());
    
    final createdDoc = await docRef.get();
    return TourPlan.fromMap(createdDoc.data()!, createdDoc.id);
  }
  
  @override
  Future<TourPlan> updateTour(TourPlan tour) async {
    await _firestore.collection('tourPlans').doc(tour.id).update(tour.toMap());
    
    final updatedDoc = await _firestore.collection('tourPlans').doc(tour.id).get();
    return TourPlan.fromMap(updatedDoc.data()!, updatedDoc.id);
  }
  
  @override
  Future<void> deleteTour(String id) async {
    await _firestore.collection('tourPlans').doc(id).delete();
  }
  
  @override
  Future<List<TourPlan>> getToursByGuideId(String guideId) async {
    final snapshot = await _firestore
        .collection('tourPlans')
        .where('guideId', isEqualTo: guideId)
        .get();
        
    return snapshot.docs
        .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
        .toList();
  }
  
  @override
  Future<List<TourPlan>> searchTours(String query) async {
    final snapshot = await _firestore
        .collection('tourPlans')
        .where('status', isEqualTo: 'published')
        .get();
        
    final tours = snapshot.docs
        .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
        .where((tour) => 
            tour.title.toLowerCase().contains(query.toLowerCase()) ||
            (tour.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();
        
    return tours;
  }
}