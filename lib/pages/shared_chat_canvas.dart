import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/chat/chat_feed_canvas.dart';

class SharedChatCanvas extends ConsumerWidget {
  final String? chatId;
  final bool isReadOnly;

  const SharedChatCanvas({
    super.key,
    required this.chatId,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChatFeedCanvas(
      chatId: chatId,
      isReadOnly: isReadOnly,
    );
  }
}
