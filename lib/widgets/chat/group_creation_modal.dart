// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/enums/layout_mode.dart';

// Repositories
import 'package:chat/repositories/chat_repository.dart';

// Providers & Widgets
import 'package:chat/widgets/chat/chat_feed_canvas.dart';

void showGroupCreationModal(BuildContext context, String workspaceId) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) {
      return GroupCreationResponsiveDialog(workspaceId: workspaceId);
    },
  );
}

class GroupCreationResponsiveDialog extends ConsumerWidget {
  final String workspaceId;

  const GroupCreationResponsiveDialog({
    super.key,
    required this.workspaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: isMobile
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: isMobile
          ? GroupCreationModal(
              workspaceId: workspaceId,
              isMobile: true,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580, maxHeight: 580),
                child: Card(
                  elevation: 12,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: theme.colorScheme.surfaceContainer,
                  child: GroupCreationModal(
                    workspaceId: workspaceId,
                    isMobile: false,
                  ),
                ),
              ),
            ),
    );
  }
}

class GroupCreationModal extends ConsumerStatefulWidget {
  final String workspaceId;
  final bool isMobile;

  const GroupCreationModal({
    super.key,
    required this.workspaceId,
    required this.isMobile,
  });

  @override
  ConsumerState<GroupCreationModal> createState() => _GroupCreationModalState();
}

class _GroupCreationModalState extends ConsumerState<GroupCreationModal> {
  int _currentPage = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _handleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCustomHandle = false;
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_nameListener);
  }

  @override
  void dispose() {
    _nameController.removeListener(_nameListener);
    _nameController.dispose();
    _handleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _nameListener() {
    if (!_isCustomHandle) {
      final name = _nameController.text.trim();
      final defaultHandle = name.replaceAll(' ', '-').toLowerCase();
      _handleController.text = defaultHandle;
    }
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

  void _handleBack() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  String _getTitle() {
    switch (_currentPage) {
      case 0:
        return 'Create a User Group';
      case 1:
        return 'Add Users';
      case 2:
        return 'Finalize User Group';
      default:
        return 'Create User Group';
    }
  }

  Future<void> _submitGroup() async {
    setState(() {
      _isLoading = true;
    });

    final currentUserId = ref.read(authStateProvider).value?.uid ?? '';
    final name = _nameController.text.trim();
    final handle = _handleController.text.trim().replaceAll('@', '').toLowerCase();

    try {
      final groupRef = FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('user_groups')
          .doc();

      await groupRef.set({
        'id': groupRef.id,
        'name': name,
        'handle': handle,
        'members': _selectedUserIds.toList(),
        'created_by': currentUserId,
        'created_at': FieldValue.serverTimestamp(),
        'is_promoted': false,
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPage1(ThemeData theme) {
    final userGroupsAsync = ref.watch(workspaceUserGroupsProvider(widget.workspaceId));
    final userGroups = userGroupsAsync.value ?? [];
    final enteredHandle = _handleController.text.trim().replaceAll('@', '').toLowerCase();
    final handleExists = enteredHandle.isNotEmpty && userGroups.any((group) => (group['handle'] ?? '').toString().toLowerCase() == enteredHandle);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User groups let you tag teams and departments all at once, such as @designers or @devs.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              hintText: 'e.g. Engineering Team',
              border: OutlineInputBorder(),
              prefixIcon: Icon(HugeIconsStroke.userGroup),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Customize Group Handle'),
            subtitle: const Text('Manually specify a custom @tag handle instead of the automatically generated one.'),
            value: _isCustomHandle,
            onChanged: (val) {
              setState(() {
                _isCustomHandle = val;
                if (!val) {
                  final name = _nameController.text.trim();
                  _handleController.text = name.replaceAll(' ', '-').toLowerCase();
                }
              });
            },
            secondary: Icon(
              _isCustomHandle ? Icons.edit : Icons.auto_awesome,
              color: theme.colorScheme.primary,
            ),
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
          if (!_isCustomHandle) ...[
            const SizedBox(height: 20),
            Text(
              'Group Handle Preview',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _handleController.text.isEmpty
                  ? '@group-handle'
                  : '@${_handleController.text}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: handleExists ? theme.colorScheme.error : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (handleExists) ...[
              const SizedBox(height: 4),
              Text(
                'This group handle is already taken in this workspace.',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
          if (_isCustomHandle) ...[
            const SizedBox(height: 20),
            TextFormField(
              controller: _handleController,
              decoration: InputDecoration(
                labelText: 'Group Handle',
                hintText: 'e.g. devs',
                border: const OutlineInputBorder(),
                prefixText: '@',
                errorText: handleExists ? 'This group handle is already taken in this workspace.' : null,
              ),
              onChanged: (val) {
                final formatted = val.replaceAll(' ', '-').toLowerCase();
                if (formatted != val) {
                  final offset = _handleController.selection.baseOffset;
                  _handleController.text = formatted;
                  try {
                    _handleController.selection = TextSelection.fromPosition(
                      TextPosition(offset: offset + (formatted.length - val.length)),
                    );
                  } catch (_) {}
                }
                setState(() {});
              },
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _nameController.text.trim().isEmpty ||
                         (_isCustomHandle && _handleController.text.trim().isEmpty) ||
                         handleExists
                  ? null
                  : () {
                      setState(() {
                        _currentPage = 1;
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2(ThemeData theme) {
    final membersAsync = ref.watch(workspaceMembersStreamProvider(widget.workspaceId));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: membersAsync.when(
        data: (users) {
          final selectedUsers = users.where((u) => _selectedUserIds.contains(u.userId)).toList();
          final filteredUsers = users.where((u) {
            if (_searchQuery.isEmpty) return true;
            final nameMatch = u.displayName.toLowerCase().contains(_searchQuery);
            final handleMatch = u.userName.toLowerCase().contains(_searchQuery);
            return nameMatch || handleMatch;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select members to add to this user group.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

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

              if (_selectedUserIds.isEmpty)
                SizedBox(
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
                              'Select members...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
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
                ),
              const SizedBox(height: 8),
              const Divider(),

              Expanded(
                child: filteredUsers.isEmpty
                    ? const Center(
                        child: Text('No members found.'),
                      )
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isSelected = _selectedUserIds.contains(user.userId);
                          final displayName = user.displayName;
                          final photoUrl = user.photoUrl;

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
                      ),
              ),

              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentPage = 2;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading members: $err')),
      ),
    );
  }

  Widget _buildPage3(ThemeData theme) {
    final membersAsync = ref.watch(workspaceMembersStreamProvider(widget.workspaceId));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review the details of your new user group.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Group Name', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(_nameController.text),
                            leading: const Icon(HugeIconsStroke.userGroup),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text('Group Handle', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('@${_handleController.text}'),
                            leading: const Icon(HugeIconsStroke.hashtag),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text('Members Count', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${_selectedUserIds.length} members added'),
                            leading: const Icon(HugeIconsStroke.user),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Members:',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  membersAsync.when(
                    data: (users) {
                      final selectedUsers = users.where((u) => _selectedUserIds.contains(u.userId)).toList();
                      if (selectedUsers.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Text('No members added.'),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedUsers.length,
                        itemBuilder: (context, index) {
                          final user = selectedUsers[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: user.photoUrl.isNotEmpty
                                ? CircleAvatar(backgroundImage: NetworkImage(user.photoUrl))
                                : CircleAvatar(
                                    backgroundColor: _getInitialsBgColor(user.displayName),
                                    child: Text(_getInitials(user.displayName), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                            title: Text(user.displayName),
                            subtitle: Text('@${user.userName}'),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Text('Error: $err'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create User Group'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(ThemeData theme) {
    switch (_currentPage) {
      case 0:
        return _buildPage1(theme);
      case 1:
        return _buildPage2(theme);
      case 2:
        return _buildPage3(theme);
      default:
        return _buildPage1(theme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isMobile) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          title: Text(
            _getTitle(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(child: _buildPageContent(theme)),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBack,
            ),
            title: Text(
              _getTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          Expanded(child: _buildPageContent(theme)),
        ],
      );
    }
  }
}
