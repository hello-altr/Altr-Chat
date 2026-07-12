// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers & Models
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/models/channel_model.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/repositories/chat_repository.dart';

// Widgets
import 'package:chat/widgets/action_button.dart';
import 'package:chat/widgets/section_header.dart';

// Enums
import 'package:chat/enums/layout_mode.dart';

class ChannelInfoPanel extends ConsumerStatefulWidget {
  const ChannelInfoPanel({super.key});

  @override
  ConsumerState<ChannelInfoPanel> createState() => _ChannelInfoPanelState();
}

class _ChannelInfoPanelState extends ConsumerState<ChannelInfoPanel> {
  late TextEditingController _nameController;
  bool _isSavingName = false;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateChannelName(String workspaceId, String channelId) async {
    final rawInput = _nameController.text.trim();
    if (rawInput.isEmpty) return;

    // Sanitization: strip spaces, parse lowercase, maintain # symbol prefix cleanly
    final cleanInput = '#${rawInput.replaceAll(' ', '').toLowerCase().replaceAll('#', '')}';
    final displayName = cleanInput.replaceAll('#', '');

    setState(() {
      _isSavingName = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('channels')
          .doc(channelId)
          .update({
            'channel_name': cleanInput,
            'name': displayName,
          });

      if (mounted) {
        setState(() {
          _isEditingName = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Channel name updated successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update channel name: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingName = false;
        });
      }
    }
  }

  Future<void> _promoteMemberToManager(String workspaceId, String userId, String displayName) async {
    try {
      await FirebaseFirestore.instance.collection('workspaces').doc(workspaceId).update({
        'managers': FieldValue.arrayUnion([userId])
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promoted $displayName to Workspace Manager.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to promote user: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeMemberFromChannel(String workspaceId, String channelId, String userId, String displayName) async {
    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('channels')
          .doc(channelId)
          .update({
            'members': FieldValue.arrayRemove([userId])
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $displayName from channel.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove user: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _archiveChannel(String workspaceId, String channelId) async {
    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('channels')
          .doc(channelId)
          .update({
            'is_archived': true,
          });

      if (!mounted) return;

      // Close settings panel overlay
      ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;

      // Find fallback channel (e.g. #general) and navigate
      final channelsAsync = ref.read(channelsStreamProvider(workspaceId));
      final channels = channelsAsync.value ?? [];
      final fallback = channels.firstWhere(
        (c) => c.name.toLowerCase() == 'general' && !c.isArchived && c.id != channelId,
        orElse: () => channels.firstWhere((c) => !c.isArchived && c.id != channelId, orElse: () => channels.first),
      );

      ref.read(activeChatSessionProvider.notifier).state = ActiveChatSession(
        chatId: fallback.id,
        type: ChatSessionType.channel,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Channel archived successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to archive channel: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showArchiveConfirmDialog(String workspaceId, String channelId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Channel?'),
        content: Text('Are you sure you want to archive #$name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _archiveChannel(workspaceId, channelId);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(String workspaceId, ChannelModel channel) {
    final isMobile = ref.read(layoutProvider) == LayoutMode.mobile;
    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => MobileAddMemberPage(
            workspaceId: workspaceId,
            channel: channel,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AddMemberDialog(
            workspaceId: workspaceId,
            channel: channel,
          );
        },
      );
    }
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

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;

    final workspace = ref.watch(currentWorkspaceProvider);
    final workspaceId = ref.watch(currentWorkspaceIdProvider) ?? '';
    final activeChatSession = ref.watch(activeChatSessionProvider);
    final channelId = activeChatSession.chatId ?? '';

    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

    if (channelId.isEmpty) {
      return const Center(child: Text('No active channel selected.'));
    }

    final channelAsync = ref.watch(activeChannelProvider(channelId));

    if (channelAsync.value == null || workspace == null || workspaceId.isEmpty) {
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
          title: const Text('Channel Details'),
          actions: [
            if (!isMobile)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
                },
              ),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final channel = channelAsync.value!;

    // Access Context Rule Check
    final isCreator = channel.createdBy == currentUserId;
    final workspaceCreator = workspace['created_by'] ?? '';
    final managers = List<String>.from(workspace['managers'] ?? []);
    final isWorkspaceAdmin = currentUserId == workspaceCreator || managers.contains(currentUserId);
    final isAuthorized = isCreator || isWorkspaceAdmin;

    // Initialize text field value once when data loads
    if (_nameController.text.isEmpty && !_isSavingName && !_isEditingName) {
      _nameController.text = channel.name;
    }

    final membersAsync = ref.watch(workspaceMembersStreamProvider(workspaceId));

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
          title: const Text(
            'Channel Info',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
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
          backgroundColor: Colors.transparent,
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
                    // Centered Channel Avatar Icon
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withAlpha(40),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              HugeIconsStroke.hashtag,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!_isEditingName) ...[
                            Text(
                              '#${channel.name}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              channel.isPrivate ? 'private channel' : 'public channel',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: TextField(
                                controller: _nameController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  labelText: 'Channel Name',
                                  prefixText: '# ',
                                  prefixStyle: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  suffixIcon: _isSavingName
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 20),
                                              onPressed: () => _updateChannelName(workspaceId, channel.id),
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: Icon(Icons.close, color: Theme.of(context).colorScheme.primary, size: 20),
                                              onPressed: () {
                                                setState(() {
                                                  _isEditingName = false;
                                                  _nameController.text = channel.name;
                                                });
                                              },
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions Row
                    if (isAuthorized) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ActionButton(
                              icon: _isEditingName ? HugeIconsStroke.checkmarkCircle01 : HugeIconsStroke.edit01,
                              label: _isEditingName ? 'Save' : 'Edit Name',
                              onTap: () {
                                if (_isEditingName) {
                                  _updateChannelName(workspaceId, channel.id);
                                } else {
                                  setState(() {
                                    _isEditingName = true;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ActionButton(
                              icon: Icons.person_add_outlined,
                              label: 'Add Member',
                              onTap: () => _showAddMemberDialog(workspaceId, channel),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ActionButton(
                              icon: HugeIconsStroke.archive02,
                              label: 'Archive',
                              onTap: () => _showArchiveConfirmDialog(workspaceId, channel.id, channel.name),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],                    // Channel participants section
                    const SectionHeader(title: 'channel participants'),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHigh,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: membersAsync.when(
                          data: (users) {
                            final channelUsers = users.where((u) => channel.members.contains(u.userId)).toList();

                            final channelOwner = channelUsers.where((u) => u.userId == channel.createdBy).toList();
                            final otherManagers = channelUsers.where((u) =>
                                (managers.contains(u.userId) || u.userId == workspaceCreator) &&
                                u.userId != channel.createdBy).toList();
                            final regularMembers = channelUsers.where((u) =>
                                u.userId != channel.createdBy &&
                                !managers.contains(u.userId) &&
                                u.userId != workspaceCreator).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (channelOwner.isNotEmpty) ...[
                                  _buildRoleSectionHeader(theme, 'Channel Owner'),
                                  ...channelOwner.map((u) => _buildParticipantRow(theme, u, workspaceId, channel.id, isAuthorized, currentUserId, true, false)),
                                  const SizedBox(height: 12),
                                ],
                                if (otherManagers.isNotEmpty) ...[
                                  _buildRoleSectionHeader(theme, 'Workspace Managers'),
                                  ...otherManagers.map((u) => _buildParticipantRow(theme, u, workspaceId, channel.id, isAuthorized, currentUserId, false, true)),
                                  const SizedBox(height: 12),
                                ],
                                if (regularMembers.isNotEmpty) ...[
                                  _buildRoleSectionHeader(theme, 'Members'),
                                  ...regularMembers.map((u) => _buildParticipantRow(theme, u, workspaceId, channel.id, isAuthorized, currentUserId, false, false)),
                                ],
                              ],
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Text('Error loading participants: $err'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const Divider(height: 8),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(
    ThemeData theme,
    AltrUser user,
    String workspaceId,
    String channelId,
    bool currentIsAuthorized,
    String currentUserId,
    bool isOwner,
    bool isManager,
  ) {
    final displayName = user.displayName;
    final photoUrl = user.photoUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          photoUrl.isNotEmpty
              ? CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(photoUrl),
                )
              : CircleAvatar(
                  radius: 16,
                  backgroundColor: _getInitialsBgColor(displayName),
                  child: Text(
                    _getInitials(displayName),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${user.userName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (currentIsAuthorized && user.userId != currentUserId) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (action) {
                if (action == 'promote') {
                  _promoteMemberToManager(workspaceId, user.userId, displayName);
                } else if (action == 'remove') {
                  _removeMemberFromChannel(workspaceId, channelId, user.userId, displayName);
                }
              },
              itemBuilder: (ctx) => [
                if (!isManager && !isOwner)
                  const PopupMenuItem(
                    value: 'promote',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Promote to Manager'),
                      ],
                    ),
                  ),
                if (!isOwner)
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove_outlined, color: theme.colorScheme.error, size: 18),
                        const SizedBox(width: 8),
                        Text('Remove from Channel', style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AddMemberDialog extends ConsumerWidget {
  final String workspaceId;
  final ChannelModel channel;

  const AddMemberDialog({
    super.key,
    required this.workspaceId,
    required this.channel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(workspaceMembersStreamProvider(workspaceId));

    return AlertDialog(
      title: const Text('Add Participant'),
      content: Container(
        width: 400,
        constraints: const BoxConstraints(maxWidth: 400),
        child: membersAsync.when(
          data: (users) {
            // Filter users who are not in the channel
            final nonChannelUsers = users.where((u) => !channel.members.contains(u.userId)).toList();

            if (nonChannelUsers.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'All workspace members are already participants in this channel.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: nonChannelUsers.length,
              itemBuilder: (context, index) {
                final user = nonChannelUsers[index];
                return ListTile(
                  leading: user.photoUrl.isNotEmpty
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(user.photoUrl),
                        )
                      : CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary.withAlpha(40),
                          child: Text(
                            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  title: Text(user.displayName),
                  subtitle: Text('@${user.userName}'),
                  trailing: TextButton(
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('workspaces')
                            .doc(workspaceId)
                            .collection('channels')
                            .doc(channel.id)
                            .update({
                              'members': FieldValue.arrayUnion([user.userId])
                            });

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${user.displayName} to channel.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add member: $e'),
                              backgroundColor: theme.colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Add'),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading workspace members: $err'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class MobileAddMemberPage extends ConsumerWidget {
  final String workspaceId;
  final ChannelModel channel;

  const MobileAddMemberPage({
    super.key,
    required this.workspaceId,
    required this.channel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(workspaceMembersStreamProvider(workspaceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Participant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: membersAsync.when(
          data: (users) {
            // Filter users who are not in the channel
            final nonChannelUsers = users.where((u) => !channel.members.contains(u.userId)).toList();

            if (nonChannelUsers.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'All workspace members are already participants in this channel.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: nonChannelUsers.length,
              itemBuilder: (context, index) {
                final user = nonChannelUsers[index];
                return ListTile(
                  leading: user.photoUrl.isNotEmpty
                      ? CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(user.photoUrl),
                        )
                      : CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary.withAlpha(40),
                          child: Text(
                            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  title: Text(user.displayName),
                  subtitle: Text('@${user.userName}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('workspaces')
                            .doc(workspaceId)
                            .collection('channels')
                            .doc(channel.id)
                            .update({
                              'members': FieldValue.arrayUnion([user.userId])
                            });

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${user.displayName} to channel.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add member: $e'),
                              backgroundColor: theme.colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Add'),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading workspace members: $err')),
        ),
      ),
    );
  }
}
