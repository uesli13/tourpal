import 'package:equatable/equatable.dart';
import '../../../../models/tour_plan.dart';
import '../../../../models/user.dart';

/// Dashboard states following TourPal BLoC architecture rules
abstract class DashboardState extends Equatable {
  const DashboardState();
  
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final User user;
  final List<TourPlan> recentTours;
  final List<TourPlan> favoriteTours;
  final DashboardStats stats;
  
  const DashboardLoaded({
    required this.user,
    required this.recentTours,
    required this.favoriteTours,
    required this.stats,
  });
  
  @override
  List<Object> get props => [user, recentTours, favoriteTours, stats];
}

class DashboardError extends DashboardState {
  final String message;
  
  const DashboardError({required this.message});
  
  @override
  List<Object> get props => [message];
}

class DashboardRefreshing extends DashboardState {
  final DashboardLoaded previousState;
  
  const DashboardRefreshing({required this.previousState});
  
  @override
  List<Object> get props => [previousState];
}

/// Dashboard statistics data model
class DashboardStats extends Equatable {
  final int totalBookings;
  final int completedTours;
  final int upcomingBookings;
  final double totalSpent;
  final int reviewsGiven;
  
  const DashboardStats({
    required this.totalBookings,
    required this.completedTours,
    required this.upcomingBookings,
    required this.totalSpent,
    required this.reviewsGiven,
  });
  
  @override
  List<Object> get props => [
    totalBookings,
    completedTours,
    upcomingBookings,
    totalSpent,
    reviewsGiven,
  ];
  
  DashboardStats copyWith({
    int? totalBookings,
    int? completedTours,
    int? upcomingBookings,
    double? totalSpent,
    int? reviewsGiven,
  }) {
    return DashboardStats(
      totalBookings: totalBookings ?? this.totalBookings,
      completedTours: completedTours ?? this.completedTours,
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      totalSpent: totalSpent ?? this.totalSpent,
      reviewsGiven: reviewsGiven ?? this.reviewsGiven,
    );
  }
  
  static const empty = DashboardStats(
    totalBookings: 0,
    completedTours: 0,
    upcomingBookings: 0,
    totalSpent: 0.0,
    reviewsGiven: 0,
  );
}