

import 'package:progress_group/features/inbox/domain/repositories/message_repository.dart';

import '../entities/chat_message_entity.dart';

class GetMessagesUseCase {
  final MessageRepository repository;

  GetMessagesUseCase(this.repository);

  Future<ChatHistory> call(String sessionId, String jid, {int page = 1}) {
    return repository.getMessages(sessionId, jid, page: page);
  }
}