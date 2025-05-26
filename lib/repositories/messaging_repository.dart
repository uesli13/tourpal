import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourpal/models/message.dart';
import '../../models/conversation.dart';

class MessagingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Conversations
  Stream<List<Conversation>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Conversation.fromMap(doc.data(), doc.id)).toList());
  }

  Future<String> createOrGetConversation(String currentUserId, String otherUserId, 
      String currentUserName, String otherUserName, 
      String? currentUserPhoto, String? otherUserPhoto) async {
    // Check if conversation already exists
    final existingQuery = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (var doc in existingQuery.docs) {
      final conversation = Conversation.fromMap(doc.data(), doc.id);
      if (conversation.participantIds.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create new conversation
    final conversationData = Conversation(
      id: '',
      participantIds: [currentUserId, otherUserId],
      participantNames: {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      participantPhotos: {
        if (currentUserPhoto != null) currentUserId: currentUserPhoto,
        if (otherUserPhoto != null) otherUserId: otherUserPhoto,
      },
      unreadCounts: {
        currentUserId: 0,
        otherUserId: 0,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _firestore.collection('conversations').add(conversationData.toMap());
    return docRef.id;
  }

  // Messages
  Stream<List<Message>> getConversationMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> sendMessage(Message message) async {
    final batch = _firestore.batch();
    
    // Add message to conversation
    final messageRef = _firestore
        .collection('conversations')
        .doc(message.conversationId)
        .collection('messages')
        .doc();
    
    batch.set(messageRef, message.copyWith(id: messageRef.id).toMap());

    // Update conversation with last message info
    final conversationRef = _firestore.collection('conversations').doc(message.conversationId);
    
    // Get current conversation to update unread counts
    final conversationDoc = await conversationRef.get();
    if (conversationDoc.exists) {
      final conversation = Conversation.fromMap(conversationDoc.data()!, conversationDoc.id);
      final updatedUnreadCounts = Map<String, int>.from(conversation.unreadCounts);
      
      // Increment unread count for other participants
      for (String participantId in conversation.participantIds) {
        if (participantId != message.senderId) {
          updatedUnreadCounts[participantId] = (updatedUnreadCounts[participantId] ?? 0) + 1;
        }
      }

      batch.update(conversationRef, {
        'lastMessage': message.content,
        'lastMessageSenderId': message.senderId,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'unreadCounts': updatedUnreadCounts,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    await batch.commit();
  }

  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final batch = _firestore.batch();

    // Get unread messages
    final messagesQuery = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('readBy', whereNotIn: [userId])
        .get();

    // Mark messages as read
    for (var doc in messagesQuery.docs) {
      final message = Message.fromMap(doc.data(), doc.id);
      final updatedReadBy = List<String>.from(message.readBy)..add(userId);
      batch.update(doc.reference, {'readBy': updatedReadBy});
    }

    // Reset unread count for this user
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final conversationDoc = await conversationRef.get();
    if (conversationDoc.exists) {
      final conversation = Conversation.fromMap(conversationDoc.data()!, conversationDoc.id);
      final updatedUnreadCounts = Map<String, int>.from(conversation.unreadCounts);
      updatedUnreadCounts[userId] = 0;
      
      batch.update(conversationRef, {'unreadCounts': updatedUnreadCounts});
    }

    await batch.commit();
  }

  Future<void> deleteConversation(String conversationId) async {
    final batch = _firestore.batch();

    // Delete all messages in the conversation
    final messagesQuery = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();

    for (var doc in messagesQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete the conversation
    batch.delete(_firestore.collection('conversations').doc(conversationId));

    await batch.commit();
  }
}