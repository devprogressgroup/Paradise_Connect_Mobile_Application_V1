import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/inbox/domain/usecases/get_messages_usecase.dart';
import 'package:progress_group/features/inbox/presentation/state/message/message_event.dart';
import 'package:progress_group/features/inbox/presentation/state/message/message_state.dart';

import '../../../domain/entities/chat_message_entity.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final GetMessagesUseCase getMessagesUseCase;

  MessageBloc(this.getMessagesUseCase) : super(MessageInitial()) {
    on<GetChatHistoryEvent>(_onGetChatHistory);
  }

  Future<void> _onGetChatHistory(
    GetChatHistoryEvent event,
    Emitter<MessageState> emit,
  ) async {
    final currentState = state;
    
    if (!event.isLoadMore) {
      emit(MessageLoading());
    } else if (currentState is MessageLoaded) {
      emit(MessageLoaded(currentState.chatHistory, isFetchingMore: true));
    }

    try {
      final chatHistory = await getMessagesUseCase(
        event.sessionId, 
        event.jid, 
        page: event.page
      );

      if (event.isLoadMore && currentState is MessageLoaded) {
        // Gabungkan pesan yang sudah ada dengan pesan baru (yang lebih lama) di bagian akhir
        final combinedMessages = [...currentState.chatHistory.messages, ...chatHistory.messages];
        emit(MessageLoaded(
          ChatHistory(
            messages: combinedMessages,
            contactInfo: currentState.chatHistory.contactInfo,
          ),
          isFetchingMore: false,
        ));
      } else {
        emit(MessageLoaded(chatHistory));
      }
    } catch (e) {
      emit(MessageError(cleanErrorMessage(e)));
    }
  }
}