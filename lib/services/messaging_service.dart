import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/conversation.dart';
import '../models/message.dart';
import '../core/errors/error_handler.dart';

/// Simple messaging service following TourPal's KEEP THINGS SIMPLE principle
class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';

  /// Get user's conversations as a stream
  Stream<List<Conversation>> getUserConversations() {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return Stream.value([]);

      return _firestore
          .collection(_conversationsCollection)
          .where('participantIds', arrayContains: currentUser.uid)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Conversation.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      AppErrorHandler.handleError(e);
      return Stream.value([]);
    }
  }

  /// Get messages for a conversation as a stream
  Stream<List<Message>> getConversationMessages(String conversationId) {
    try {
      return _firestore
          .collection(_messagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('sentAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Message.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      AppErrorHandler.handleError(e);
      return Stream.value([]);
    }
  }

  /// Send a new message
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw AppException('User not authenticated');

      final messageRef = _firestore.collection(_messagesCollection).doc();
      final now = DateTime.now();

      final message = Message(
        id: messageRef.id,
        senderId: currentUser.uid,
        receiverId: receiverId,
        content: content.trim(),
        sentAt: now,
        isRead: false,
        conversationId: conversationId,
      );

      // Update conversation and send message in batch
      final batch = _firestore.batch();
      
      batch.set(messageRef, message.toMap());
      
      batch.update(_firestore.collection(_conversationsCollection).doc(conversationId), {
        'lastMessage': content.trim(),
        'lastMessageSenderId': currentUser.uid,
        'lastMessageTime': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'unreadCounts.$receiverId': FieldValue.increment(1),
      });

      await batch.commit();
      AppErrorHandler.logInfo('Message sent to conversation: $conversationId');
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Failed to send message: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final batch = _firestore.batch();

      // Mark unread messages as read
      final unreadMessages = await _firestore
          .collection(_messagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Reset unread count for current user
      batch.update(_firestore.collection(_conversationsCollection).doc(conversationId), {
        'unreadCounts.${currentUser.uid}': 0,
      });

      await batch.commit();
      AppErrorHandler.logInfo('Messages marked as read for conversation: $conversationId');
    } catch (e) {
      AppErrorHandler.handleError(e);
      // Don't throw - this is not critical
    }
  }

  /// Get unread message count for current user
  Future<int> getTotalUnreadCount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 0;

      final conversations = await _firestore
          .collection(_conversationsCollection)
          .where('participantIds', arrayContains: currentUser.uid)
          .get();

      int totalUnread = 0;
      for (final doc in conversations.docs) {
        final conversation = Conversation.fromMap(doc.data(), doc.id);
        totalUnread += conversation.getUnreadCount(currentUser.uid);
      }

      return totalUnread;
    } catch (e) {
      AppErrorHandler.handleError(e);
      return 0;
    }
  }
}