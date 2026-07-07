import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/enums/layout_mode.dart';
import 'package:chat/repositories/chat_repository.dart';

class SidebarItemTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final layoutMode = ref.watch(layoutProvider);
    final isDesktop = layoutMode == LayoutMode.desktop;
    
    final activeWorkspaceId = ref.watch(currentWorkspaceIdProvider) ?? '';
    
    // Wire up activity tracking badges
    final metaAsync = ref.watch(workspaceMetaProvider(activeWorkspaceId));
    
    bool isUnread = false;
    if (lastMessageTime != null && !isSelected) {
      final metaData = metaAsync.value;
      final lastReadTimestamps = metaData?['last_read_timestamps'] as Map<String, dynamic>? ?? {};
      final lastReadVal = lastReadTimestamps[id];
      
      if (lastReadVal == null) {
        isUnread = true;
      } else if (lastReadVal is Timestamp) {
        final lastReadDateTime = lastReadVal.toDate();
        isUnread = lastMessageTime!.isAfter(lastReadDateTime);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
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
                    id: FieldValue.serverTimestamp(),
                  }
                }, SetOptions(merge: true));
          }
          
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected && isDesktop
                ? theme.colorScheme.primaryContainer.withAlpha(150)
                : Colors.transparent,
            border: Border.all(
              color: isSelected && isDesktop
                  ? theme.colorScheme.primary.withAlpha(80)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // Lead Icon
              icon,
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
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isSelected && isDesktop
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
                      subtitle,
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
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
