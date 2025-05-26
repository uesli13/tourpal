import 'package:equatable/equatable.dart';
import '../../../../models/notification.dart';

/// Simple notifications events following TourPal's KEEP THINGS SIMPLE principle
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object> get props => [];
}

/// Load user notifications
class LoadNotificationsEvent extends NotificationsEvent {
  const LoadNotificationsEvent();
}

/// Mark notification as read
class MarkNotificationReadEvent extends NotificationsEvent {
  final String notificationId;

  const MarkNotificationReadEvent({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

/// Mark single notification as read (alias for screen compatibility)
class MarkAsReadEvent extends NotificationsEvent {
  final String notificationId;

  const MarkAsReadEvent(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

/// Mark all notifications as read
class MarkAllAsReadEvent extends NotificationsEvent {
  const MarkAllAsReadEvent();
}

/// Delete a notification
class DeleteNotificationEvent extends NotificationsEvent {
  final String notificationId;

  const DeleteNotificationEvent(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

/// Create new notification (for testing/demo)
class CreateNotificationEvent extends NotificationsEvent {
  final String title;
  final String message;
  final NotificationType type;
  final String? actionData;

  const CreateNotificationEvent({
    required this.title,
    required this.message,
    required this.type,
    this.actionData,
  });

  @override
  List<Object> get props => [title, message, type, actionData ?? ''];
}