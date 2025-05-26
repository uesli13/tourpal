import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:tourpal/core/utils/logger.dart';
import 'package:tourpal/core/exceptions/app_exceptions.dart';
import 'package:tourpal/features/profile/services/profile_service.dart';
import 'package:tourpal/features/profile/presentation/bloc/profile_event.dart';
import 'package:tourpal/features/profile/presentation/bloc/profile_state.dart';

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService _profileService;

  ProfileBloc({required ProfileService profileService})
      : _profileService = profileService,
        super(ProfileInitial()) {
    
    AppLogger.info('ProfileBloc initialized');
    
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateProfileEvent>(_onUpdateProfileEvent);
    on<UpdateProfileRoleEvent>(_onUpdateProfileRoleEvent);
    on<UpdateEmailEvent>(_onUpdateEmailEvent);
    on<UpdatePasswordEvent>(_onUpdatePasswordEvent);
    on<ClearErrorEvent>(_onClearErrorEvent);
    on<AddTourToFavorites>(_onAddTourToFavorites);
    on<RemoveTourFromFavorites>(_onRemoveTourFromFavorites);
  }

  @override
  void onChange(Change<ProfileState> change) {
    super.onChange(change);
    AppLogger.blocTransition(
      'ProfileBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(ProfileEvent event) {
    super.onEvent(event);
    AppLogger.blocEvent('ProfileBloc', event.runtimeType.toString());
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading profile for user: ${event.userId}');
    
    try {
      emit(ProfileLoading());
      
      final user = await _profileService.getUserProfile(event.userId);
      
      stopwatch.stop();
      AppLogger.performance('Load Profile', stopwatch.elapsed);
      AppLogger.serviceOperation('ProfileService', 'getUserProfile', true);
      
      emit(ProfileLoaded(user));
    } on ProfileException catch (e) {
      stopwatch.stop();
      AppLogger.error('Profile service error', e);
      AppLogger.serviceOperation('ProfileService', 'getUserProfile', false);
      emit(ProfileError(e.message));
    } on AppException catch (e) {
      stopwatch.stop();
      AppLogger.error('App error loading profile', e);
      emit(ProfileError(e.message));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Unexpected error loading profile', e);
      emit(const ProfileError('An unexpected error occurred'));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Updating profile for user: ${event.user.id}');
    
    emit(ProfileLoading());
    
    try {
      // Extract update data from the User object
      final updatedUser = await _profileService.updateProfile(
        name: event.user.name,
        bio: event.user.bio,
        // profileImagePath would need to be passed separately for new images
      );
      
      stopwatch.stop();
      AppLogger.performance('Profile Update', stopwatch.elapsed);
      AppLogger.serviceOperation('ProfileService', 'updateProfile', true);
      
      emit(ProfileUpdated(user: updatedUser));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to update profile', e);
      AppLogger.serviceOperation('ProfileService', 'updateProfile', false);
      emit(ProfileError(_getErrorMessage(e)));
    }
  }

  Future<void> _onUpdateProfileEvent(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Updating profile with new event handler');
    
    emit(ProfileLoading());
    
    try {
      // Handle profile image logic
      String? profileImagePath = event.profileImagePath;
      
      // If a new profile image file is provided, use its path
      if (event.profileImage != null) {
        profileImagePath = event.profileImage!.path;
      }
      
      // If remove profile image is requested, set path to null
      if (event.removeProfileImage == true) {
        profileImagePath = null;
      }
      
      final updatedUser = await _profileService.updateProfile(
        name: event.name,
        bio: event.bio,
        profileImagePath: profileImagePath,
        birthdate: event.birthdate,
      );
      
      stopwatch.stop();
      AppLogger.performance('Profile Update Event', stopwatch.elapsed);
      AppLogger.serviceOperation('ProfileService', 'updateProfile', true);
      
      emit(ProfileUpdateSuccess(user: updatedUser));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to update profile via event', e);
      AppLogger.serviceOperation('ProfileService', 'updateProfile', false);
      emit(ProfileError(_getErrorMessage(e), error: e.toString()));
    }
  }

  Future<void> _onUpdateProfileRoleEvent(
    UpdateProfileRoleEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Updating user role - isGuide: ${event.isGuide}');
    
    emit(ProfileLoading());
    
    try {
      final updatedUser = await _profileService.updateProfile(
        isGuide: event.isGuide,
      );
      
      stopwatch.stop();
      AppLogger.performance('Profile Role Update', stopwatch.elapsed);
      AppLogger.serviceOperation('ProfileService', 'updateProfile', true);
      
      emit(ProfileUpdateSuccess(user: updatedUser));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to update profile role', e);
      AppLogger.serviceOperation('ProfileService', 'updateProfile', false);
      emit(ProfileError(_getErrorMessage(e), error: e.toString()));
    }
  }

  Future<void> _onUpdateEmailEvent(
    UpdateEmailEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Updating user email');
    
    emit(ProfileLoading());
    
    try {
      await _profileService.updateEmail(
        newEmail: event.newEmail,
        password: event.password,
      );
      
      stopwatch.stop();
      AppLogger.performance('Email Update', stopwatch.elapsed);
      AppLogger.serviceOperation('ProfileService', 'updateEmail', true);
      
      emit(ProfileEmailUpdateSuccess(newEmail: event.newEmail));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to update email', e);
      AppLogger.serviceOperation('ProfileService', 'updateEmail', false);
      emit(ProfileError(_getErrorMessage(e), error: e.toString()));
    }
  }

  Future<void> _onUpdatePasswordEvent(
    UpdatePasswordEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Updating user password');
    
    emit(ProfileLoading());
    
    try {
      await _profileService.updatePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      
      stopwatch.stop();
      AppLogger.performance('Password Update', stopwatch.elapsed);
      AppLogger.serviceOperation('ProfileService', 'updatePassword', true);
      
      emit(const ProfilePasswordUpdateSuccess());
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to update password', e);
      AppLogger.serviceOperation('ProfileService', 'updatePassword', false);
      emit(ProfileError(_getErrorMessage(e), error: e.toString()));
    }
  }

  void _onClearErrorEvent(
    ClearErrorEvent event,
    Emitter<ProfileState> emit,
  ) {
    AppLogger.info('Clearing profile errors');
    emit(ProfileInitial());
  }

  Future<void> _onAddTourToFavorites(AddTourToFavorites event, Emitter<ProfileState> emit) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Adding tour ${event.tourId} to favorites for user ${event.userId}');
    
    try {
      await _profileService.addTourToFavorites(event.userId, event.tourId);
      
      // Get updated user profile
      final updatedUser = await _profileService.getUserProfile(event.userId);
      
      stopwatch.stop();
      AppLogger.performance('Add Tour to Favorites', stopwatch.elapsed);
      AppLogger.serviceOperation('ProfileService', 'addTourToFavorites', true);
      
      emit(TourAddedToFavorites(tourId: event.tourId, updatedUser: updatedUser));
    } on ProfileServiceException catch (e) {
      stopwatch.stop();
      AppLogger.error('Error adding tour to favorites', e);
      AppLogger.serviceOperation('ProfileService', 'addTourToFavorites', false);
      emit(ProfileError(e.message));
    } on AppException catch (e) {
      stopwatch.stop();
      AppLogger.error('App error adding tour to favorites', e);
      emit(ProfileError(e.message));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Unexpected error adding tour to favorites', e);
      emit(const ProfileError('Failed to add tour to favorites'));
    }
  }

  Future<void> _onRemoveTourFromFavorites(RemoveTourFromFavorites event, Emitter<ProfileState> emit) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Removing tour ${event.tourId} from favorites for user ${event.userId}');
    
    try {
      await _profileService.removeTourFromFavorites(event.userId, event.tourId);
      
      // Get updated user profile
      final updatedUser = await _profileService.getUserProfile(event.userId);
      
      stopwatch.stop();
      AppLogger.performance('Remove Tour from Favorites', stopwatch.elapsed);
      AppLogger.serviceOperation('ProfileService', 'removeTourFromFavorites', true);
      
      emit(TourRemovedFromFavorites(tourId: event.tourId, updatedUser: updatedUser));
    } on ProfileServiceException catch (e) {
      stopwatch.stop();
      AppLogger.error('Error removing tour from favorites', e);
      AppLogger.serviceOperation('ProfileService', 'removeTourFromFavorites', false);
      emit(ProfileError(e.message));
    } on AppException catch (e) {
      stopwatch.stop();
      AppLogger.error('App error removing tour from favorites', e);
      emit(ProfileError(e.message));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Unexpected error removing tour from favorites', e);
      emit(const ProfileError('Failed to remove tour from favorites'));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is ProfileException) {
      return error.message;
    } else if (error is DatabaseException) {
      return 'Database error: ${error.message}';
    } else if (error is AuthenticationException) {
      return 'Authentication error: ${error.message}';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Future<void> close() {
    AppLogger.info('ProfileBloc disposed');
    return super.close();
  }
}