import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:tourpal/core/utils/logger.dart';
import 'package:tourpal/core/utils/bloc_error_handler.dart';
import 'package:tourpal/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:tourpal/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:tourpal/features/profile/domain/usecases/upload_profile_image_usecase.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

import '../../../auth/presentation/bloc/auth_event.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUsecase _getProfileUsecase;
  final UpdateProfileUsecase _updateProfileUsecase;
  final UploadProfileImageUsecase _uploadProfileImageUsecase;
  final AuthBloc? _authBloc;

  ProfileBloc({
    required GetProfileUsecase getProfileUsecase,
    required UpdateProfileUsecase updateProfileUsecase,
    required UploadProfileImageUsecase uploadProfileImageUsecase,
    AuthBloc? authBloc,
  })  : _getProfileUsecase = getProfileUsecase,
        _updateProfileUsecase = updateProfileUsecase,
        _uploadProfileImageUsecase = uploadProfileImageUsecase,
        _authBloc = authBloc,
        super(ProfileInitial()) {
    
    AppLogger.info('ProfileBloc initialized');
    
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateProfileRoleEvent>(_onUpdateProfileRole);
    on<UploadProfileImageEvent>(_onUploadImage);
    on<ClearProfileErrorEvent>(_onClearError);
  }

  @override
  void onChange(Change<ProfileState> change) {
    super.onChange(change);
    BlocErrorHandler.logTransition(
      'ProfileBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(ProfileEvent event) {
    super.onEvent(event);
    BlocErrorHandler.logEvent('ProfileBloc', event.runtimeType.toString());
  }

  Future<void> _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(ProfileLoading());
        return await _getProfileUsecase(event.userId);
      },
      onSuccess: (user) => emit(ProfileLoaded(user)),
      onError: (error) => emit(ProfileError.fromException(error)),
      operationName: 'loadProfile',
      serviceName: 'ProfileUsecase',
    );
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(ProfileUpdating());
        return await _updateProfileUsecase(
          name: event.name,
          bio: event.bio,
          profileImage: event.profileImage,
          profileImagePath: event.profileImagePath,
          removeProfileImage: event.removeProfileImage ?? false,
          birthdate: event.birthdate,
        );
      },
      onSuccess: (user) => emit(ProfileUpdateSuccess(user: user, message: 'Profile updated successfully!')),
      onError: (error) => emit(ProfileError.fromException(error)),
      operationName: 'updateProfile',
      serviceName: 'ProfileUsecase',
    );
  }

  Future<void> _onUpdateProfileRole(UpdateProfileRoleEvent event, Emitter<ProfileState> emit) async {
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(ProfileUpdating());
        return await _updateProfileUsecase(
          isGuide: event.isGuide,
        );
      },
      onSuccess: (user) {
        // Update the auth bloc with the new user state
        _authBloc?.add(UpdateUserRoleEvent(isGuide: event.isGuide));
        emit(ProfileUpdateSuccess(
          user: user, 
          message: event.isGuide 
              ? 'Switched to Guide Mode successfully!' 
              : 'Switched to Traveler Mode successfully!'
        ));
      },
      onError: (error) => emit(ProfileError.fromException(error)),
      operationName: 'updateProfileRole',
      serviceName: 'ProfileUsecase',
    );
  }

  Future<void> _onUploadImage(UploadProfileImageEvent event, Emitter<ProfileState> emit) async {
    await BlocErrorHandler.executeWithErrorHandling(
      operation: () async {
        emit(ProfileImageUploading());
        final imageFile = File(event.imagePath);
        return await _uploadProfileImageUsecase(event.userId, imageFile);
      },
      onSuccess: (imageUrl) => emit(ProfileImageUploaded(imageUrl: imageUrl)),
      onError: (error) => emit(ProfileError.fromException(error)),
      operationName: 'uploadImage',
      serviceName: 'ProfileUsecase',
    );
  }

  void _onClearError(ClearProfileErrorEvent event, Emitter<ProfileState> emit) {
    BlocErrorHandler.logEvent('ProfileBloc', 'ClearError');
    if (state is ProfileError) {
      emit(ProfileInitial());
    }
  }
}