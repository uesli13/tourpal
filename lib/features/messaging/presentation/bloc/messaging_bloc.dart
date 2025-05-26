import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/messaging_service.dart';
import '../../../../core/utils/logger.dart';
import 'messaging_event.dart';
import 'messaging_state.dart';

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessagingService _messagingService;
  StreamSubscription? _conversationsSubscription;
  StreamSubscription? _messagesSubscription;

  MessagingBloc({required MessagingService messagingService})
      : _messagingService = messagingService,
        super(MessagingInitial()) {
    
    AppLogger.info('MessagingBloc initialized');
    
    on<LoadConversationsEvent>(_onLoadConversations);
    on<LoadConversationMessagesEvent>(_onLoadConversationMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<MarkAsReadEvent>(_onMarkAsRead);
  }

  @override
  void onChange(Change<MessagingState> change) {
    super.onChange(change);
    AppLogger.blocTransition(
      'MessagingBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(MessagingEvent event) {
    super.onEvent(event);
    AppLogger.blocEvent('MessagingBloc', event.runtimeType.toString());
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      emit(MessagingLoading());
      
      await _conversationsSubscription?.cancel();
      _conversationsSubscription = _messagingService.getUserConversations().listen(
        (conversations) {
          if (!isClosed) {
            emit(ConversationsLoaded(conversations: conversations));
          }
        },
        onError: (error) {
          AppLogger.error('Error loading conversations', error);
          if (!isClosed) {
            emit(MessagingError(message: 'Failed to load conversations'));
          }
        },
      );
    } catch (e) {
      AppLogger.error('Failed to load conversations', e);
      emit(MessagingError(message: 'Failed to load conversations'));
    }
  }

  Future<void> _onLoadConversationMessages(
    LoadConversationMessagesEvent event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagesSubscription?.cancel();
      _messagesSubscription = _messagingService
          .getConversationMessages(event.conversationId)
          .listen(
        (messages) {
          if (!isClosed) {
            emit(ConversationMessagesLoaded(
              messages: messages,
              conversationId: event.conversationId,
            ));
          }
        },
        onError: (error) {
          AppLogger.error('Error loading messages', error);
          if (!isClosed) {
            emit(MessagingError(message: 'Failed to load messages'));
          }
        },
      );
    } catch (e) {
      AppLogger.error('Failed to load conversation messages', e);
      emit(MessagingError(message: 'Failed to load messages'));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      if (event.content.trim().isEmpty) {
        emit(MessagingError(message: 'Message cannot be empty'));
        return;
      }

      await _messagingService.sendMessage(
        conversationId: event.conversationId,
        receiverId: event.receiverId,
        content: event.content,
      );

      AppLogger.info('Message sent successfully');
      // State will be updated automatically via stream
    } catch (e) {
      AppLogger.error('Failed to send message', e);
      emit(MessagingError(message: 'Failed to send message'));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagingService.markMessagesAsRead(event.conversationId);
      AppLogger.info('Messages marked as read');
    } catch (e) {
      AppLogger.error('Failed to mark messages as read', e);
      // Don't emit error - this is not critical
    }
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}