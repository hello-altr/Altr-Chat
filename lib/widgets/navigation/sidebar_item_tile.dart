// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/providers/chat_session_provider.dart';

// Repositories
import 'package:chat/repositories/chat_repository.dart';

// Enums and Values
import 'package:chat/enums/layout_mode.dart';

class SidebarItemTile extends ConsumerStatefulWidget {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final Widget icon;
  final bool isSelected;
  final DateTime? lastMessageTime;
  final VoidCallback onTap;

  const SidebarItemTile({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.isSelected,
    required this.lastMessageTime,
    required this.onTap,
  });

  @override
  ConsumerState<SidebarItemTile> createState() => _SidebarItemTileState();
}

class _SidebarItemTileState extends ConsumerState<SidebarItemTile> {
  TapDownDetails? _tapDownDetails;
  DateTime? _lastReadTimeLocally;

  Future<bool?> _showWarningDialog({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          constraints: const BoxConstraints(maxWidth: 400),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title),
              ),
            ],
          ),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showPopupMenu(BuildContext context, WidgetRef ref) {
    if (_tapDownDetails == null) return;
    
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        _tapDownDetails!.globalPosition,
        _tapDownDetails!.globalPosition,
      ),
      Offset.zero & overlay.size,
    );

    final isChannel = widget.title.startsWith('#');
    final activeWorkspaceId = ref.read(currentWorkspaceIdProvider) ?? '';
    final theme = Theme.of(context);

    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          value: 'info',
          child: Row(
            children: const [
              Icon(Icons.info_outline, size: 20),
              SizedBox(width: 12),
              Text('Get Info'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.delete_sweep_outlined, size: 20, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Text('Clear History', style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_forever_outlined, size: 20, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Text('Delete Chat', style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
        ),
      ],
    ).then((value) async {
      if (!context.mounted || value == null) return;
      
      final repo = ref.read(chatRepositoryProvider);

      if (value == 'info') {
        if (isChannel) {
          // Do nothing on info, or open info panel if needed.
        } else {
          final currentUserId = ref.read(authStateProvider).value?.uid ?? '';
          final parts = widget.id.split('_');
          final counterpartId = parts.firstWhere(
            (uid) => uid != currentUserId,
            orElse: () => currentUserId,
          );
          ref.read(profileTargetUserIdProvider.notifier).state = counterpartId;
          ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.profile;
        }
      } else if (value == 'clear') {
        final confirm = await _showWarningDialog(
          context: context,
          title: 'Clear Chat History',
          content: 'Are you sure you want to clear the chat history for "${widget.title}"? This action cannot be undone.',
        );
        if (confirm == true && context.mounted) {
          try {
            await repo.clearChatHistory(
              workspaceId: activeWorkspaceId,
              id: widget.id,
              isChannel: isChannel,
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      } else if (value == 'delete') {
        final confirm = await _showWarningDialog(
          context: context,
          title: 'Delete Chat',
          content: 'Are you sure you want to permanently delete the chat "${widget.title}"? This action cannot be undone.',
        );
        if (confirm == true && context.mounted) {
          try {
            // Deselect the active chat if it was deleted
            final chatSession = ref.read(activeChatSessionProvider);
            if (chatSession.chatId == widget.id) {
              ref.read(activeChatSessionProvider.notifier).state = const ActiveChatSession();
            }

            await repo.deleteChat(
              workspaceId: activeWorkspaceId,
              id: widget.id,
              isChannel: isChannel,
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layoutMode = ref.watch(layoutProvider);
    final isDesktop = layoutMode == LayoutMode.desktop;
    final activeWorkspaceId = ref.watch(currentWorkspaceIdProvider) ?? '';
    
    if (widget.isSelected) {
      _lastReadTimeLocally = DateTime.now();
    }

    final isChannel = widget.title.startsWith('#');
    final unreadCountAsync = ref.watch(unreadCountStreamProvider(
      UnreadCountArgs(chatId: widget.id, isChannel: isChannel),
    ));
    
    int unreadCount = unreadCountAsync.value ?? 0;
    if (widget.isSelected) {
      unreadCount = 0;
    } else if (_lastReadTimeLocally != null && widget.lastMessageTime != null) {
      if (!widget.lastMessageTime!.isAfter(_lastReadTimeLocally!)) {
        unreadCount = 0;
      }
    }
    final bool isUnread = unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          _tapDownDetails = details;
        },
        onSecondaryTapDown: (details) {
          _tapDownDetails = details;
        },
        onSecondaryTap: () {
          _showPopupMenu(context, ref);
        },
        child: InkWell(
          onTap: () {
            _lastReadTimeLocally = DateTime.now();
            // Banish badge immediately in Firestore
            final authUser = ref.read(authStateProvider).value;
            if (authUser != null && activeWorkspaceId.isNotEmpty) {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(authUser.uid)
                  .collection('workspace_meta')
                  .doc(activeWorkspaceId)
                  .set({
                    'last_read_timestamps': {
                      widget.id: FieldValue.serverTimestamp(),
                    }
                  }, SetOptions(merge: true));
            }
            
            widget.onTap();
          },
          onLongPress: () {
            _showPopupMenu(context, ref);
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: widget.isSelected && isDesktop
                  ? theme.colorScheme.primaryContainer.withAlpha(150)
                  : Colors.transparent,
              border: Border.all(
                color: widget.isSelected && isDesktop
                    ? theme.colorScheme.primary.withAlpha(80)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lead Icon
                widget.icon,
                const SizedBox(width: 12),
                
                // Title and Subtitle Info block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: widget.isSelected && isDesktop
                                    ? FontWeight.bold
                                    : (isUnread ? FontWeight.bold : FontWeight.w600),
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                          fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Time stamp and unread count badge details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
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
    );
  }
}

class UnreadCountArgs {
  final String chatId;
  final bool isChannel;
  const UnreadCountArgs({required this.chatId, required this.isChannel});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnreadCountArgs &&
          runtimeType == other.runtimeType &&
          chatId == other.chatId &&
          isChannel == other.isChannel;

  @override
  int get hashCode => chatId.hashCode ^ isChannel.hashCode;
}

final unreadCountStreamProvider = StreamProvider.family<int, UnreadCountArgs>((ref, args) {
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  if (workspaceId == null) return Stream.value(0);

  final metaAsync = ref.watch(workspaceMetaProvider(workspaceId));
  return metaAsync.when(
    data: (metaData) {
      final lastReadTimestamps = metaData?['last_read_timestamps'] as Map<String, dynamic>? ?? {};
      final lastReadVal = lastReadTimestamps[args.chatId];

      var query = FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection(args.isChannel ? 'channels' : 'dms')
          .doc(args.chatId)
          .collection('messages');

      Query finalQuery = query;
      if (lastReadVal != null && lastReadVal is Timestamp) {
        finalQuery = query.where('timestamp', isGreaterThan: lastReadVal);
      }

      return finalQuery.snapshots().map((snapshot) => snapshot.docs.length);
    },
    loading: () => Stream.value(0),
    error: (err, stack) => Stream.value(0),
  );
});
