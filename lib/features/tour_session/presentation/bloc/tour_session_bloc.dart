import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../tours/services/tour_session_service.dart';
import 'tour_session_event.dart';
import 'tour_session_state.dart';

class TourSessionBloc extends Bloc<TourSessionEvent, TourSessionState> {
  final TourSessionService tourSessionService;

  TourSessionBloc({required this.tourSessionService}) : super(TourSessionInitial()) {
    on<CheckActiveTourSessionEvent>(_onCheckActiveTourSession);
    on<DeclineTourSessionEvent>(_onDeclineTourSession);
    on<ConfirmTravelerReadyEvent>(_onConfirmTravelerReady);
  }

  Future<void> _onCheckActiveTourSession(
    CheckActiveTourSessionEvent event,
    Emitter<TourSessionState> emit,
  ) async {
    emit(TourSessionLoading());
    try {
      // Check for active tour session for the user
      // For now, emit initial state as we don't have active sessions
      emit(TourSessionInitial());
    } catch (e) {
      emit(TourSessionError(e.toString()));
    }
  }

  Future<void> _onDeclineTourSession(
    DeclineTourSessionEvent event,
    Emitter<TourSessionState> emit,
  ) async {
    try {
      // Handle declining tour session
      emit(TourSessionInitial());
    } catch (e) {
      emit(TourSessionError(e.toString()));
    }
  }

  Future<void> _onConfirmTravelerReady(
    ConfirmTravelerReadyEvent event,
    Emitter<TourSessionState> emit,
  ) async {
    try {
      // Handle confirming traveler ready
      emit(TourSessionInitial());
    } catch (e) {
      emit(TourSessionError(e.toString()));
    }
  }
} 