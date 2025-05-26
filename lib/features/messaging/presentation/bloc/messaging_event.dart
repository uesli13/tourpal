import 'package:equatable/equatable.dart';
import '../../../../models/conversation.dart';
import '../../../../models/message.dart';

abstract class MessagingEvent extends Equatable {
  const MessagingEvent();
  @override
  List<Object?> get props => [];
}

class LoadConversationsEvent extends MessagingEvent {}

class LoadConversationMessagesEvent extends MessagingEvent {
  final String conversationId;
  
  const LoadConversationMessagesEvent({required this.conversationId});
  
  @override
  List<Object> get props => [conversationId];
}

class SendMessageEvent extends MessagingEvent {
  final String conversationId;
  final String receiverId;
  final String content;
  
  const SendMessageEvent({
    required this.conversationId,
    required this.receiverId,
    required this.content,
  });
  
  @override
  List<Object> get props => [conversationId, receiverId, content];
}

class MarkAsReadEvent extends MessagingEvent {
  final String conversationId;
  
  const MarkAsReadEvent({required this.conversationId});
  
  @override
  List<Object> get props => [conversationId];
}