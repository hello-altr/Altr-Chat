// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers & Models
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/chat_state_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/repositories/chat_repository.dart';
import 'package:chat/models/message_model.dart';

// Enums
import 'package:chat/enums/layout_mode.dart';


final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  if (workspaceId == null) return Stream.value([]);

  final chatSession = ref.watch(activeChatSessionProvider);
  final isChannel = chatSession.type == ChatSessionType.channel;
  final collectionPath = isChannel ? 'channels' : 'dms';

  return FirebaseFirestore.instance
      .collection('workspaces')
      .doc(workspaceId)
      .collection(collectionPath)
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
      });
});

class ChatFeedCanvas extends ConsumerStatefulWidget {
  final String? chatId;
  final bool isReadOnly;

  const ChatFeedCanvas({
    super.key,
    required this.chatId,
    required this.isReadOnly,
  });

  @override
  ConsumerState<ChatFeedCanvas> createState() => _ChatFeedCanvasState();
}

class _ChatFeedCanvasState extends ConsumerState<ChatFeedCanvas> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialText = ref.read(messageDraftProvider(widget.chatId ?? ''));
    _controller = TextEditingController(text: initialText);
    _controller.addListener(_syncTextWithProvider);
  }

  @override
  void didUpdateWidget(ChatFeedCanvas oldWidget) {
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

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) return;

    final userProfile = ref.read(userProfileProvider).value;
    final senderName = userProfile?.displayName ?? authUser.displayName ?? 'Altr Member';
    final senderPhotoUrl = userProfile?.photoUrl ?? authUser.photoURL ?? '';

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    if (workspaceId == null) return;

    final chatSession = ref.read(activeChatSessionProvider);
    final isChannel = chatSession.type == ChatSessionType.channel;
    final collectionPath = isChannel ? 'channels' : 'dms';
    final activeId = widget.chatId ?? '';

    final docRef = FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection(collectionPath)
        .doc(activeId);

    _controller.clear();

    try {
      await docRef.collection('messages').add({
        'sender_id': authUser.uid,
        'sender_name': senderName,
        'sender_photo_url': senderPhotoUrl,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (isChannel) {
        await docRef.update({
          'last_message': content,
          'last_message_time': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'last_message': content,
          'last_message_preview': content,
          'last_message_time': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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

    // Resolve channel name or DM counterpart display name
    String titleText = activeId;
    if (isChannel) {
      final channelAsync = ref.watch(activeChannelProvider(activeId));
      titleText = channelAsync.value?.name ?? activeId;
    } else {
      final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
      final parts = activeId.split('_');
      final counterpartId = parts.firstWhere(
        (id) => id != currentUserId,
        orElse: () => currentUserId,
      );
      final profileAsync = ref.watch(userProfileByIdProvider(counterpartId));
      titleText = profileAsync.value?.displayName ?? 'Loading...';
    }

    final messagesAsync = ref.watch(messagesStreamProvider(activeId));

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
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isChannel
              ? () {
                  ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.channelInfo;
                }
              : () {
                  final currentUserId = ref.read(authStateProvider).value?.uid ?? '';
                  final parts = activeId.split('_');
                  final counterpartId = parts.firstWhere(
                    (id) => id != currentUserId,
                    orElse: () => currentUserId,
                  );
                  ref.read(profileTargetUserIdProvider.notifier).state = counterpartId;
                  ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.profile;
                },
          child: Row(
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
                      '$prefix$titleText',
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
        ),
        actions: [
          IconButton(
            icon: const Icon(HugeIconsStroke.call),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(HugeIconsStroke.informationCircle),
            onPressed: () {
              if (isChannel) {
                ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.channelInfo;
              } else {
                final currentUserId = ref.read(authStateProvider).value?.uid ?? '';
                final parts = activeId.split('_');
                final counterpartId = parts.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => currentUserId,
                );
                ref.read(profileTargetUserIdProvider.notifier).state = counterpartId;
                ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.profile;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
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
                          isChannel ? "Welcome to #$titleText!" : "Start of your DM with $titleText",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isChannel
                              ? "This is the start of the #$titleText channel."
                              : "Send a message to start the conversation.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageRow(message: message);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error loading messages: $err'),
              ),
            ),
          ),
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
                        onSubmitted: (_) => _sendMessage(),
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
                    onPressed: _sendMessage,
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

class MessageRow extends ConsumerWidget {
  final MessageModel message;
  const MessageRow({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userProfileByIdProvider(message.senderId));

    return userAsync.when(
      data: (user) {
        final displayName = user?.displayName ?? message.senderName;
        final photoUrl = user?.photoUrl ?? message.senderPhotoUrl;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(displayName, photoUrl, theme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: SizedBox(height: 36),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildAvatar(String displayName, String photoUrl, ThemeData theme) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(photoUrl),
      );
    }
    final initials = _getInitials(displayName);
    return CircleAvatar(
      radius: 18,
      backgroundColor: _getInitialsBgColor(displayName),
      child: Text(
        initials,
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getInitialsBgColor(String name) {
    final colors = [
      const Color(0xFFF43F5E), // Rose
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
    ];
    return colors[name.hashCode % colors.length];
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
