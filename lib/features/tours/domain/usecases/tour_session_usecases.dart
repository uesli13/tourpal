import '../../../../models/tour_session.dart';
import '../repositories/tour_session_repository.dart';

class StartTourSessionUseCase {
  final TourSessionRepository _repository;
  
  StartTourSessionUseCase(this._repository);

  Future<TourSession> execute({
    required String tourInstanceId,
    required String guideId,
    required String travelerId,
  }) async {
    return await _repository.createSession(
      tourInstanceId: tourInstanceId,
      guideId: guideId,
      travelerId: travelerId,
    );
  }
}

class GetActiveTourSessionsUseCase {
  final TourSessionRepository _repository;
  
  GetActiveTourSessionsUseCase(this._repository);

  Future<List<TourSession>> execute(String userId) async {
    return await _repository.getActiveSessionsForUser(userId);
  }
}

class UpdateTourProgressUseCase {
  final TourSessionRepository _repository;
  
  UpdateTourProgressUseCase(this._repository);

  Future<void> execute(String sessionId, int currentPlaceIndex) async {
    await _repository.updateProgress(sessionId, currentPlaceIndex);
  }
}

class WatchTourSessionUseCase {
  final TourSessionRepository _repository;
  
  WatchTourSessionUseCase(this._repository);

  Stream<TourSession?> execute(String sessionId) {
    return _repository.watchSession(sessionId);
  }
}