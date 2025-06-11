import '../../../../models/tour_session.dart';

abstract class TourSessionState {}

class TourSessionInitial extends TourSessionState {}

class TourSessionLoading extends TourSessionState {}

class TourSessionWaitingConfirmation extends TourSessionState {
  final TourSession session;
  
  TourSessionWaitingConfirmation(this.session);
}

class TourSessionConfirmed extends TourSessionState {
  final TourSession session;
  
  TourSessionConfirmed(this.session);
}

class TourSessionActive extends TourSessionState {
  final TourSession session;
  
  TourSessionActive(this.session);
}

class TourSessionError extends TourSessionState {
  final String message;
  
  TourSessionError(this.message);
} 