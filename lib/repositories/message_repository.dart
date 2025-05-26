import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourpal/core/constants/app_constants.dart';
import '../core/errors/error_handler.dart';
import 'base_repository.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });
  
  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isRead: map['isRead'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }
}

class MessageRepository extends BaseRepository {
  MessageRepository(super.firestore);
  
  CollectionReference get _messagesCollection => 
      firestore.collection(FirebaseCollections.messages);
  
  /// Send a message
  Future<Message> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    return await handleAsyncFirestoreError(() async {
      AppErrorHandler.logInfo('Sending message from $senderId to $receiverId');
      
      final docRef = _messagesCollection.doc();
      final message = Message(
        id: docRef.id,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      await docRef.set(message.toMap());
      
      AppErrorHandler.logInfo('Message sent successfully: ${message.id}');
      return message;
    });
  }
  
  /// Get messages between two users
  Future<List<Message>> getConversation(String userId1, String userId2) async {
    return await handleAsyncFirestoreError(() async {
      AppErrorHandler.logInfo('Fetching conversation between $userId1 and $userId2');
      
      final querySnapshot = await _messagesCollection
          .where('senderId', whereIn: [userId1, userId2])
          .where('receiverId', whereIn: [userId1, userId2])
          .orderBy('timestamp', descending: true)
          .get();
      
      final messages = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Message.fromMap(data, doc.id);
          })
          .where((message) =>
              (message.senderId == userId1 && message.receiverId == userId2) ||
              (message.senderId == userId2 && message.receiverId == userId1))
          .toList();
      
      AppErrorHandler.logInfo('Fetched ${messages.length} messages');
      return messages;
    });
  }
  
  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    return await handleAsyncFirestoreError(() async {
      await _messagesCollection.doc(messageId).update({'isRead': true});
    });
  }
  
  /// Listen to conversation
  Stream<List<Message>> watchConversation(String userId1, String userId2) {
    return _messagesCollection
        .where('senderId', whereIn: [userId1, userId2])
        .where('receiverId', whereIn: [userId1, userId2])
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Message.fromMap(data, doc.id);
          })
          .where((message) =>
              (message.senderId == userId1 && message.receiverId == userId2) ||
              (message.senderId == userId2 && message.receiverId == userId1))
          .toList();
    });
  }
}