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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Channel Info: ${widget.title}')),
          );
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chat history cleared.')),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chat deleted.')),
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
    
    // Wire up activity tracking badges
    final metaAsync = ref.watch(workspaceMetaProvider(activeWorkspaceId));
    
    bool isUnread = false;
    if (widget.lastMessageTime != null && !widget.isSelected) {
      final metaData = metaAsync.value;
      final lastReadTimestamps = metaData?['last_read_timestamps'] as Map<String, dynamic>? ?? {};
      final lastReadVal = lastReadTimestamps[widget.id];
      
      if (lastReadVal == null) {
        isUnread = true;
      } else if (lastReadVal is Timestamp) {
        final lastReadDateTime = lastReadVal.toDate();
        isUnread = widget.lastMessageTime!.isAfter(lastReadDateTime);
      }
    }

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
                          // High-density unread indicator element (color badge mark dot) right adjacent to the label
                          if (isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
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
                
                // Time stamp details
                Text(
                  widget.time,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
