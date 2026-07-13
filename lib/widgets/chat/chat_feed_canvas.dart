// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

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
  final FocusNode _inputFocusNode = FocusNode();

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
    _inputFocusNode.dispose();
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

  Future<void> _updateMessage(String messageId, String newContent) async {
    final workspaceId = ref.read(currentWorkspaceIdProvider);
    if (workspaceId == null) return;

    final chatSession = ref.read(activeChatSessionProvider);
    final isChannel = chatSession.type == ChatSessionType.channel;
    final collectionPath = isChannel ? 'channels' : 'dms';
    final activeId = widget.chatId ?? '';

    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection(collectionPath)
          .doc(activeId)
          .collection('messages')
          .doc(messageId)
          .update({
        'content': newContent,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update message: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final workspaceId = ref.read(currentWorkspaceIdProvider);
    if (workspaceId == null) return;

    final chatSession = ref.read(activeChatSessionProvider);
    final isChannel = chatSession.type == ChatSessionType.channel;
    final collectionPath = isChannel ? 'channels' : 'dms';
    final activeId = widget.chatId ?? '';

    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection(collectionPath)
          .doc(activeId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete message: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showEditDialog(BuildContext context, MessageModel message) {
    final controller = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Edit your message...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                Navigator.pop(ctx);
                await _updateMessage(message.id, newContent);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, MessageModel message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to permanently delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteMessage(message.id);
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
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
    bool isChannelPrivate = false;
    if (isChannel) {
      final channelAsync = ref.watch(activeChannelProvider(activeId));
      titleText = channelAsync.value?.name ?? activeId;
      isChannelPrivate = channelAsync.value?.isPrivate ?? false;
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
        backgroundColor: theme.colorScheme.surfaceContainer,
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
                  isChannel
                      ? (isChannelPrivate ? HugeIconsStroke.lock : HugeIconsStroke.hashtag)
                      : HugeIconsStroke.user,
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
                          isChannel
                              ? (isChannelPrivate ? HugeIconsStroke.lock : HugeIconsStroke.hashtag)
                              : HugeIconsStroke.chat01,
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
                    final bool showSenderInfo = index + 1 >= messages.length ||
                        messages[index + 1].senderId != message.senderId;

                    return MessageRow(
                      message: message,
                      showSenderInfo: showSenderInfo,
                      onQuote: (text) {
                        final currentText = _controller.text;
                        _controller.text = '> $text\n$currentText';
                      },
                      onStartThread: (msg) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Start a Thread'),
                            content: const Text('Threads will be integrated soon!'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      onEdit: (msg) {
                        _showEditDialog(context, msg);
                      },
                      onDelete: (msg) {
                        _showDeleteConfirmDialog(context, msg);
                      },
                      onShowMenu: () {
                        if (_inputFocusNode.hasFocus) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _inputFocusNode.requestFocus();
                          });
                        }
                      },
                    );
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
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (!isMobile && event is KeyDownEvent) {
                            if (event.logicalKey == LogicalKeyboardKey.enter ||
                                event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                              final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
                              if (!isShiftPressed) {
                                _sendMessage();
                                return KeyEventResult.handled;
                              }
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: _controller,
                          focusNode: _inputFocusNode,
                          minLines: 1,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHigh,
                            hintText: 'Type your message here...',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant.withAlpha(80),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant.withAlpha(80),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
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
            ),
        ],
      ),
    );
  }
}

class MessageRow extends ConsumerStatefulWidget {
  final MessageModel message;
  final bool showSenderInfo;
  final Function(String text) onQuote;
  final Function(MessageModel message) onStartThread;
  final Function(MessageModel message) onEdit;
  final Function(MessageModel message) onDelete;
  final VoidCallback onShowMenu;

  const MessageRow({
    super.key,
    required this.message,
    required this.showSenderInfo,
    required this.onQuote,
    required this.onStartThread,
    required this.onEdit,
    required this.onDelete,
    required this.onShowMenu,
  });

  @override
  ConsumerState<MessageRow> createState() => _MessageRowState();
}

class _MessageRowState extends ConsumerState<MessageRow> {
  TapDownDetails? _tapDownDetails;
  OverlayEntry? _overlayEntry;

  void _hidePopupMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hidePopupMenu();
    super.dispose();
  }

  void _showPopupMenu(BuildContext context) {
    if (_tapDownDetails == null) return;
    widget.onShowMenu();

    final overlay = Overlay.of(context);

    final currentUserId = ref.read(authStateProvider).value?.uid ?? '';
    final workspace = ref.read(currentWorkspaceProvider);
    final chatSession = ref.read(activeChatSessionProvider);
    final isChannel = chatSession.type == ChatSessionType.channel;

    bool isSender = widget.message.senderId == currentUserId;
    bool isCreator = false;
    bool isManager = false;

    if (isChannel && chatSession.chatId != null) {
      final channelAsync = ref.read(activeChannelProvider(chatSession.chatId!));
      final channel = channelAsync.value;
      if (channel != null) {
        isCreator = channel.createdBy == currentUserId;
        isManager = channel.managers.contains(currentUserId);
      }
    }

    if (workspace != null) {
      final workspaceCreator = workspace['created_by'] ?? '';
      final workspaceManagers = List<String>.from(workspace['managers'] ?? []);
      if (workspaceCreator == currentUserId) {
        isCreator = true;
      }
      if (workspaceManagers.contains(currentUserId)) {
        isManager = true;
      }
    }

    final bool canDelete = isSender || isCreator || isManager;

    int itemCount = 2; // Quote and Thread
    if (isSender) itemCount++;
    if (canDelete) itemCount++;

    final double menuHeight = itemCount * 48.0 + 16.0;
    const double menuWidth = 200.0;
    final tapX = _tapDownDetails!.globalPosition.dx;
    final tapY = _tapDownDetails!.globalPosition.dy;
    final theme = Theme.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        final visibleHeight = size.height - keyboardHeight;

        double left = tapX;
        if (left + menuWidth > size.width - 16.0) {
          left = size.width - menuWidth - 16.0;
        }
        if (left < 16.0) left = 16.0;

        double adjustedTapY = tapY;
        if (adjustedTapY > visibleHeight - 16.0) {
          adjustedTapY = visibleHeight - 16.0;
        }

        double? topPosition;
        double? bottomPosition;

        if (adjustedTapY + menuHeight < visibleHeight - 16.0) {
          topPosition = adjustedTapY;
        } else {
          bottomPosition = size.height - adjustedTapY;
          if (bottomPosition < keyboardHeight + 16.0) {
            bottomPosition = keyboardHeight + 16.0;
          }
        }

        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hidePopupMenu,
              onPanDown: (_) => _hidePopupMenu(),
              child: const SizedBox.expand(),
            ),
            Positioned(
              left: left,
              top: topPosition,
              bottom: bottomPosition,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHigh,
                child: Container(
                  width: menuWidth,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildOverlayItem(
                        icon: Icons.format_quote_outlined,
                        text: 'Quote Message',
                        onTap: () {
                          _hidePopupMenu();
                          widget.onQuote(widget.message.content);
                        },
                        theme: theme,
                      ),
                      _buildOverlayItem(
                        icon: Icons.forum_outlined,
                        text: 'Start a Thread',
                        onTap: () {
                          _hidePopupMenu();
                          widget.onStartThread(widget.message);
                        },
                        theme: theme,
                      ),
                      if (isSender)
                        _buildOverlayItem(
                          icon: Icons.edit_outlined,
                          text: 'Edit Message',
                          onTap: () {
                            _hidePopupMenu();
                            widget.onEdit(widget.message);
                          },
                          theme: theme,
                        ),
                      if (canDelete)
                        _buildOverlayItem(
                          icon: Icons.delete_outline,
                          text: 'Delete Message',
                          textColor: theme.colorScheme.error,
                          iconColor: theme.colorScheme.error,
                          onTap: () {
                            _hidePopupMenu();
                            widget.onDelete(widget.message);
                          },
                          theme: theme,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  Widget _buildOverlayItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required ThemeData theme,
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userProfileByIdProvider(widget.message.senderId));

    return userAsync.when(
      data: (user) {
        final displayName = user?.displayName ?? widget.message.senderName;
        final photoUrl = user?.photoUrl ?? widget.message.senderPhotoUrl;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (details) {
              _tapDownDetails = details;
            },
            onSecondaryTapDown: (details) {
              _tapDownDetails = details;
            },
            onTap: () {
              // Allows ripple effect to play on simple tap
            },
            onSecondaryTap: () {
              _showPopupMenu(context);
            },
            onLongPress: () {
              _showPopupMenu(context);
            },
            hoverColor: theme.colorScheme.onSurface.withAlpha(12),
            splashColor: theme.colorScheme.primary.withAlpha(20),
            highlightColor: theme.colorScheme.primary.withAlpha(10),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: widget.showSenderInfo ? 8.0 : 2.0,
                horizontal: 16.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showSenderInfo)
                    _buildAvatar(displayName, photoUrl, theme)
                  else
                    const SizedBox(width: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showSenderInfo) ...[
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
                                _formatTimestamp(widget.message.timestamp),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          widget.message.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(220),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
