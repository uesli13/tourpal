import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../../../core/utils/logger.dart';
import '../../../../models/notification.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

/// Simple notifications BLoC following TourPal's KEEP THINGS SIMPLE principle
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  static const String _notificationsCollection = 'notifications';

  NotificationsBloc() : super(const NotificationsInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<MarkNotificationReadEvent>(_onMarkNotificationRead);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAllAsReadEvent>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<CreateNotificationEvent>(_onCreateNotification);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      AppLogger.info('Loading user notifications');
      emit(const NotificationsLoading());
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(const NotificationsLoaded(notifications: []));
        return;
      }

      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final notifications = querySnapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
          .toList();

      emit(NotificationsLoaded(notifications: notifications));
      AppLogger.info('Notifications loaded: ${notifications.length} items');
    } catch (e) {
      AppLogger.error('Failed to load notifications', e);
      emit(const NotificationsError(message: 'Failed to load notifications'));
    }
  }

  Future<void> _onMarkNotificationRead(
    MarkNotificationReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      AppLogger.info('Marking notification as read: ${event.notificationId}');
      
      await _firestore
          .collection(_notificationsCollection)
          .doc(event.notificationId)
          .update({'isRead': true});

      // Update current state
      final currentState = state;
      if (currentState is NotificationsLoaded) {
        final updatedNotifications = currentState.notifications.map((n) {
          return n.id == event.notificationId ? n.copyWith(isRead: true) : n;
        }).toList();
        
        emit(NotificationsLoaded(notifications: updatedNotifications));
      }
      
      AppLogger.serviceOperation('NotificationsBloc', 'markAsRead', true);
    } catch (e) {
      AppLogger.error('Failed to mark notification as read', e);
      AppLogger.serviceOperation('NotificationsBloc', 'markAsRead', false);
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      AppLogger.info('Marking notification as read: ${event.notificationId}');
      
      await _firestore
          .collection(_notificationsCollection)
          .doc(event.notificationId)
          .update({'isRead': true});

      // Update current state
      final currentState = state;
      if (currentState is NotificationsLoaded) {
        final updatedNotifications = currentState.notifications.map((n) {
          return n.id == event.notificationId ? n.copyWith(isRead: true) : n;
        }).toList();
        
        emit(NotificationsLoaded(notifications: updatedNotifications));
      }
      
      AppLogger.serviceOperation('NotificationsBloc', 'markAsRead', true);
    } catch (e) {
      AppLogger.error('Failed to mark notification as read', e);
      AppLogger.serviceOperation('NotificationsBloc', 'markAsRead', false);
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      AppLogger.info('Marking all notifications as read');
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get all unread notifications for the user
      final unreadQuery = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      // Batch update all unread notifications
      final batch = _firestore.batch();
      for (final doc in unreadQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Update current state
      final currentState = state;
      if (currentState is NotificationsLoaded) {
        final updatedNotifications = currentState.notifications.map((n) {
          return n.copyWith(isRead: true);
        }).toList();
        
        emit(NotificationsLoaded(notifications: updatedNotifications));
      }
      
      AppLogger.serviceOperation('NotificationsBloc', 'markAllAsRead', true);
    } catch (e) {
      AppLogger.error('Failed to mark all notifications as read', e);
      AppLogger.serviceOperation('NotificationsBloc', 'markAllAsRead', false);
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      AppLogger.info('Deleting notification: ${event.notificationId}');
      
      await _firestore
          .collection(_notificationsCollection)
          .doc(event.notificationId)
          .delete();

      // Update current state
      final currentState = state;
      if (currentState is NotificationsLoaded) {
        final updatedNotifications = currentState.notifications
            .where((n) => n.id != event.notificationId)
            .toList();
        
        emit(NotificationsLoaded(notifications: updatedNotifications));
      }
      
      AppLogger.serviceOperation('NotificationsBloc', 'deleteNotification', true);
    } catch (e) {
      AppLogger.error('Failed to delete notification', e);
      AppLogger.serviceOperation('NotificationsBloc', 'deleteNotification', false);
    }
  }

  Future<void> _onCreateNotification(
    CreateNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final notification = AppNotification(
        id: '',
        userId: currentUser.uid,
        title: event.title,
        message: event.message,
        type: event.type,
        isRead: false,
        createdAt: DateTime.now(),
        actionData: event.actionData,
      );

      await _firestore
          .collection(_notificationsCollection)
          .add(notification.toMap());

      AppLogger.info('Notification created: ${event.title}');
      
      // Reload notifications
      add(const LoadNotificationsEvent());
    } catch (e) {
      AppLogger.error('Failed to create notification', e);
    }
  }
}