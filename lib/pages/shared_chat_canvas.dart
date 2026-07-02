import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/chat_state_provider.dart';
import 'package:chat/providers/layout_provider.dart';

// Enums
import 'package:chat/enums/layout_mode.dart';

class SharedChatCanvas extends ConsumerStatefulWidget {
  final String? chatId;
  final bool isReadOnly;

  const SharedChatCanvas({
    super.key,
    required this.chatId,
    required this.isReadOnly,
  });

  @override
  ConsumerState<SharedChatCanvas> createState() => _SharedChatCanvasState();
}

class _SharedChatCanvasState extends ConsumerState<SharedChatCanvas> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialText = ref.read(messageDraftProvider(widget.chatId ?? ''));
    _controller = TextEditingController(text: initialText);
    _controller.addListener(_syncTextWithProvider);
  }

  @override
  void didUpdateWidget(SharedChatCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      _controller.removeListener(_syncTextWithProvider);
      _controller.dispose();
      final initialText = ref.read(messageDraftProvider(widget.chatId ?? ''));
      _controller = TextEditingController(text: initialText);
      _controller.addListener(_syncTextWithProvider);
    }
  }

  void _syncTextWithProvider() {
    ref.read(messageDraftProvider(widget.chatId ?? '').notifier).state = _controller.text;
  }

  @override
  void dispose() {
    _controller.removeListener(_syncTextWithProvider);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatSession = ref.watch(activeChatSessionProvider);
    final layoutMode = ref.watch(layoutProvider);
    final isMobile = layoutMode == LayoutMode.mobile;
    final isChannel = chatSession.type == ChatSessionType.channel;
    final prefix = isChannel ? '#' : '';
    final activeId = widget.chatId ?? '';

    if (activeId.isEmpty) {
      return Center(
        child: Text(
          "No conversation selected",
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Custom back button used on mobile
        titleSpacing: isMobile ? 0 : 16,
        leading: isMobile
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  ref.read(activeChatSessionProvider.notifier).state = const ActiveChatSession();
                },
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              alignment: Alignment.center,
              child: Icon(
                isChannel ? HugeIconsStroke.hashtag : HugeIconsStroke.user,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$prefix$activeId',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isChannel ? 'channel space' : 'direct message',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(HugeIconsStroke.call),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(HugeIconsStroke.informationCircle),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Expanded mock messages space
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isChannel ? HugeIconsStroke.hashtag : HugeIconsStroke.chat01,
                    size: 64,
                    color: theme.colorScheme.primary.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isChannel
                        ? "Active Channels Chat Space Preview"
                        : "Active DMs Chat Space Preview",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You are currently viewing $prefix$activeId.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Preserved Text Box Input Row
          if (!widget.isReadOnly)
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withAlpha(80),
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type your message here...',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        _controller.clear();
                      }
                    },
                    icon: const Icon(HugeIconsStroke.sent),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(48, 48),
                      maximumSize: const Size(48, 48),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
