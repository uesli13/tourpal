import '../../../../models/tour_plan.dart';
import '../repositories/tour_repository.dart';

class CreateTourUsecase {
  final TourRepository _repository;
  
  CreateTourUsecase(this._repository);
  
  Future<TourPlan> call(TourPlan tour) async {
    return await _repository.createTour(tour);
  }
}