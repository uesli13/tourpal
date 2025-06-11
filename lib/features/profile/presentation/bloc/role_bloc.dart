import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/guide.dart';
import 'role_event.dart';
import 'role_state.dart';

class RoleBloc extends Bloc<RoleEvent, RoleState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _rolePreferenceKey = 'user_role_preference';

  RoleBloc() : super(const RoleInitial()) {
    on<CheckGuideStatus>(_onCheckGuideStatus);
    on<SwitchToTravelerMode>(_onSwitchToTravelerMode);
    on<SwitchToGuideMode>(_onSwitchToGuideMode);
    on<CreateGuideProfile>(_onCreateGuideProfile);
    on<UpdateGuideProfile>(_onUpdateGuideProfile);
    on<UpdateGuideAvailability>(_onUpdateGuideAvailability);
    on<LoadGuideProfile>(_onLoadGuideProfile);
  }

  Future<void> _onCheckGuideStatus(
    CheckGuideStatus event,
    Emitter<RoleState> emit,
  ) async {
    try {
      emit(const RoleLoading());

      final guideDoc = await _firestore
          .collection('guides')
          .doc(event.userId)
          .get();

      if (guideDoc.exists) {
        final guide = Guide.fromFirestore(guideDoc);
        
        // Get the user's preferred role from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final rolePreference = prefs.getString(_rolePreferenceKey);
        
        final preferredRole = rolePreference == 'guide' 
            ? UserRole.guide 
            : UserRole.traveler;
        
        emit(DualRoleState(
          currentRole: preferredRole,
          guide: guide,
        ));
      } else {
        emit(const TravelerModeState());
      }
    } catch (e) {
      emit(RoleError('Failed to check guide status: ${e.toString()}'));
    }
  }

  Future<void> _onSwitchToTravelerMode(
    SwitchToTravelerMode event,
    Emitter<RoleState> emit,
  ) async {
    if (state is DualRoleState) {
      final currentState = state as DualRoleState;
      
      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rolePreferenceKey, 'traveler');
      
      emit(DualRoleState(
        currentRole: UserRole.traveler,
        guide: currentState.guide,
      ));
    }
  }

  Future<void> _onSwitchToGuideMode(
    SwitchToGuideMode event,
    Emitter<RoleState> emit,
  ) async {
    if (state is DualRoleState) {
      final currentState = state as DualRoleState;
      if (currentState.guide != null) {
        // Save preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_rolePreferenceKey, 'guide');
        
        emit(DualRoleState(
          currentRole: UserRole.guide,
          guide: currentState.guide,
        ));
      }
    }
  }

  Future<void> _onCreateGuideProfile(
    CreateGuideProfile event,
    Emitter<RoleState> emit,
  ) async {
    try {
      emit(const GuideProfileCreating());

      await _firestore
          .collection('guides')
          .doc(event.guide.id)
          .set(event.guide.toFirestore());

      // Save preference when creating guide profile
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rolePreferenceKey, 'guide');

      emit(DualRoleState(
        currentRole: UserRole.guide,
        guide: event.guide,
      ));
    } catch (e) {
      emit(RoleError('Failed to create guide profile: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateGuideProfile(
    UpdateGuideProfile event,
    Emitter<RoleState> emit,
  ) async {
    try {
      emit(const RoleLoading());

      await _firestore
          .collection('guides')
          .doc(event.guide.id)
          .update(event.guide.toFirestore());

      emit(DualRoleState(
        currentRole: UserRole.guide,
        guide: event.guide,
      ));
    } catch (e) {
      emit(RoleError('Failed to update guide profile: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateGuideAvailability(
    UpdateGuideAvailability event,
    Emitter<RoleState> emit,
  ) async {
    try {
      await _firestore
          .collection('guides')
          .doc(event.userId)
          .update({'isAvailable': event.isAvailable});

      if (state is DualRoleState) {
        final currentState = state as DualRoleState;
        if (currentState.guide != null) {
          final updatedGuide = currentState.guide!.copyWith(
            isAvailable: event.isAvailable,
          );
          emit(DualRoleState(
            currentRole: currentState.currentRole,
            guide: updatedGuide,
          ));
        }
      }
    } catch (e) {
      emit(RoleError('Failed to update availability: ${e.toString()}'));
    }
  }

  Future<void> _onLoadGuideProfile(
    LoadGuideProfile event,
    Emitter<RoleState> emit,
  ) async {
    try {
      emit(const RoleLoading());

      final guideDoc = await _firestore
          .collection('guides')
          .doc(event.userId)
          .get();

      if (guideDoc.exists) {
        final guide = Guide.fromFirestore(guideDoc);
        emit(DualRoleState(
          currentRole: UserRole.guide,
          guide: guide,
        ));
      } else {
        emit(const TravelerModeState());
      }
    } catch (e) {
      emit(RoleError('Failed to load guide profile: ${e.toString()}'));
    }
  }
}