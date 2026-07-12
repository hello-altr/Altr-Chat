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

  Future<void> _promoteMemberToManager(String workspaceId, String channelId, String userId, String displayName) async {
    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('channels')
          .doc(channelId)
          .update({
        'managers': FieldValue.arrayUnion([userId])
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promoted $displayName to Channel Manager.'),
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ResponsiveAddMemberRoute(
          workspaceId: workspaceId,
          channel: channel,
        );
      },
    );
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
    final isWorkspaceOwner = currentUserId == workspaceCreator;
    final isChannelManager = channel.managers.contains(currentUserId);
    final isAuthorized = isCreator || isWorkspaceOwner || isChannelManager;

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
                            child: Icon(
                              channel.isPrivate ? HugeIconsStroke.lock : HugeIconsStroke.hashtag,
                              color: theme.colorScheme.onPrimary,
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
                          if (channel.isPrivate) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: ActionButton(
                                icon: Icons.person_add_outlined,
                                label: 'Add Member',
                                onTap: () => _showAddMemberDialog(workspaceId, channel),
                              ),
                            ),
                          ],
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
                            final channelUsers = channel.isPrivate
                                ? users.where((u) => channel.members.contains(u.userId)).toList()
                                : users;

                            final channelOwner = channelUsers.where((u) => u.userId == channel.createdBy).toList();
                            final otherManagers = channelUsers.where((u) =>
                                channel.managers.contains(u.userId) &&
                                u.userId != channel.createdBy).toList();
                            final regularMembers = channelUsers.where((u) =>
                                u.userId != channel.createdBy &&
                                !channel.managers.contains(u.userId)).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (channelOwner.isNotEmpty) ...[
                                  _buildRoleSectionHeader(theme, 'Channel Owner'),
                                  ...channelOwner.map((u) => _buildParticipantRow(theme, u, workspaceId, channel.id, isAuthorized, currentUserId, true, false, channel.isPrivate)),
                                  const SizedBox(height: 12),
                                ],
                                if (otherManagers.isNotEmpty) ...[
                                  _buildRoleSectionHeader(theme, 'Channel Managers'),
                                  ...otherManagers.map((u) => _buildParticipantRow(theme, u, workspaceId, channel.id, isAuthorized, currentUserId, false, true, channel.isPrivate)),
                                  const SizedBox(height: 12),
                                ],
                                if (regularMembers.isNotEmpty) ...[
                                  _buildRoleSectionHeader(theme, 'Members'),
                                  ...regularMembers.map((u) => _buildParticipantRow(theme, u, workspaceId, channel.id, isAuthorized, currentUserId, false, false, channel.isPrivate)),
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
    bool isChannelPrivate,
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
                  _promoteMemberToManager(workspaceId, channelId, user.userId, displayName);
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
                if (!isOwner && isChannelPrivate)
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

class ResponsiveAddMemberRoute extends ConsumerStatefulWidget {
  final String workspaceId;
  final ChannelModel channel;

  const ResponsiveAddMemberRoute({
    super.key,
    required this.workspaceId,
    required this.channel,
  });

  @override
  ConsumerState<ResponsiveAddMemberRoute> createState() => _ResponsiveAddMemberRouteState();
}

class _ResponsiveAddMemberRouteState extends ConsumerState<ResponsiveAddMemberRoute> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedUserIds = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<AltrUser>> membersAsync,
    VoidCallback onClose,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name or @handle...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim().toLowerCase();
            });
          },
        ),
        const SizedBox(height: 12),

        // 2. Horizontal Scrolling Selected Members Chips (Placeholder always stays)
        membersAsync.when(
          data: (users) {
            if (_selectedUserIds.isEmpty) {
              // Placeholder Chip to prevent layout jumping
              return SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh.withAlpha(120),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withAlpha(100),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select participants...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final selectedUsers = users.where((u) => _selectedUserIds.contains(u.userId)).toList();

            return SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = selectedUsers[index];
                  final displayName = user.displayName;
                  final photoUrl = user.photoUrl;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InputChip(
                      avatar: photoUrl.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(photoUrl),
                            )
                          : CircleAvatar(
                              backgroundColor: _getInitialsBgColor(displayName),
                              child: Text(
                                _getInitials(displayName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      label: Text(
                        displayName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedUserIds.remove(user.userId);
                        });
                      },
                      deleteIconColor: theme.colorScheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(height: 42),
          error: (err, stack) => const SizedBox(height: 42),
        ),
        const SizedBox(height: 8),
        const Divider(),

        // 3. Scrollable List of Members
        Expanded(
          child: membersAsync.when(
            data: (users) {
              final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

              // Filter by search query
              final filteredUsers = users.where((u) {
                if (_searchQuery.isEmpty) return true;
                final nameMatch = u.displayName.toLowerCase().contains(_searchQuery);
                final handleMatch = u.userName.toLowerCase().contains(_searchQuery);
                return nameMatch || handleMatch;
              }).toList();

              // Sort: Active (non-channel) users first, joined users / current user last
              filteredUsers.sort((a, b) {
                final aJoined = widget.channel.members.contains(a.userId) || a.userId == currentUserId;
                final bJoined = widget.channel.members.contains(b.userId) || b.userId == currentUserId;
                if (aJoined && !bJoined) return 1;
                if (!aJoined && bJoined) return -1;
                return a.displayName.compareTo(b.displayName);
              });

              if (filteredUsers.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'No workspace members match your selection.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final isJoined = widget.channel.members.contains(user.userId) || user.userId == currentUserId;
                  final isSelected = isJoined || _selectedUserIds.contains(user.userId);
                  final displayName = user.displayName;
                  final photoUrl = user.photoUrl;

                  if (isJoined) {
                    final suffix = user.userId == currentUserId ? ' (You)' : ' (Joined)';
                    return Opacity(
                      opacity: 0.5,
                      child: CheckboxListTile(
                        value: true,
                        onChanged: null,
                        secondary: photoUrl.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(photoUrl),
                              )
                            : CircleAvatar(
                                backgroundColor: _getInitialsBgColor(displayName),
                                child: Text(
                                  _getInitials(displayName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        title: Text(displayName),
                        subtitle: Text('@${user.userName}$suffix'),
                        controlAffinity: ListTileControlAffinity.trailing,
                        contentPadding: EdgeInsets.zero,
                      ),
                    );
                  }

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? val) {
                      setState(() {
                        if (val == true) {
                          _selectedUserIds.add(user.userId);
                        } else {
                          _selectedUserIds.remove(user.userId);
                        }
                      });
                    },
                    secondary: photoUrl.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(photoUrl),
                          )
                        : CircleAvatar(
                            backgroundColor: _getInitialsBgColor(displayName),
                            child: Text(
                              _getInitials(displayName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    title: Text(displayName),
                    subtitle: Text('@${user.userName}'),
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading members: $err')),
          ),
        ),
        const Divider(),

        // 4. Save Buttons Bottom Row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onClose,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSaving || _selectedUserIds.isEmpty
                    ? null
                    : () async {
                        setState(() {
                          _isSaving = true;
                        });
                        try {
                          await FirebaseFirestore.instance
                              .collection('workspaces')
                              .doc(widget.workspaceId)
                              .collection('channels')
                              .doc(widget.channel.id)
                              .update({
                            'members': FieldValue.arrayUnion(_selectedUserIds.toList()),
                          });

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ${_selectedUserIds.length} member(s) to the channel.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            onClose();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add members: $e'),
                                backgroundColor: theme.colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                            });
                          }
                        }
                      },
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Add Selected (${_selectedUserIds.length})'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;
    final membersAsync = ref.watch(workspaceMembersStreamProvider(widget.workspaceId));

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Participant'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildContent(context, theme, membersAsync, () => Navigator.of(context).pop()),
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 450,
        height: 550,
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 550),
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Participant',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(context, theme, membersAsync, () => Navigator.of(context).pop()),
            ),
          ],
        ),
      ),
    );
  }
}
