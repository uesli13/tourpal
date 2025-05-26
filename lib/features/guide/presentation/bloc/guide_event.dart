import 'package:equatable/equatable.dart';
import '../../../../models/guide.dart';

// Events
abstract class GuideEvent extends Equatable {
  const GuideEvent();
  @override
  List<Object> get props => [];
}

class LoadGuide extends GuideEvent {
  final String userId;
  const LoadGuide(this.userId);
  @override
  List<Object> get props => [userId];
}

class CreateGuideProfile extends GuideEvent {
  final Guide guide;
  const CreateGuideProfile(this.guide);
  @override
  List<Object> get props => [guide];
}

class UpdateGuideProfile extends GuideEvent {
  final Guide guide;
  const UpdateGuideProfile(this.guide);
  @override
  List<Object> get props => [guide];
}

class ToggleAvailability extends GuideEvent {
  final String userId;
  final bool isAvailable;
  const ToggleAvailability(this.userId, this.isAvailable);
  @override
  List<Object> get props => [userId, isAvailable];
}

class LoadAvailableGuides extends GuideEvent {}

