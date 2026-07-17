// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/enums/layout_mode.dart';

// Widgets
import 'package:chat/widgets/chat/chat_feed_canvas.dart';
import 'package:chat/widgets/section_header.dart';
import 'package:chat/widgets/action_button.dart';
import 'package:chat/widgets/details_row.dart';

// Enums

class UserGroupInfoPanel extends ConsumerStatefulWidget {
  const UserGroupInfoPanel({super.key});

  @override
  ConsumerState<UserGroupInfoPanel> createState() => _UserGroupInfoPanelState();
}

class _UserGroupInfoPanelState extends ConsumerState<UserGroupInfoPanel> {
  Color _getInitialsBgColor(String name) {
    final colors = [
      const Color(0xFFF43F5E),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    return colors[name.hashCode % colors.length];
  }

  Future<void> _promoteGroup(BuildContext context, String workspaceId, Map<String, dynamic> group) async {
    final theme = Theme.of(context);
    final isCurrentlyPromoted = group['is_promoted'] == true;
    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('user_groups')
          .doc(group['id'])
          .update({'is_promoted': !isCurrentlyPromoted});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update group: $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteGroup(BuildContext context, String workspaceId, String groupId, String name) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User Group'),
        content: Text('Are you sure you want to delete the user group "$name"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('workspaces')
            .doc(workspaceId)
            .collection('user_groups')
            .doc(groupId)
            .delete();

        ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete group: $e'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _addUserToGroup(BuildContext context, String workspaceId, Map<String, dynamic> group, List<String> workspaceMembers) async {
    final theme = Theme.of(context);
    final groupMembers = List<String>.from(group['members'] ?? []);
    final addableMembers = workspaceMembers.where((id) => !groupMembers.contains(id)).toList();

    if (addableMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All workspace members are already in this group!'),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add User to Group'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('user_id', whereIn: addableMembers)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final users = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    final userId = userData['user_id'] ?? '';
                    final displayName = userData['display_name'] ?? 'Aero User';
                    final handle = userData['user_name'] ?? 'user';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getInitialsBgColor(displayName),
                        child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: Text(
                        '@$handle',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      onTap: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('workspaces')
                              .doc(workspaceId)
                              .collection('user_groups')
                              .doc(group['id'])
                              .update({
                            'members': FieldValue.arrayUnion([userId])
                          });

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add user: $e'),
                                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupId = ref.watch(userGroupTargetIdProvider);
    final workspace = ref.watch(currentWorkspaceProvider);
    final workspaceId = workspace?['id'] ?? '';
    final creatorId = workspace?['created_by'] ?? '';
    final managers = List<String>.from(workspace?['managers'] ?? []);
    final workspaceMembers = List<String>.from(workspace?['members'] ?? []);
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final isAdmin = currentUserId == creatorId;
    final isManager = managers.contains(currentUserId) || isAdmin;
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;

    if (groupId == null || workspaceId.isEmpty) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: isMobile
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () {
                      ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
                    },
                  )
                : null,
            title: const Text('User Group Details'),
          ),
          body: const Center(child: Text('No group selected.')),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workspaces')
            .doc(workspaceId)
            .collection('user_groups')
            .doc(groupId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: isMobile
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () {
                          ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
                        },
                      )
                    : null,
              ),
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final groupDoc = snapshot.data!;
          if (!groupDoc.exists) {
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: isMobile
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () {
                          ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
                        },
                      )
                    : null,
              ),
              body: const Center(child: Text('User Group not found.')),
            );
          }

          final groupData = groupDoc.data() as Map<String, dynamic>;
          final name = groupData['name'] ?? 'Unnamed Group';
          final handle = groupData['handle'] ?? 'group';
          final isPromoted = groupData['is_promoted'] == true;
          final members = List<String>.from(groupData['members'] ?? []);

          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: isMobile
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () {
                        ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
                      },
                    )
                  : null,
              title: const Text(
                'User Group Details',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                if (!isMobile)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
                    },
                  ),
              ],
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              elevation: 0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.only(
                      top: 24.0,
                      bottom: 90,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primaryContainer,
                                ),
                                child: Icon(
                                  HugeIconsStroke.userGroup,
                                  color: theme.colorScheme.primary,
                                  size: 44,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  if (isPromoted) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Manager',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: theme.colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@$handle',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick Actions Row
                        Builder(builder: (context) {
                          final userGroups = ref.watch(workspaceUserGroupsProvider(workspaceId)).value ?? [];
                          bool isManagerFromAnotherGroup = false;
                          for (final g in userGroups) {
                            if (g['id'] == groupId) continue;
                            if (g['is_promoted'] == true) {
                              final membersList = List<String>.from(g['members'] ?? []);
                              if (membersList.contains(currentUserId)) {
                                isManagerFromAnotherGroup = true;
                                break;
                              }
                            }
                          }

                          if (isManager || isManagerFromAnotherGroup) {
                            return Column(children: [
                              Row(
                                children: [
                                  if (isManager) ...[
                                    Expanded(
                                      child: ActionButton(
                                        icon: Icons.person_add_alt_1_outlined,
                                        label: 'Add Member',
                                        onTap: () {
                                          _addUserToGroup(context, workspaceId, groupData, workspaceMembers);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: ActionButton(
                                      icon: isPromoted ? Icons.shield_outlined : Icons.shield,
                                      label: isPromoted ? 'Demote' : 'Promote',
                                      onTap: () {
                                        _promoteGroup(context, workspaceId, groupData);
                                      },
                                    ),
                                  ),
                                  if (isManager) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ActionButton(
                                        icon: Icons.delete_outline,
                                        label: 'Delete Group',
                                        onTap: () {
                                          _deleteGroup(context, workspaceId, groupId, name);
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 24),
                            ]);
                          }
                          return const SizedBox.shrink();
                        }),

                        // Group Details Card
                        const SectionHeader(title: 'Group Details', fontSize: 11.0),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withAlpha(80),
                            ),
                          ),
                          child: Column(
                            children: [
                              DetailsRow(
                                icon: Icons.people_outline,
                                label: 'Total Members',
                                value: '${members.length} members',
                              ),
                              Divider(
                                height: 24,
                                color: theme.colorScheme.outlineVariant.withAlpha(80),
                              ),
                              DetailsRow(
                                icon: Icons.shield_outlined,
                                label: 'Group Role',
                                value: isPromoted ? 'Manager Group' : 'Standard Group',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Group Members List at the bottom
                        const SectionHeader(title: 'Group Members', fontSize: 11.0),
                        const SizedBox(height: 8),
                        if (members.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            child: Text(
                              'No members in this group yet.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                              ),
                            ),
                          )
                        else
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .where('user_id', whereIn: members)
                                .snapshots(),
                            builder: (context, memberSnapshot) {
                              if (memberSnapshot.hasError) return Text('Error: ${memberSnapshot.error}');
                              if (!memberSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                              final users = memberSnapshot.data!.docs;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final userData = users[index].data() as Map<String, dynamic>;
                                  final memberId = userData['user_id'] ?? '';
                                  final memberName = userData['display_name'] ?? 'Aero User';
                                  final memberHandle = userData['user_name'] ?? 'user';
                                  final memberPhoto = userData['photo_url'] as String?;

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: memberPhoto == null || memberPhoto.isEmpty
                                          ? _getInitialsBgColor(memberName)
                                          : null,
                                      backgroundImage: memberPhoto != null && memberPhoto.isNotEmpty
                                          ? NetworkImage(memberPhoto)
                                          : null,
                                      child: memberPhoto == null || memberPhoto.isEmpty
                                          ? Text(
                                              memberName.isNotEmpty ? memberName[0].toUpperCase() : 'M',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      memberName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      '@$memberHandle',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    onTap: () {
                                      ref.read(profileTargetUserIdProvider.notifier).state = memberId;
                                      ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.profile;
                                    },
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
