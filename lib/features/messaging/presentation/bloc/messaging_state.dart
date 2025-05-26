import 'package:equatable/equatable.dart';
import '../../../../models/conversation.dart';
import '../../../../models/message.dart';

abstract class MessagingState extends Equatable {
  const MessagingState();
  @override
  List<Object?> get props => [];
}

class MessagingInitial extends MessagingState {}

class MessagingLoading extends MessagingState {}

class ConversationsLoaded extends MessagingState {
  final List<Conversation> conversations;
  
  const ConversationsLoaded({required this.conversations});
  
  @override
  List<Object> get props => [conversations];
}

class ConversationMessagesLoaded extends MessagingState {
  final List<Message> messages;
  final String conversationId;
  
  const ConversationMessagesLoaded({
    required this.messages,
    required this.conversationId,
  });
  
  @override
  List<Object> get props => [messages, conversationId];
}

class MessageSent extends MessagingState {}

class MessagingError extends MessagingState {
  final String message;
  
  const MessagingError({required this.message});
  
  @override
  List<Object> get props => [message];
}