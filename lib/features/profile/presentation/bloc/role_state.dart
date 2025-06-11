import 'package:equatable/equatable.dart';
import '../../../../models/guide.dart';

/// User roles in the app
enum UserRole { traveler, guide }

/// States for role switching and guide profile management
abstract class RoleState extends Equatable {
  const RoleState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class RoleInitial extends RoleState {
  const RoleInitial();
}

/// Loading state
class RoleLoading extends RoleState {
  const RoleLoading();
}

/// User is in traveler mode (default)
class TravelerModeState extends RoleState {
  final bool canBecomeGuide;

  const TravelerModeState({this.canBecomeGuide = true});

  @override
  List<Object> get props => [canBecomeGuide];
}

/// User is in guide mode
class GuideModeState extends RoleState {
  final Guide guide;

  const GuideModeState(this.guide);

  @override
  List<Object> get props => [guide];
}

/// Guide profile creation in progress
class GuideProfileCreating extends RoleState {
  const GuideProfileCreating();
}

/// Guide profile created successfully
class GuideProfileCreated extends RoleState {
  final Guide guide;

  const GuideProfileCreated(this.guide);

  @override
  List<Object> get props => [guide];
}

/// Guide profile updated successfully
class GuideProfileUpdated extends RoleState {
  final Guide guide;

  const GuideProfileUpdated(this.guide);

  @override
  List<Object> get props => [guide];
}

/// Guide profile deleted successfully
class GuideProfileDeleted extends RoleState {
  const GuideProfileDeleted();
}

/// Guide availability updated
class GuideAvailabilityUpdated extends RoleState {
  final Guide guide;

  const GuideAvailabilityUpdated(this.guide);

  @override
  List<Object> get props => [guide];
}

/// Error state
class RoleError extends RoleState {
  final String message;

  const RoleError(this.message);

  @override
  List<Object> get props => [message];
}

/// Dual role state - user has both traveler and guide capabilities
class DualRoleState extends RoleState {
  final UserRole currentRole;
  final Guide? guide;
  final bool canSwitchRoles;

  const DualRoleState({
    required this.currentRole,
    this.guide,
    this.canSwitchRoles = true,
  });

  bool get isGuide => guide != null;
  bool get isTraveler => currentRole == UserRole.traveler;
  bool get isInGuideMode => currentRole == UserRole.guide;

  @override
  List<Object?> get props => [currentRole, guide, canSwitchRoles];
}