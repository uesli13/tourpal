import 'package:equatable/equatable.dart';
import 'package:tourpal/models/tour_plan.dart';

abstract class TourEvent extends Equatable {
  const TourEvent();

  @override
  List<Object?> get props => [];
}

class LoadToursEvent extends TourEvent {
  final String? guideId;
  final TourStatus? status;
  
  const LoadToursEvent({this.guideId, this.status});
  
  @override
  List<Object?> get props => [guideId, status];
}

class LoadToursByGuideEvent extends TourEvent {
  final String guideId;
  
  const LoadToursByGuideEvent(this.guideId);
  
  @override
  List<Object?> get props => [guideId];
}

class LoadAllPublishedToursEvent extends TourEvent {
  const LoadAllPublishedToursEvent();
}

class LoadTourDetailsEvent extends TourEvent {
  final String tourId;
  
  const LoadTourDetailsEvent(this.tourId);
  
  @override
  List<Object?> get props => [tourId];
}

class UpdateTourStatusEvent extends TourEvent {
  final String tourId;
  final TourStatus status;
  
  const UpdateTourStatusEvent(this.tourId, this.status);
  
  @override
  List<Object?> get props => [tourId, status];
}
 
class UpdateTourEvent extends TourEvent {
  final TourPlan tour;
  
  const UpdateTourEvent(this.tour);
  
  @override
  List<Object?> get props => [tour];
}

class DeleteTourEvent extends TourEvent {
  final String tourId;
  
  const DeleteTourEvent(this.tourId);
  
  @override
  List<Object?> get props => [tourId];
}

class RefreshToursEvent extends TourEvent {
  final String? guideId;
  
  const RefreshToursEvent({this.guideId});
  
  @override
  List<Object?> get props => [guideId];
}

class FilterToursEvent extends TourEvent {
  final TourStatus? status;
  final String? searchQuery;
  
  const FilterToursEvent({this.status, this.searchQuery});
  
  @override
  List<Object?> get props => [status, searchQuery];
}