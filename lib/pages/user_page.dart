import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons_pro/hugeicons.dart';

// Providers & Layout
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/nav_provider.dart';
import 'package:chat/repositories/chat_repository.dart';
import 'package:chat/widgets/action_button.dart';
import 'package:chat/widgets/details_row.dart';
import 'package:chat/widgets/section_header.dart';
import 'package:chat/enums/layout_mode.dart';

class UsersAndGroupsPage extends ConsumerStatefulWidget {
  const UsersAndGroupsPage({super.key});

  @override
  ConsumerState<UsersAndGroupsPage> createState() => _UsersAndGroupsPageState();
}

class UsersAndGroupsPageState extends ConsumerState<UsersAndGroupsPage> {
  late PageController _pageController;
  late TextEditingController _userSearchController;
  late TextEditingController _groupSearchController;
  String _userSearchQuery = '';
  String _groupSearchQuery = '';

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(usersAndGroupsPageIndexProvider);
    _pageController = PageController(initialPage: initialPage);
    _userSearchController = TextEditingController();
    _userSearchController.addListener(() {
      setState(() {
        _userSearchQuery = _userSearchController.text; 
      });
    });
    _groupSearchController = TextEditingController();
    _groupSearchController.addListener(() {
      setState(() {
        _groupSearchQuery = _groupSearchController.text;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _userSearchController.dispose();
    _groupSearchController.dispose();
    super.dispose();
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

  Future<void> _dmUser(BuildContext context, String targetUserId, String targetDisplayName) async {
    final currentUserId = ref.read(authStateProvider).value?.uid ?? '';
    final activeWorkspaceId = ref.read(currentWorkspaceIdProvider);
    final theme = Theme.of(context);

    if (activeWorkspaceId == null || currentUserId.isEmpty) return;

    // Deterministic DM ID
    final dmId = currentUserId.compareTo(targetUserId) < 0
        ? '${currentUserId}_$targetUserId'
        : '${targetUserId}_$currentUserId';

    try {
      final dmRef = FirebaseFirestore.instance
          .collection('workspaces')
          .doc(activeWorkspaceId)
          .collection('dms')
          .doc(dmId);

      final dmDoc = await dmRef.get();
      if (!dmDoc.exists) {
        await dmRef.set({
          'id': dmId,
          'participants': [currentUserId, targetUserId],
          'last_message': 'Conversation started.',
          'last_message_time': FieldValue.serverTimestamp(),
          'unread_count': 0,
        });
      }

      if (mounted) {
        // Exit settings page back to main canvas
        ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
        ref.read(navIndexProvider.notifier).state = 0; // DM section
        ref.read(activeChatSessionProvider.notifier).state = ActiveChatSession(
          chatId: dmId,
          type: ChatSessionType.dm,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening chat with $targetDisplayName...'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeUser(BuildContext context, String workspaceId, String userId, String displayName) async {
    final theme = Theme.of(context);
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Remove user from workspace members
      final workspaceRef = FirebaseFirestore.instance.collection('workspaces').doc(workspaceId);
      batch.update(workspaceRef, {
        'members': FieldValue.arrayRemove([userId])
      });

      // Remove workspace from user's joined list
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      batch.update(userRef, {
        'joined_workspaces': FieldValue.arrayRemove([workspaceId])
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $displayName from workspace.'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove user: $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _promoteUser(BuildContext context, String workspaceId, String userId, String displayName) async {
    final theme = Theme.of(context);
    try {
      final workspaceRef = FirebaseFirestore.instance.collection('workspaces').doc(workspaceId);
      await workspaceRef.update({
        'managers': FieldValue.arrayUnion([userId])
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promoted $displayName to Workspace Manager.'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to promote user: $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _createNewGroup(BuildContext context, String workspaceId) async {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final handleController = TextEditingController();
    final currentUserId = ref.read(authStateProvider).value?.uid ?? '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create User Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g. Engineering Team',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: handleController,
                decoration: const InputDecoration(
                  labelText: 'Group Handle',
                  hintText: 'e.g. engineering',
                  prefixText: '@',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final handle = handleController.text.trim().replaceAll('@', '').toLowerCase();
                if (name.isNotEmpty && handle.isNotEmpty) {
                  try {
                    final groupRef = FirebaseFirestore.instance
                        .collection('workspaces')
                        .doc(workspaceId)
                        .collection('user_groups')
                        .doc();

                    await groupRef.set({
                      'id': groupRef.id,
                      'name': name,
                      'handle': handle,
                      'members': const [],
                      'created_by': currentUserId,
                      'created_at': FieldValue.serverTimestamp(),
                      'is_promoted': false,
                    });

                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('User Group "@$handle" created successfully!'),
                          backgroundColor: theme.colorScheme.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create group: $e'),
                          backgroundColor: theme.colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addUserToGroup(BuildContext context, String workspaceId, Map<String, dynamic> group, List<String> workspaceMembers) async {
    final theme = Theme.of(context);
    final groupMembers = List<String>.from(group['members'] ?? []);
    
    // Find workspace users not already in group
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
                          
                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added $displayName to group.'),
                                backgroundColor: theme.colorScheme.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add user: $e'),
                                backgroundColor: theme.colorScheme.error,
                                behavior: SnackBarBehavior.floating,
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyPromoted ? 'Revoked group promotion.' : 'Promoted user group!'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('user_groups')
          .doc(groupId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted user group "$name".'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  Widget _buildFloatingPill(ThemeData theme, int currentPage) {
    return Center(
      child: Container(
        width: 280,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.onSurface.withAlpha(30),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(usersAndGroupsPageIndexProvider.notifier).state = 0;
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.fastOutSlowIn,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: currentPage == 0
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        currentPage == 0 ? HugeIconsSolid.user : HugeIconsStroke.user,
                        size: 14,
                        color: currentPage == 0
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Users',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentPage == 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(usersAndGroupsPageIndexProvider.notifier).state = 1;
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.fastOutSlowIn,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: currentPage == 1
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        currentPage == 1 ? HugeIconsSolid.userGroup : HugeIconsStroke.userGroup,
                        size: 14,
                        color: currentPage == 1
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Groups',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentPage == 1
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide(
        color: theme.colorScheme.outlineVariant.withAlpha(80),
      ),
    );
    return TextField(
      controller: controller,
      style: theme.textTheme.bodyMedium,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
        ),
        prefixIcon: Icon(
          HugeIconsStroke.search01,
          color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
          size: 20,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHigh,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;
    final workspace = ref.watch(currentWorkspaceProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

    if (workspace == null) {
      return Scaffold(
        appBar: isMobile
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () {
                    ref.read(activeSettingsPanelProvider.notifier).state =
                        SettingsPanelType.none;
                  },
                ),
                title: const Text('Users & Groups'),
              )
            : null,
        body: const Center(
          child: Text('No active workspace selected.'),
        ),
      );
    }

    final workspaceId = workspace['id'] ?? '';
    final creatorId = workspace['created_by'] ?? '';
    final managers = List<String>.from(workspace['managers'] ?? []);
    final workspaceMembers = List<String>.from(workspace['members'] ?? []);

    final isAdmin = currentUserId == creatorId;
    final isManager = managers.contains(currentUserId) || isAdmin;
    final _viewHistory = ref.watch(usersAndGroupsViewHistoryProvider);
    final _currentPage = ref.watch(usersAndGroupsPageIndexProvider);

    if (!_pageController.hasClients && _pageController.initialPage != _currentPage) {
      _pageController.dispose();
      _pageController = PageController(initialPage: _currentPage);
    }

    final bodyContent = _viewHistory.isNotEmpty
        ? (_viewHistory.last.startsWith('user:')
            ? _buildUserProfileInspector(context, _viewHistory.last.substring(5), workspaceId, isManager)
            : _buildUserGroupInspector(context, _viewHistory.last.substring(6), workspaceId, workspaceMembers, isManager))
        : Scaffold(
      appBar: AppBar(
        leading: isMobile
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  ref.read(activeSettingsPanelProvider.notifier).state =
                      SettingsPanelType.none;
                },
              )
            : null,
        title: Text(
          'Users & Groups',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            children: [
                const SizedBox(height: 12),
                _buildFloatingPill(theme, _currentPage),
                const SizedBox(height: 16),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      ref.read(usersAndGroupsPageIndexProvider.notifier).state = index;
                    },
                    children: [
                      // PAGE 1: USERS
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('user_id', whereIn: workspaceMembers.isEmpty ? [''] : workspaceMembers)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final users = snapshot.data!.docs;

                          if (users.isEmpty) {
                            return const Center(child: Text('No users in this workspace.'));
                          }

                          final totalUserCount = users.length;
                          final filteredUsers = users.where((doc) {
                            final userData = doc.data() as Map<String, dynamic>;
                            final displayName = (userData['display_name'] ?? '').toString().toLowerCase();
                            final handle = (userData['user_name'] ?? '').toString().toLowerCase();
                            final query = _userSearchQuery.toLowerCase();
                            return displayName.contains(query) || handle.contains(query);
                          }).toList();

                          return Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: _buildSearchBar(
                                      context,
                                      controller: _userSearchController,
                                      hintText: 'Search $totalUserCount users',
                                      onClear: () {
                                        _userSearchController.clear();
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: filteredUsers.isEmpty
                                        ? const Center(child: Text('No matching users found.'))
                                        : ListView.builder(
                                            itemCount: filteredUsers.length,
                                            itemBuilder: (context, index) {
                                              final userData = filteredUsers[index].data() as Map<String, dynamic>;
                                              final userId = userData['user_id'] ?? '';
                                              final displayName = userData['display_name'] ?? 'Aero User';
                                              final photoUrl = userData['photo_url'] as String?;
                                              final handle = userData['user_name'] ?? 'user';
                                              final isThisUserCreator = userId == creatorId;
                                              final isThisUserManager = managers.contains(userId) || isThisUserCreator;

                                              final initials = displayName.isNotEmpty
                                                  ? displayName[0].toUpperCase()
                                                  : 'A';

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: ListTile(
                                                  onTap: () {
                                                    ref.read(usersAndGroupsViewHistoryProvider.notifier).update((state) => [...state, 'user:$userId']);
                                                  },
                                                  hoverColor: theme.colorScheme.primary.withAlpha(20),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  leading: CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor: photoUrl == null || photoUrl.isEmpty
                                                        ? _getInitialsBgColor(displayName)
                                                        : null,
                                                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                                        ? NetworkImage(photoUrl)
                                                        : null,
                                                    child: photoUrl == null || photoUrl.isEmpty
                                                        ? Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                                        : null,
                                                  ),
                                                  title: Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          displayName,
                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      if (isThisUserCreator)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: theme.colorScheme.primaryContainer,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text('Admin', style: TextStyle(fontSize: 8, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                                        )
                                                      else if (isThisUserManager)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: theme.colorScheme.secondaryContainer,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text('Manager', style: TextStyle(fontSize: 8, color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                                                        )
                                                    ],
                                                  ),
                                                  subtitle: Text(
                                                    '@$handle',
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                  trailing: PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_vert),
                                                    onSelected: (action) {
                                                      if (action == 'dm') {
                                                        _dmUser(context, userId, displayName);
                                                      } else if (action == 'remove') {
                                                        _removeUser(context, workspaceId, userId, displayName);
                                                      } else if (action == 'promote') {
                                                        _promoteUser(context, workspaceId, userId, displayName);
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(
                                                        value: 'dm',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.chat_bubble_outline, size: 18),
                                                            SizedBox(width: 8),
                                                            Text('Send DM'),
                                                          ],
                                                        ),
                                                      ),
                                                      if (isManager && userId != currentUserId && !isThisUserCreator) ...[
                                                        const PopupMenuItem(
                                                          value: 'promote',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.shield, size: 18),
                                                              SizedBox(width: 8),
                                                              Text('Promote to Manager'),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'remove',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.person_remove, size: 18, color: Colors.red),
                                                              SizedBox(width: 8),
                                                              Text('Remove User', style: TextStyle(color: Colors.red)),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // PAGE 2: USER GROUPS
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('workspaces')
                            .doc(workspaceId)
                            .collection('user_groups')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final groups = snapshot.data!.docs;
                          final totalGroupCount = groups.length;
                          final filteredGroups = groups.where((doc) {
                            final groupData = doc.data() as Map<String, dynamic>;
                            final name = (groupData['name'] ?? '').toString().toLowerCase();
                            final handle = (groupData['handle'] ?? '').toString().toLowerCase();
                            final query = _groupSearchQuery.toLowerCase();
                            return name.contains(query) || handle.contains(query);
                          }).toList();

                          return Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  if (groups.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildSearchBar(
                                              context,
                                              controller: _groupSearchController,
                                              hintText: 'Search $totalGroupCount user groups',
                                              onClear: () {
                                                _groupSearchController.clear();
                                              },
                                            ),
                                          ),
                                          if (isManager) ...[
                                            const SizedBox(width: 12),
                                            ElevatedButton.icon(
                                              onPressed: () => _createNewGroup(context, workspaceId),
                                              icon: const Icon(Icons.add, size: 16),
                                              label: const Text('Create Group'),
                                              style: ElevatedButton.styleFrom(
                                                fixedSize: const Size.fromHeight(50),
                                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(25),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  else if (isManager)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: ElevatedButton.icon(
                                        onPressed: () => _createNewGroup(context, workspaceId),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Create User Group'),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size.fromHeight(50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: groups.isEmpty
                                        ? const Center(child: Text('No user groups created yet.'))
                                        : filteredGroups.isEmpty
                                            ? const Center(child: Text('No matching user groups found.'))
                                            : ListView.builder(
                                                itemCount: filteredGroups.length,
                                                itemBuilder: (context, index) {
                                                  final groupDoc = filteredGroups[index];
                                                  final groupData = groupDoc.data() as Map<String, dynamic>;
                                                  final name = groupData['name'] ?? 'Unnamed Group';
                                                  final handle = groupData['handle'] ?? 'group';
                                                 final groupId = groupData['id'] ?? '';
                                                  final isPromoted = groupData['is_promoted'] == true;

                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                    child: ListTile(
                                                      onTap: () {
                                                        ref.read(usersAndGroupsViewHistoryProvider.notifier).update((state) => [...state, 'group:$groupId']);
                                                      },
                                                      hoverColor: theme.colorScheme.primary.withAlpha(20),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      leading: CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor: theme.colorScheme.primaryContainer,
                                                        child: Icon(
                                                          HugeIconsStroke.userGroup,
                                                          color: theme.colorScheme.primary,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      title: Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              name,
                                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                          if (isPromoted) ...[
                                                            const SizedBox(width: 6),
                                                            Icon(Icons.star, color: Colors.amber[600], size: 14),
                                                          ],
                                                        ],
                                                      ),
                                                      subtitle: Text(
                                                        '@$handle',
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                      trailing: PopupMenuButton<String>(
                                                        icon: const Icon(Icons.more_vert),
                                                        onSelected: (action) {
                                                          if (action == 'view') {
                                                            ref.read(usersAndGroupsViewHistoryProvider.notifier).update((state) => [...state, 'group:$groupId']);
                                                          } else if (action == 'add_user') {
                                                            _addUserToGroup(context, workspaceId, groupData, workspaceMembers);
                                                          } else if (action == 'promote') {
                                                            _promoteGroup(context, workspaceId, groupData);
                                                          } else if (action == 'delete') {
                                                            _deleteGroup(context, workspaceId, groupId, name);
                                                          }
                                                        },
                                                        itemBuilder: (context) => [
                                                          const PopupMenuItem(
                                                            value: 'view',
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.visibility_outlined, size: 18),
                                                                SizedBox(width: 8),
                                                                Text('View Group Details'),
                                                               ],
                                                            ),
                                                          ),
                                                          if (isManager) ...[
                                                            const PopupMenuItem(
                                                              value: 'add_user',
                                                              child: Row(
                                                                children: [
                                                                  Icon(Icons.person_add_alt_1_outlined, size: 18),
                                                                  SizedBox(width: 8),
                                                                  Text('Add Member'),
                                                                ],
                                                              ),
                                                            ),
                                                            PopupMenuItem(
                                                              value: 'promote',
                                                              child: Row(
                                                                children: [
                                                                  Icon(isPromoted ? Icons.star_border : Icons.star, size: 18),
                                                                  const SizedBox(width: 8),
                                                                  Text(isPromoted ? 'Demote Group' : 'Promote Group'),
                                                                ],
                                                              ),
                                                            ),
                                                            const PopupMenuItem(
                                                              value: 'delete',
                                                              child: Row(
                                                                children: [
                                                                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                                  SizedBox(width: 8),
                                                                  Text('Delete Group', style: TextStyle(color: Colors.red)),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        );

    return PopScope(
      canPop: _viewHistory.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(usersAndGroupsViewHistoryProvider.notifier).update((state) => state.isEmpty ? state : state.sublist(0, state.length - 1));
      },
      child: bodyContent,
    );
  }

  Widget _buildUserProfileInspector(BuildContext context, String userId, String workspaceId, bool isManager) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userProfileByIdProvider(userId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            ref.read(usersAndGroupsViewHistoryProvider.notifier).update((state) => state.isEmpty ? state : state.sublist(0, state.length - 1));
          },
        ),
        title: const Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading profile: $e')),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('User profile not found.'));
            }
            final displayName = user.displayName.isNotEmpty ? user.displayName : 'Aero User';
            final photoUrl = user.photoUrl;
            final handle = user.userName.isNotEmpty ? user.userName : 'user';
            final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
            final activeWorkspace = ref.watch(currentWorkspaceProvider);
            final creatorId = activeWorkspace?['created_by'] ?? '';
            final managers = List<String>.from(activeWorkspace?['managers'] ?? []);
            final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
            final isCreator = userId == creatorId;
            final isThisUserManager = managers.contains(userId) || isCreator;
            
            String roleText = 'Member';
            if (isCreator) {
              roleText = 'Admin/Creator';
            } else if (isThisUserManager) {
              roleText = 'Manager';
            }

            return SingleChildScrollView(
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
                      // Profile Header Card
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: photoUrl.isEmpty
                                    ? LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.secondary,
                                        ],
                                      )
                                    : null,
                                image: photoUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(photoUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withAlpha(40),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: photoUrl.isNotEmpty
                                  ? null
                                  : Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
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
                      Row(
                        children: [
                          Expanded(
                            child: ActionButton(
                              icon: Icons.chat_bubble_outline,
                              label: 'Send DM',
                              onTap: () {
                                _dmUser(context, userId, displayName);
                              },
                            ),
                          ),
                          if (isManager && userId != currentUserId && !isCreator) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ActionButton(
                                icon: isThisUserManager ? Icons.shield : Icons.shield_outlined,
                                label: isThisUserManager ? 'Demote' : 'Promote',
                                onTap: () {
                                  _promoteUser(context, workspaceId, userId, displayName);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ActionButton(
                                icon: Icons.person_remove,
                                label: 'Remove',
                                onTap: () {
                                  _removeUser(context, workspaceId, userId, displayName);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Profile Details Card
                      const SectionHeader(title: 'Profile Details', fontSize: 11.0),
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
                              icon: Icons.email_outlined,
                              label: 'Email ID',
                              value: user.emailId,
                            ),
                            Divider(
                              height: 24,
                              color: theme.colorScheme.outlineVariant.withAlpha(80),
                            ),
                            DetailsRow(
                              icon: Icons.shield,
                              label: 'Workspace Role',
                              value: roleText,
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
        ),
      ),
    );
  }

  Widget _buildUserGroupInspector(BuildContext context, String groupId, String workspaceId, List<String> workspaceMembers, bool isManager) {
    final theme = Theme.of(context);
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('user_groups')
          .doc(groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  ref.read(usersAndGroupsViewHistoryProvider.notifier).update((state) => state.isEmpty ? state : state.sublist(0, state.length - 1));
                },
              ),
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () {
                ref.read(usersAndGroupsViewHistoryProvider.notifier).update((state) => state.isEmpty ? state : state.sublist(0, state.length - 1));
              },
            ),
            title: const Text(
              'User Group Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                      // Group Header Card
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
                                    theme.colorScheme.primaryContainer,
                                    theme.colorScheme.secondaryContainer,
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
                              child: Icon(
                                HugeIconsStroke.userGroup,
                                color: theme.colorScheme.primary,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                  Icon(Icons.star, color: Colors.amber[600], size: 20),
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
                      if (isManager) ...[
                        Row(
                          children: [
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
                            Expanded(
                              child: ActionButton(
                                icon: isPromoted ? Icons.star_border : Icons.star,
                                label: isPromoted ? 'Demote Group' : 'Promote Group',
                                onTap: () {
                                  _promoteGroup(context, workspaceId, groupData);
                                },
                              ),
                            ),
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
                        ),
                        const SizedBox(height: 24),
                      ],

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
                              icon: Icons.star_outline,
                              label: 'Starred Status',
                              value: isPromoted ? 'Starred (Promoted)' : 'Standard Group',
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
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withAlpha(80),
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              final memberId = members[index];
                              final isLast = index == members.length - 1;
                              
                              return Consumer(
                                builder: (context, ref, child) {
                                  final profileAsync = ref.watch(userProfileByIdProvider(memberId));
                                  return profileAsync.when(
                                    loading: () => const ListTile(title: Text('Loading member...')),
                                    error: (e, s) => ListTile(title: Text('Error: $e')),
                                    data: (profile) {
                                      if (profile == null) return const SizedBox.shrink();
                                      final displayName = profile.displayName.isNotEmpty ? profile.displayName : 'Aero User';
                                      final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
                                      final photoUrl = profile.photoUrl;

                                      return Column(
                                        children: [
                                          ListTile(
                                            onTap: () {
                                              ref.read(usersAndGroupsViewHistoryProvider.notifier).update((state) => [...state, 'user:$memberId']);
                                            },
                                            hoverColor: theme.colorScheme.primary.withAlpha(20),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            leading: CircleAvatar(
                                              radius: 18,
                                              backgroundColor: photoUrl.isEmpty
                                                  ? _getInitialsBgColor(displayName)
                                                  : null,
                                              backgroundImage: photoUrl.isNotEmpty
                                                  ? NetworkImage(photoUrl)
                                                  : null,
                                              child: photoUrl.isEmpty
                                                  ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                                                  : null,
                                            ),
                                            title: Text(
                                              displayName,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            subtitle: Text(
                                              '@${profile.userName}',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                                          ),
                                          if (!isLast)
                                            Divider(
                                              height: 1,
                                              indent: 16,
                                              color: theme.colorScheme.outlineVariant.withAlpha(80),
                                            ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UsersAndGroupsPageState extends UsersAndGroupsPageState {}

