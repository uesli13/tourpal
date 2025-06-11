import '../../../../models/tour_plan.dart';
import '../repositories/tour_repository.dart';

class UpdateTourUsecase {
  final TourRepository _repository;

  UpdateTourUsecase(this._repository);

  Future<TourPlan> call(TourPlan tour) async {
    return await _repository.updateTour(tour);
  }
}