import 'package:flutter_riverpod/legacy.dart';

enum ChatSessionType { channel, dm, none }

class ActiveChatSession {
  final String? chatId;
  final ChatSessionType type;

  const ActiveChatSession({this.chatId, this.type = ChatSessionType.none});

  ActiveChatSession copyWith({String? chatId, ChatSessionType? type}) {
    return ActiveChatSession(
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
    );
  }
}

// Global Single Source of Truth for tracking which conversation is actively focused
final activeChatSessionProvider = StateProvider<ActiveChatSession>((ref) => const ActiveChatSession());
