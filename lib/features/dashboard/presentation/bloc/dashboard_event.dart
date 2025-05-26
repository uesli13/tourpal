import 'package:equatable/equatable.dart';

/// Dashboard events following TourPal BLoC architecture rules
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  final String userId;
  
  const LoadDashboard({required this.userId});
  
  @override
  List<Object> get props => [userId];
}

class RefreshDashboard extends DashboardEvent {
  final String userId;
  
  const RefreshDashboard({required this.userId});
  
  @override
  List<Object> get props => [userId];
}

class LoadRecentTours extends DashboardEvent {
  final String userId;
  final int limit;
  
  const LoadRecentTours({
    required this.userId,
    this.limit = 5,
  });
  
  @override
  List<Object> get props => [userId, limit];
}

class LoadFavoriteTours extends DashboardEvent {
  final String userId;
  final int limit;
  
  const LoadFavoriteTours({
    required this.userId,
    this.limit = 5,
  });
  
  @override
  List<Object> get props => [userId, limit];
}

class LoadBookingStats extends DashboardEvent {
  final String userId;
  
  const LoadBookingStats({required this.userId});
  
  @override
  List<Object> get props => [userId];
}