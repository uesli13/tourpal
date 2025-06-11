import '../../../../models/tour_plan.dart';
import '../repositories/tour_repository.dart';

class GetToursUsecase {
  final TourRepository _repository;

  GetToursUsecase(this._repository);

  /// Get all published tours
  Future<List<TourPlan>> call() async {
    final allTours = await _repository.getAllTours();
    return allTours.where((tour) => tour.status == TourStatus.published).toList();
  }

  /// Get tours by guide ID
  Future<List<TourPlan>> getToursByGuideId(String guideId) async {
    return await _repository.getToursByGuideId(guideId);
  }

  /// Get tour by ID
  Future<TourPlan?> getTourById(String tourId) async {
    return await _repository.getTourById(tourId);
  }
}