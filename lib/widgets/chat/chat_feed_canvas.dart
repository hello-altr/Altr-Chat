// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

// Providers
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/chat_state_provider.dart';
import 'package:chat/providers/appearance_notifier.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/providers/nav_provider.dart';

// Repositories
import 'package:chat/repositories/user_cache_repository.dart';
import 'package:chat/repositories/chat_repository.dart';

// Models
import 'package:chat/models/message_model.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/models/channel_model.dart';

// Enums
import 'package:chat/enums/layout_mode.dart';


// messagesStreamProvider has been replaced by channelMessagesStreamProvider and dmMessagesStreamProvider in chat_repository.dart

final workspaceUserGroupsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, workspaceId) {
  return FirebaseFirestore.instance
      .collection('workspaces')
      .doc(workspaceId)
      .collection('user_groups')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList());
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
  FocusNode _inputFocusNode = FocusNode();
  MessageModel? _quotedMessage;
  MessageModel? _editingMessage;

  bool _showMentionPopup = false;
  String _mentionQuery = '';
  int _mentionIndex = -1;

  @override
  void initState() {
    super.initState();
    final initialText = ref.read(messageDraftProvider(widget.chatId ?? ''));
    _controller = TextEditingController(text: initialText);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(ChatFeedCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      _controller.removeListener(_onTextChanged);
      _controller.dispose();
      final initialText = ref.read(messageDraftProvider(widget.chatId ?? ''));
      _controller = TextEditingController(text: initialText);
      _controller.addListener(_onTextChanged);
    }
  }

  void _syncTextWithProvider() {
    ref.read(messageDraftProvider(widget.chatId ?? '').notifier).state = _controller.text;
  }

  void _onTextChanged() {
    _syncTextWithProvider();

    final text = _controller.text;
    final selection = _controller.selection;
    final cursor = selection.baseOffset;

    if (cursor >= 0) {
      final textBeforeCursor = text.substring(0, cursor);
      final atIndex = textBeforeCursor.lastIndexOf('@');
      if (atIndex != -1) {
        final substring = textBeforeCursor.substring(atIndex + 1);
        final bool isWordBoundary = atIndex == 0 ||
            RegExp(r'\s').hasMatch(textBeforeCursor.substring(atIndex - 1, atIndex));

        if (isWordBoundary && !substring.contains(' ')) {
          setState(() {
            _showMentionPopup = true;
            _mentionQuery = substring;
            _mentionIndex = atIndex;
          });
          return;
        }
      }
    }

    if (_showMentionPopup) {
      setState(() {
        _showMentionPopup = false;
        _mentionQuery = '';
        _mentionIndex = -1;
      });
    }
  }

  void _selectMention(String handle) {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    if (cursor >= 0 && _mentionIndex != -1) {
      final beforeMention = text.substring(0, _mentionIndex);
      final afterCursor = text.substring(cursor);
      final newText = '$beforeMention@$handle $afterCursor';
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: _mentionIndex + handle.length + 2, // +1 for @, +1 for space
      );
    }
    setState(() {
      _showMentionPopup = false;
      _mentionQuery = '';
      _mentionIndex = -1;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) return;

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    if (workspaceId == null) return;

    final chatSession = ref.read(activeChatSessionProvider);
    final isChannel = chatSession.type == ChatSessionType.channel;
    final activeId = widget.chatId ?? '';

    final docRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(workspaceId)
        .collection(isChannel ? 'channels' : 'dms')
        .doc(activeId);

    _controller.clear();

    try {
      String? quotedSenderName;
      if (_quotedMessage != null) {
        final senderUser = ref.read(userCacheRepositoryProvider)[_quotedMessage!.senderId];
        quotedSenderName = senderUser?.displayName ?? 'Altr Member';
      }

      await docRef.collection('messages').add({
        'sender_id': authUser.uid,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'time': FieldValue.serverTimestamp(),
        'type': 'message',
        'quoted_reply_id': _quotedMessage?.id,
        if (_quotedMessage != null) ...{
          'quoted_message_content': _quotedMessage!.content,
          'quoted_message_sender_name': quotedSenderName,
        }
      });

      setState(() {
        _quotedMessage = null;
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

  Widget _buildQuotePreview(ThemeData theme) {
    if (_quotedMessage == null) return const SizedBox.shrink();
    final quotedSenderAsync = ref.watch(userProfileByIdProvider(_quotedMessage!.senderId));
    final quotedSenderName = quotedSenderAsync.value?.displayName ?? 'Altr Member';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quotedSenderName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _quotedMessage!.content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                _quotedMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateMessage(String messageId, String newContent) async {
    final workspaceId = ref.read(currentWorkspaceIdProvider);
    if (workspaceId == null) return;

    final chatSession = ref.read(activeChatSessionProvider);
    final isChannel = chatSession.type == ChatSessionType.channel;
    final activeId = widget.chatId ?? '';

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(workspaceId)
          .collection(isChannel ? 'channels' : 'dms')
          .doc(activeId)
          .collection('messages')
          .doc(messageId)
          .update({
        'content': newContent,
        'is_edited': true,
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
    final activeId = widget.chatId ?? '';

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(workspaceId)
          .collection(isChannel ? 'channels' : 'dms')
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

  Widget _buildEditPreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Editing Message',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _editingMessage!.content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                _editingMessage = null;
                _controller.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (_editingMessage != null) {
      _saveEditedMessage();
    } else {
      _sendMessage();
    }
  }

  Future<void> _saveEditedMessage() async {
    if (_editingMessage == null) return;
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final messageId = _editingMessage!.id;

    setState(() {
      _editingMessage = null;
      _controller.clear();
    });

    await _updateMessage(messageId, content);
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

  Widget _buildMentionPopup(BuildContext context, ThemeData theme, String workspaceId) {
    final workspaceMembersAsync = ref.watch(workspaceMembersStreamProvider(workspaceId));
    final userGroupsAsync = ref.watch(workspaceUserGroupsProvider(workspaceId));

    if (!workspaceMembersAsync.hasValue || !userGroupsAsync.hasValue) {
      return const SizedBox.shrink();
    }

    final members = workspaceMembersAsync.value ?? [];
    final groups = userGroupsAsync.value ?? [];

    final query = _mentionQuery.toLowerCase();
    final chatSession = ref.watch(activeChatSessionProvider);
    final activeId = widget.chatId ?? '';

    List<Map<String, dynamic>> items = [];

    // 1. Add matching users in this chat
    if (chatSession.type == ChatSessionType.channel) {
      final channel = ref.watch(activeChannelProvider(activeId)).value;
      if (channel != null) {
        final channelUsers = members.where((u) => channel.members.contains(u.userId));
        for (final user in channelUsers) {
          if (query.isEmpty ||
              user.displayName.toLowerCase().contains(query) ||
              user.userName.toLowerCase().contains(query)) {
            items.add({
              'id': user.userId,
              'name': user.displayName,
              'handle': user.userName,
              'type': 'user',
              'photoUrl': user.photoUrl,
            });
          }
        }
      }
    } else if (chatSession.type == ChatSessionType.dm) {
      final dm = ref.watch(activeDmProvider(activeId)).value;
      if (dm != null) {
        final dmUsers = members.where((u) => dm.participants.contains(u.userId));
        for (final user in dmUsers) {
          if (query.isEmpty ||
              user.displayName.toLowerCase().contains(query) ||
              user.userName.toLowerCase().contains(query)) {
            items.add({
              'id': user.userId,
              'name': user.displayName,
              'handle': user.userName,
              'type': 'user',
              'photoUrl': user.photoUrl,
            });
          }
        }
      }
    }

    // 2. Add matching workspace user groups that have been added to the channel
    if (chatSession.type == ChatSessionType.channel) {
      final channel = ref.watch(activeChannelProvider(activeId)).value;
      if (channel != null) {
        for (final group in groups) {
          final groupId = group['id'] ?? '';
          if (channel.userGroups.contains(groupId)) {
            final name = group['name'] ?? '';
            final handle = group['handle'] ?? '';
            if (query.isEmpty ||
                name.toLowerCase().contains(query) ||
                handle.toLowerCase().contains(query)) {
              items.add({
                'id': groupId,
                'name': name,
                'handle': handle,
                'type': 'group',
              });
            }
          }
        }
      }
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limit to 5 items to keep it clean and compact
    final displayItems = items.take(5).toList();

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 180),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];
            final isUser = item['type'] == 'user';
            final name = item['name'] ?? '';
            final handle = item['handle'] ?? '';

            Widget leading;
            if (isUser) {
              final photoUrl = item['photoUrl'] as String? ?? '';
              if (photoUrl.isNotEmpty) {
                leading = CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(photoUrl),
                );
              } else {
                leading = CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
            } else {
              leading = CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(
                  Icons.group_outlined,
                  color: theme.colorScheme.secondary,
                  size: 16,
                ),
              );
            }

            return ListTile(
              dense: true,
              leading: leading,
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('@$handle'),
              onTap: () => _selectMention(handle),
            );
          },
        ),
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

    final messagesAsync = isChannel
        ? ref.watch(channelMessagesStreamProvider(activeId))
        : ref.watch(dmMessagesStreamProvider(activeId));
    final workspaceId = ref.watch(currentWorkspaceIdProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
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
              data: (ascendingMessages) {
                final messages = ascendingMessages.reversed.toList();
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
                    final bool isLastOfBlock = index - 1 < 0 ||
                        messages[index - 1].senderId != message.senderId;
 
                    return MessageRow(
                      message: message,
                      showSenderInfo: showSenderInfo,
                      isLastOfBlock: isLastOfBlock,
                      onQuote: (msg) {
                        setState(() {
                          _quotedMessage = msg;
                        });
                        _inputFocusNode.requestFocus();
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
                        setState(() {
                          _editingMessage = msg;
                          _quotedMessage = null;
                          _controller.text = msg.content;
                        });
                        _inputFocusNode.requestFocus();
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_quotedMessage != null)
                      _buildQuotePreview(theme),
                    if (_editingMessage != null)
                      _buildEditPreview(theme),
                    if (_showMentionPopup && workspaceId != null)
                      _buildMentionPopup(context, theme, workspaceId),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
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
                                      _handleSubmit();
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
                                  hintText: _editingMessage != null
                                      ? 'Edit your message...'
                                      : 'Type your message here...',
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
                            onPressed: _handleSubmit,
                            icon: Icon(
                              _editingMessage != null
                                  ? Icons.check
                                  : HugeIconsStroke.sent,
                            ),
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
  final bool isLastOfBlock;
  final Function(MessageModel message) onQuote;
  final Function(MessageModel message) onStartThread;
  final Function(MessageModel message) onEdit;
  final Function(MessageModel message) onDelete;
  final VoidCallback onShowMenu;

  const MessageRow({
    super.key,
    required this.message,
    required this.showSenderInfo,
    required this.isLastOfBlock,
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
    final bool showStartDM = isChannel && widget.message.senderId != currentUserId;

    int itemCount = 2; // Quote and Thread
    if (isSender) itemCount++;
    if (canDelete) itemCount++;
    if (showStartDM) itemCount++;

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
                          widget.onQuote(widget.message);
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
                      if (showStartDM)
                        _buildOverlayItem(
                          icon: Icons.chat_bubble_outline,
                          text: 'Start DM',
                          onTap: () async {
                            _hidePopupMenu();
                            final workspaceId = ref.read(currentWorkspaceIdProvider) ?? '';
                            if (workspaceId.isNotEmpty && currentUserId.isNotEmpty) {
                              try {
                                final repo = ref.read(chatRepositoryProvider);
                                final dmId = await repo.initializeDM(
                                  workspaceId: workspaceId,
                                  currentUserId: currentUserId,
                                  targetUserId: widget.message.senderId,
                                );
                                ref.read(navIndexProvider.notifier).state = 0; // Navigates to DMs section
                                ref.read(activeChatSessionProvider.notifier).state = ActiveChatSession(
                                  chatId: dmId,
                                  type: ChatSessionType.dm,
                                );
                                ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to start conversation: $e'),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            }
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
        final displayName = user?.displayName ?? 'Altr Member';
        final photoUrl = user?.photoUrl ?? '';

        final bubbleMode = ref.watch(bubbleModeProvider);

        if (bubbleMode) {
          return _buildBubbleLayout(context, displayName, photoUrl, theme);
        } else {
          return _buildStandardLayout(context, displayName, photoUrl, theme);
        }
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: SizedBox(height: 36),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildStandardLayout(
    BuildContext context,
    String displayName,
    String photoUrl,
    ThemeData theme,
  ) {
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
          padding: EdgeInsets.only(
            top: widget.showSenderInfo ? 8.0 : 1.0,
            bottom: widget.isLastOfBlock ? 8.0 : 1.0,
            left: 16.0,
            right: 16.0,
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
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.message.isEdited) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(edited)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                                fontSize: 10,
                              ),
                            ),
                          ],
                          const Spacer(),
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
                    if (widget.message.quotedMessageContent != null) ...[
                      _buildQuotedMessageBubble(
                        theme,
                        bubbleMode: false,
                        isCurrentUser: widget.message.senderId == ref.read(authStateProvider).value?.uid,
                      ),
                      const SizedBox(height: 6),
                    ],
                    MentionText(
                      content: widget.message.content,
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
  }

  Widget _buildBubbleLayout(
    BuildContext context,
    String displayName,
    String photoUrl,
    ThemeData theme,
  ) {
    final currentUserId = ref.read(authStateProvider).value?.uid ?? '';
    final bool isCurrentUser = widget.message.senderId == currentUserId;

    return Padding(
      padding: EdgeInsets.only(
        top: widget.showSenderInfo ? 6.0 : 1.0,
        bottom: widget.isLastOfBlock ? 6.0 : 1.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            if (widget.showSenderInfo)
              _buildAvatar(displayName, photoUrl, theme)
            else
              const SizedBox(width: 36),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: (MediaQuery.of(context).size.width * 0.7).clamp(0.0, 600.0),
                ),
                 decoration: BoxDecoration(
                  color: isCurrentUser
                      ? theme.colorScheme.primary.withAlpha(20)
                      : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(
                      isCurrentUser
                          ? 12
                          : (widget.isLastOfBlock ? 0 : 12),
                    ),
                    bottomRight: Radius.circular(
                      isCurrentUser
                          ? (widget.isLastOfBlock ? 0 : 12)
                          : 12,
                    ),
                  ),
                  border: Border.all(
                    color: isCurrentUser
                        ? theme.colorScheme.primary.withAlpha(35)
                        : theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
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
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(
                      isCurrentUser
                          ? 12
                          : (widget.isLastOfBlock ? 0 : 12),
                    ),
                    bottomRight: Radius.circular(
                      isCurrentUser
                          ? (widget.isLastOfBlock ? 0 : 12)
                          : 12,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCurrentUser && widget.showSenderInfo) ...[
                          Text(
                            displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (widget.message.quotedMessageContent != null) ...[
                          _buildQuotedMessageBubble(
                            theme,
                            bubbleMode: true,
                            isCurrentUser: isCurrentUser,
                          ),
                          const SizedBox(height: 6),
                        ],
                        MentionText(
                          content: widget.message.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(220),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimestamp(widget.message.timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                                fontSize: 9,
                              ),
                            ),
                            if (widget.message.isEdited) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(edited)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotedMessageBubble(
    ThemeData theme, {
    required bool bubbleMode,
    required bool isCurrentUser,
  }) {
    final Color quoteBgColor;
    if (bubbleMode) {
      if (isCurrentUser) {
        quoteBgColor = theme.colorScheme.surfaceContainerHigh;
      } else {
        quoteBgColor = theme.colorScheme.primary.withAlpha(40);
      }
    } else {
      quoteBgColor = theme.colorScheme.surfaceContainerHigh;
    }

    return Container(
      decoration: BoxDecoration(
        color: quoteBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message.quotedMessageSenderName ?? '',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            widget.message.quotedMessageContent ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

class MentionText extends ConsumerWidget {
  final String content;
  final TextStyle? style;

  const MentionText({
    super.key,
    required this.content,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(currentWorkspaceIdProvider) ?? '';
    if (workspaceId.isEmpty) {
      return Text(content, style: style);
    }

    final workspaceMembersAsync = ref.watch(workspaceMembersStreamProvider(workspaceId));
    final userGroupsAsync = ref.watch(workspaceUserGroupsProvider(workspaceId));

    if (!workspaceMembersAsync.hasValue || !userGroupsAsync.hasValue) {
      return Text(content, style: style);
    }

    final members = workspaceMembersAsync.value ?? [];
    final groups = userGroupsAsync.value ?? [];

    final activeChatSession = ref.watch(activeChatSessionProvider);
    ChannelModel? activeChannel;
    if (activeChatSession.type == ChatSessionType.channel && activeChatSession.chatId != null) {
      activeChannel = ref.watch(activeChannelProvider(activeChatSession.chatId!)).value;
    }

    final theme = Theme.of(context);
    final textStyle = style ?? theme.textTheme.bodyMedium;

    final regex = RegExp(r'@([\w\-]+)');
    final matches = regex.allMatches(content);

    if (matches.isEmpty) {
      return Text(content, style: style);
    }

    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
          style: textStyle,
        ));
      }

      final handle = match.group(1)?.toLowerCase() ?? '';
      final mentionText = match.group(0) ?? '';

      AltrUser? user;
      for (final u in members) {
        if (u.userName.toLowerCase() == handle) {
          user = u;
          break;
        }
      }

      Map<String, dynamic>? group;
      for (final g in groups) {
        if ((g['handle'] ?? '').toString().toLowerCase() == handle) {
          group = g;
          break;
        }
      }

      final targetUser = user;
      final targetGroup = group;

      if (targetUser != null) {
        final displayName = targetUser.displayName.isNotEmpty ? targetUser.displayName : targetUser.userName;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () {
                ref.read(profileTargetUserIdProvider.notifier).state = targetUser.userId;
                ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.profile;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayName,
                  style: textStyle?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (targetGroup != null && activeChannel != null && activeChannel.userGroups.contains(targetGroup['id'])) {
        final groupName = targetGroup['name']?.toString() ?? mentionText;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () {
                ref.read(userGroupTargetIdProvider.notifier).state = targetGroup['id'];
                ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.userGroupInfo;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  groupName,
                  style: textStyle?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(
          text: mentionText,
          style: textStyle,
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: textStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
