abstract class TourSessionEvent {}

class CheckActiveTourSessionEvent extends TourSessionEvent {
  final String userId;
  
  CheckActiveTourSessionEvent(this.userId);
}

class DeclineTourSessionEvent extends TourSessionEvent {
  final String sessionId;
  
  DeclineTourSessionEvent(this.sessionId);
}

class ConfirmTravelerReadyEvent extends TourSessionEvent {
  final String sessionId;
  
  ConfirmTravelerReadyEvent(this.sessionId);
} 