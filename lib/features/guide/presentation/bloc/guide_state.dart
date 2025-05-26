import 'package:equatable/equatable.dart';
import '../../../../models/guide.dart';

abstract class GuideState extends Equatable {const GuideState();
    @override
  List<Object?> get props => [];
}

class GuideInitial extends GuideState {const GuideInitial();
}

class GuideLoading extends GuideState {const GuideLoading();

}
class GuideLoaded extends GuideState {
  final Guide guide;
  const GuideLoaded(this.guide);
  @override
  List<Object> get props => [guide];
}

class GuidesLoaded extends GuideState {
  final List<Guide> guides;
  const GuidesLoaded(this.guides);
  @override
  List<Object> get props => [guides];
}

class GuideError extends GuideState {
  final String message;
  const GuideError(this.message);
  @override
  List<Object> get props => [message];
}