import '../../../../models/tour_plan.dart';

abstract class TourRepository {
  Future<List<TourPlan>> getAllTours();
  Future<TourPlan?> getTourById(String id);
  Future<TourPlan> createTour(TourPlan tour);
  Future<TourPlan> updateTour(TourPlan tour);
  Future<void> deleteTour(String id);
  Future<List<TourPlan>> getToursByGuideId(String guideId);
  Future<List<TourPlan>> searchTours(String query);
}