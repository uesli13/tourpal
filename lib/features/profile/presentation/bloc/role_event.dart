import 'package:equatable/equatable.dart';

import '../../../../models/guide.dart';

/// Events for role switching and guide profile management
abstract class RoleEvent extends Equatable {
  const RoleEvent();

  @override
  List<Object?> get props => [];
}

/// Switch to traveler mode (only changes active mode, doesn't delete guide profile)
class SwitchToTravelerMode extends RoleEvent {
  const SwitchToTravelerMode();
}

/// Switch to guide mode
class SwitchToGuideMode extends RoleEvent {
  const SwitchToGuideMode();
}

/// Check if user is a guide
class CheckGuideStatus extends RoleEvent {
  final String userId;

  const CheckGuideStatus(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Create guide profile
class CreateGuideProfile extends RoleEvent {
  final Guide guide;

  const CreateGuideProfile(this.guide);

  @override
  List<Object> get props => [guide];
}

/// Update guide profile
class UpdateGuideProfile extends RoleEvent {
  final Guide guide;

  const UpdateGuideProfile(this.guide);

  @override
  List<Object> get props => [guide];
}

/// Update guide availability
class UpdateGuideAvailability extends RoleEvent {
  final String userId;
  final bool isAvailable;

  const UpdateGuideAvailability(this.userId, this.isAvailable);

  @override
  List<Object> get props => [userId, isAvailable];
}

/// Load guide profile
class LoadGuideProfile extends RoleEvent {
  final String userId;

  const LoadGuideProfile(this.userId);

  @override
  List<Object> get props => [userId];
}