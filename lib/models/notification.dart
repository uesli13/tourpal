import 'package:equatable/equatable.dart';

/// Simple notification model following TourPal's KEEP THINGS SIMPLE principle
class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? actionData; // Optional data for navigation

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.actionData,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      type: NotificationType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      isRead: map['isRead'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      actionData: map['actionData'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'actionData': actionData,
    };
  }

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      actionData: actionData,
    );
  }

  @override
  List<Object?> get props => [
    id, userId, title, message, type, isRead, createdAt, actionData
  ];
}

/// Simple notification types
enum NotificationType {
  general('General', '📢'),
  booking('Booking', '📅'),
  favorite('Favorite', '💖'),
  tour('Tour Update', '🎯');

  const NotificationType(this.displayName, this.emoji);
  
  final String displayName;
  final String emoji;
}