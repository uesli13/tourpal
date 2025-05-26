import 'package:equatable/equatable.dart';
import '../../../../models/notification.dart';

/// Simple notifications states following TourPal's KEEP THINGS SIMPLE principle
abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object> get props => [];
}

/// Initial state
class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

/// Loading notifications
class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

/// Notifications loaded successfully
class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;

  const NotificationsLoaded({required this.notifications});

  @override
  List<Object> get props => [notifications];

  /// Get unread count for badge
  int get unreadCount => notifications.where((n) => !n.isRead).length;
  
  /// Get recent notifications (last 7 days)
  List<AppNotification> get recentNotifications {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return notifications.where((n) => n.createdAt.isAfter(weekAgo)).toList();
  }
}

/// Error state
class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError({required this.message});

  @override
  List<Object> get props => [message];
}