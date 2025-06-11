import '../../../../models/tour_plan.dart';
import '../datasources/tour_data_source.dart';
import '../../domain/repositories/tour_repository.dart';

class TourRepositoryImpl implements TourRepository {
  final TourDataSource _dataSource;

  TourRepositoryImpl(this._dataSource);

  @override
  Future<List<TourPlan>> getAllTours() async {
    try {
      return await _dataSource.getAllTours();
    } catch (e) {
      throw Exception('Failed to get tours: $e');
    }
  }

  @override
  Future<TourPlan?> getTourById(String id) async {
    try {
      return await _dataSource.getTourById(id);
    } catch (e) {
      throw Exception('Failed to get tour: $e');
    }
  }

  @override
  Future<TourPlan> createTour(TourPlan tour) async {
    try {
      return await _dataSource.createTour(tour);
    } catch (e) {
      throw Exception('Failed to create tour: $e');
    }
  }

  @override
  Future<TourPlan> updateTour(TourPlan tour) async {
    try {
      return await _dataSource.updateTour(tour);
    } catch (e) {
      throw Exception('Failed to update tour: $e');
    }
  }

  @override
  Future<void> deleteTour(String id) async {
    try {
      await _dataSource.deleteTour(id);
    } catch (e) {
      throw Exception('Failed to delete tour: $e');
    }
  }

  @override
  Future<List<TourPlan>> getToursByGuideId(String guideId) async {
    try {
      return await _dataSource.getToursByGuideId(guideId);
    } catch (e) {
      throw Exception('Failed to get guide tours: $e');
    }
  }

  @override
  Future<List<TourPlan>> searchTours(String query) async {
    try {
      return await _dataSource.searchTours(query);
    } catch (e) {
      throw Exception('Failed to search tours: $e');
    }
  }
}