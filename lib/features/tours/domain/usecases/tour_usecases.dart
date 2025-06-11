import '../../../../models/tour_plan.dart';
import '../repositories/tour_repository.dart';

class GetAllToursUseCase {
  final TourRepository _repository;

  GetAllToursUseCase(this._repository);

  Future<List<TourPlan>> call() async {
    return await _repository.getAllTours();
  }
}

class GetTourByIdUseCase {
  final TourRepository _repository;

  GetTourByIdUseCase(this._repository);

  Future<TourPlan?> call(String id) async {
    return await _repository.getTourById(id);
  }
}

class CreateTourUseCase {
  final TourRepository _repository;

  CreateTourUseCase(this._repository);

  Future<TourPlan> call(TourPlan tour) async {
    return await _repository.createTour(tour);
  }
}

class SearchToursUseCase {
  final TourRepository _repository;

  SearchToursUseCase(this._repository);

  Future<List<TourPlan>> call(String query) async {
    return await _repository.searchTours(query);
  }
}

class GetToursByGuideUseCase {
  final TourRepository _repository;

  GetToursByGuideUseCase(this._repository);

  Future<List<TourPlan>> call(String guideId) async {
    return await _repository.getToursByGuideId(guideId);
  }
}