import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourpal/core/utils/logger.dart';
import 'package:tourpal/core/exceptions/app_exceptions.dart';
import 'package:tourpal/features/guide/presentation/bloc/guide_event.dart';
import 'package:tourpal/features/guide/presentation/bloc/guide_state.dart';
import 'package:tourpal/repositories/guide_repository.dart';

// BLoC
class GuideBloc extends Bloc<GuideEvent, GuideState> {
  final GuideRepository _guideRepository;

  GuideBloc({required GuideRepository guideRepository})
      : _guideRepository = guideRepository,
        super(const GuideInitial()) {
    on<LoadGuide>(_onLoadGuide);
    on<CreateGuideProfile>(_onCreateGuideProfile);
    on<UpdateGuideProfile>(_onUpdateGuideProfile);
    on<ToggleAvailability>(_onToggleAvailability);
    on<LoadAvailableGuides>(_onLoadAvailableGuides);
  }

  Future<void> _onLoadGuide(LoadGuide event, Emitter<GuideState> emit) async {
    try {
      emit(const GuideLoading());
      AppLogger.info('Loading guide profile for user: ${event.userId}');
      
      final guide = await _guideRepository.getGuideByUserId(event.userId);
      if (guide != null) {
        emit(GuideLoaded(guide));
        AppLogger.info('Guide profile loaded successfully');
      } else {
        emit(const GuideError('Guide profile not found'));
        AppLogger.warning('Guide profile not found: ${event.userId}');
      }
    } on GuideException catch (e) {
      emit(GuideError(e.message));
      AppLogger.error('Failed to load guide profile: ${e.message}');
    } catch (e) {
      emit(const GuideError('An unexpected error occurred'));
      AppLogger.error('Unexpected error loading guide profile: $e');
    }
  }

  Future<void> _onCreateGuideProfile(CreateGuideProfile event, Emitter<GuideState> emit) async {
    try {
      emit(const GuideLoading());
      AppLogger.info('Creating guide profile for user: ${event.guide.userId}');
      
      await _guideRepository.createGuide(event.guide);
      emit(GuideLoaded(event.guide));
      AppLogger.info('Guide profile created successfully');
    } on GuideException catch (e) {
      emit(GuideError(e.message));
      AppLogger.error('Failed to create guide profile: ${e.message}');
    } catch (e) {
      emit(const GuideError('Failed to create guide profile'));
      AppLogger.error('Unexpected error creating guide profile: $e');
    }
  }

  Future<void> _onUpdateGuideProfile(UpdateGuideProfile event, Emitter<GuideState> emit) async {
    try {
      emit(const GuideLoading());
      AppLogger.info('Updating guide profile for user: ${event.guide.userId}');
      
      await _guideRepository.updateGuide(event.guide);
      emit(GuideLoaded(event.guide));
      AppLogger.info('Guide profile updated successfully');
    } on GuideException catch (e) {
      emit(GuideError(e.message));
      AppLogger.error('Failed to update guide profile: ${e.message}');
    } catch (e) {
      emit(const GuideError('Failed to update guide profile'));
      AppLogger.error('Unexpected error updating guide profile: $e');
    }
  }

  Future<void> _onToggleAvailability(ToggleAvailability event, Emitter<GuideState> emit) async {
    try {
      AppLogger.info('Toggling availability for guide: ${event.userId}');
      
      await _guideRepository.updateAvailability(event.userId, event.isAvailable);
      
      // Reload guide to get updated data
      add(LoadGuide(event.userId));
      AppLogger.info('Guide availability updated successfully');
    } on GuideException catch (e) {
      emit(GuideError(e.message));
      AppLogger.error('Failed to toggle guide availability: ${e.message}');
    } catch (e) {
      emit(const GuideError('Failed to toggle availability'));
      AppLogger.error('Unexpected error toggling guide availability: $e');
    }
  }

  Future<void> _onLoadAvailableGuides(LoadAvailableGuides event, Emitter<GuideState> emit) async {
    try {
      emit(const GuideLoading());
      AppLogger.info('Loading available guides');
      
      final guides = await _guideRepository.getAvailableGuides();
      emit(GuidesLoaded(guides));
      AppLogger.info('Available guides loaded successfully: ${guides.length} guides');
    } on GuideException catch (e) {
      emit(GuideError(e.message));
      AppLogger.error('Failed to load available guides: ${e.message}');
    } catch (e) {
      emit(const GuideError('Failed to load available guides'));
      AppLogger.error('Unexpected error loading available guides: $e');
    }
  }
}