// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers & Layout
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/providers/nav_provider.dart';

// Widgets
import 'package:chat/widgets/chat/group_creation_modal.dart';

// Enums & Values
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
    Future.microtask(() {
      ref.read(usersAndGroupsViewHistoryProvider.notifier).state = const [];
      ref.read(usersAndGroupsPageIndexProvider.notifier).state = 0;
    });
    super.dispose();
  }

  Offset _tapPosition = Offset.zero;

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showUserPopupMenu(
    BuildContext context,
    String userId,
    String displayName,
    bool isManager,
    bool isThisUserCreator,
    String currentUserId,
    String workspaceId,
  ) {
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(_tapPosition.dx, _tapPosition.dy, 30, 30),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
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
          PopupMenuItem(
            value: 'promote',
            child: Row(
              children: [
                Icon(Icons.shield, size: 18),
                const SizedBox(width: 8),
                Text('Promote/Demote'),
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
    ).then((action) {
      if (action == 'dm') {
        _dmUser(context, userId, displayName);
      } else if (action == 'remove') {
        _removeUser(context, workspaceId, userId, displayName);
      } else if (action == 'promote') {
        _promoteUser(context, workspaceId, userId, displayName);
      }
    });
  }

  void _showGroupPopupMenu(
    BuildContext context,
    String groupId,
    String name,
    Map<String, dynamic> groupData,
    bool isManager,
    bool isOtherGroupManager,
    bool isPromoted,
    List<String> workspaceMembers,
    String workspaceId,
  ) {
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(_tapPosition.dx, _tapPosition.dy, 30, 30),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
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
        ],
        if (isManager || isOtherGroupManager) ...[
          PopupMenuItem(
            value: 'promote',
            child: Row(
              children: [
                Icon(isPromoted ? Icons.shield_outlined : Icons.shield, size: 18),
                const SizedBox(width: 8),
                Text(isPromoted ? 'Demote Group' : 'Promote Group'),
              ],
            ),
          ),
        ],
        if (isManager) ...[
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
    ).then((action) {
      if (action == 'view') {
        ref.read(userGroupTargetIdProvider.notifier).state = groupId;
        ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.userGroupInfo;
      } else if (action == 'add_user') {
        _addUserToGroup(context, workspaceId, groupData, workspaceMembers);
      } else if (action == 'promote') {
        _promoteGroup(context, workspaceId, groupData);
      } else if (action == 'delete') {
        _deleteGroup(context, workspaceId, groupId, name);
      }
    });
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
          .collection('chats')
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

        // Opening chat session
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
        // User removed successfully
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
        // User promoted successfully
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
    showGroupCreationModal(context, workspaceId);
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
        // Group promotion updated successfully
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
        // Group deleted successfully
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
                title: const Text('Users & User Groups'),
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

    final bodyContent = Scaffold(
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
          'Users & User Groups',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!isMobile && ref.read(navIndexProvider) != 2)
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
                            return RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(userWorkspacesProvider);
                                try {
                                  await ref.read(userWorkspacesProvider.future);
                                } catch (_) {}
                              },
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(
                                    height: 300,
                                    child: Center(child: Text('No users in this workspace.')),
                                  ),
                                ],
                              ),
                            );
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
                                    child: RefreshIndicator(
                                      onRefresh: () async {
                                        ref.invalidate(userWorkspacesProvider);
                                        try {
                                          await ref.read(userWorkspacesProvider.future);
                                        } catch (_) {}
                                      },
                                      child: filteredUsers.isEmpty
                                          ? ListView(
                                              physics: const AlwaysScrollableScrollPhysics(),
                                              children: const [
                                                SizedBox(
                                                  height: 200,
                                                  child: Center(
                                                    child: Text('No matching users found.'),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : ListView.builder(
                                              physics: const AlwaysScrollableScrollPhysics(),
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
                                                   child: GestureDetector(
                                                     onTapDown: _storePosition,
                                                     onLongPress: () {
                                                       _showUserPopupMenu(context, userId, displayName, isManager, isThisUserCreator, currentUserId, workspaceId);
                                                     },
                                                     onSecondaryTap: () {
                                                       _showUserPopupMenu(context, userId, displayName, isManager, isThisUserCreator, currentUserId, workspaceId);
                                                     },
                                                     child: ListTile(
                                                       onTap: () {
                                                         ref.read(profileTargetUserIdProvider.notifier).state = userId;
                                                         ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.profile;
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
                                                     ),
                                                   ),
                                                 );
                                               },
                                            ),
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
                                    child: RefreshIndicator(
                                      onRefresh: () async {
                                        ref.invalidate(userWorkspacesProvider);
                                        try {
                                          await ref.read(userWorkspacesProvider.future);
                                        } catch (_) {}
                                      },
                                      child: groups.isEmpty
                                          ? ListView(
                                              physics: const AlwaysScrollableScrollPhysics(),
                                              children: const [
                                                SizedBox(
                                                  height: 200,
                                                  child: Center(child: Text('No user groups created yet.')),
                                                ),
                                              ],
                                            )
                                          : filteredGroups.isEmpty
                                              ? ListView(
                                                  physics: const AlwaysScrollableScrollPhysics(),
                                                  children: const [
                                                    SizedBox(
                                                      height: 200,
                                                      child: Center(child: Text('No matching user groups found.')),
                                                    ),
                                                  ],
                                                )
                                              : ListView.builder(
                                                  physics: const AlwaysScrollableScrollPhysics(),
                                                  itemCount: filteredGroups.length,
                                                   itemBuilder: (context, index) {
                                                     final groupDoc = filteredGroups[index];
                                                     final groupData = groupDoc.data() as Map<String, dynamic>;
                                                     final name = groupData['name'] ?? 'Unnamed Group';
                                                     final handle = groupData['handle'] ?? 'group';
                                                     final groupId = groupData['id'] ?? '';
                                                     final isPromoted = groupData['is_promoted'] == true;

                                                     bool isOtherGroupManagerLocal = false;
                                                     final currentUserId = ref.read(authStateProvider).value?.uid ?? '';
                                                     for (final doc in groups) {
                                                       if (doc.id == groupId) continue;
                                                       final data = doc.data() as Map<String, dynamic>;
                                                       if (data['is_promoted'] == true) {
                                                         final membersList = List<String>.from(data['members'] ?? []);
                                                         if (membersList.contains(currentUserId)) {
                                                           isOtherGroupManagerLocal = true;
                                                           break;
                                                         }
                                                       }
                                                     }

                                                     return Padding(
                                                       padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                       child: GestureDetector(
                                                         onTapDown: _storePosition,
                                                         onLongPress: () {
                                                           _showGroupPopupMenu(context, groupId, name, groupData, isManager, isOtherGroupManagerLocal, isPromoted, workspaceMembers, workspaceId);
                                                         },
                                                         onSecondaryTap: () {
                                                           _showGroupPopupMenu(context, groupId, name, groupData, isManager, isOtherGroupManagerLocal, isPromoted, workspaceMembers, workspaceId);
                                                         },
                                                         child: ListTile(
                                                           onTap: () {
                                                             ref.read(userGroupTargetIdProvider.notifier).state = groupId;
                                                             ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.userGroupInfo;
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
                                                           subtitle: Text(
                                                             '@$handle',
                                                             overflow: TextOverflow.ellipsis,
                                                             maxLines: 1,
                                                           ),
                                                           trailing: PopupMenuButton<String>(
                                                             icon: const Icon(Icons.more_vert),
                                                             onSelected: (action) {
                                                               if (action == 'view') {
                                                                 ref.read(userGroupTargetIdProvider.notifier).state = groupId;
                                                                 ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.userGroupInfo;
                                                               } else if (action == 'add_user') {
                                                                 _addUserToGroup(context, workspaceId, groupData, workspaceMembers);
                                                               } else if (action == 'promote') {
                                                                 _promoteGroup(context, workspaceId, groupData);
                                                               } else if (action == 'delete') {
                                                                 _deleteGroup(context, workspaceId, groupId, name);
                                                               }
                                                             },
                                                             itemBuilder: (context) {
                                                               return [
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
                                                                 ],
                                                                 if (isManager || isOtherGroupManagerLocal) ...[
                                                                   PopupMenuItem(
                                                                     value: 'promote',
                                                                     child: Row(
                                                                       children: [
                                                                         Icon(isPromoted ? Icons.shield_outlined : Icons.shield, size: 18),
                                                                         const SizedBox(width: 8),
                                                                         Text(isPromoted ? 'Demote Group' : 'Promote Group'),
                                                                       ],
                                                                     ),
                                                                   ),
                                                                 ],
                                                                 if (isManager) ...[
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
                                                               ];
                                                             },
                                                           ),
                                                         ),
                                                       ),
                                                     );
                                                   },
                                                ),
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
}

class _UsersAndGroupsPageState extends UsersAndGroupsPageState {}

