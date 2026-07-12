// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hugeicons_pro/hugeicons.dart';

// Providers
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/nav_provider.dart';

// Repositories
import 'package:chat/repositories/chat_repository.dart';

// Models
import 'package:chat/models/user_model.dart';

/// Entrypoint to display the creation flow modal adaptively.
void showCreationFlowModal(BuildContext context, {required bool isChannel}) {
  final width = MediaQuery.of(context).size.width;
  final isMobile = width < 840;

  if (isMobile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: CreationFlowModal(
            isChannel: isChannel,
            isMobile: true,
          ),
        ),
      ),
    );
  } else {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580, maxHeight: 520),
              child: Card(
                elevation: 12,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: theme.colorScheme.surfaceContainer,
                child: CreationFlowModal(
                  isChannel: isChannel,
                  isMobile: false,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CreationFlowModal extends ConsumerStatefulWidget {
  final bool isChannel;
  final bool isMobile;

  const CreationFlowModal({
    super.key,
    required this.isChannel,
    required this.isMobile,
  });

  @override
  ConsumerState<CreationFlowModal> createState() => _CreationFlowModalState();
}

class _CreationFlowModalState extends ConsumerState<CreationFlowModal> {
  late bool _showChannelCreation;

  @override
  void initState() {
    super.initState();
    _showChannelCreation = widget.isChannel;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = _showChannelCreation
        ? ChannelCreationSheet(
            isMobile: widget.isMobile,
            onClose: () => Navigator.of(context).pop(),
            onSwitchToDM: () {
              setState(() {
                _showChannelCreation = false;
              });
            },
          )
        : DMMemberSelectorSheet(
            isMobile: widget.isMobile,
            onClose: () => Navigator.of(context).pop(),
            onSwitchToChannel: () {
              setState(() {
                _showChannelCreation = true;
              });
            },
          );

    if (widget.isMobile) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            _showChannelCreation ? 'Create Channel' : 'New Direct Message',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _showChannelCreation = !_showChannelCreation;
                });
              },
              child: Text(
                _showChannelCreation ? 'Switch to DM' : 'Switch to Channel',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(child: child),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _showChannelCreation ? 'Create Channel' : 'New Direct Message',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showChannelCreation = !_showChannelCreation;
                  });
                },
                child: Text(
                  _showChannelCreation ? 'Switch to DM' : 'Switch to Channel',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          Expanded(child: child),
        ],
      );
    }
  }
}

class ChannelCreationSheet extends ConsumerStatefulWidget {
  final bool isMobile;
  final VoidCallback onClose;
  final VoidCallback onSwitchToDM;

  const ChannelCreationSheet({
    super.key,
    required this.isMobile,
    required this.onClose,
    required this.onSwitchToDM,
  });

  @override
  ConsumerState<ChannelCreationSheet> createState() => _ChannelCreationSheetState();
}

class _ChannelCreationSheetState extends ConsumerState<ChannelCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isPrivate = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_formatChannelNameReactively);
  }

  @override
  void dispose() {
    _nameController.removeListener(_formatChannelNameReactively);
    _nameController.dispose();
    super.dispose();
  }

  void _formatChannelNameReactively() {
    final original = _nameController.text;
    final formatted = original.replaceAll(' ', '').toLowerCase();
    
    // Remove any '#' typed or pasted to avoid prefix duplication with the icon
    final cleanString = formatted.replaceAll('#', '');

    if (cleanString != original) {
      final offset = _nameController.selection.baseOffset;
      _nameController.text = cleanString;
      // Preserve selection cursor alignment offset
      try {
        _nameController.selection = TextSelection.fromPosition(
          TextPosition(offset: offset + (cleanString.length - original.length)),
        );
      } catch (_) {}
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    final workspaceId = ref.read(currentWorkspaceIdProvider) ?? '';
    final currentUserId = ref.read(authStateProvider).value?.uid ?? '';
    final channelName = _nameController.text;

    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.createChannel(
        workspaceId: workspaceId,
        channelName: channelName,
        type: _isPrivate ? 'private' : 'public',
        currentUserId: currentUserId,
      );

      // Close modal on completion
      widget.onClose();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create channel: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Channels are where your team communicates. They’re best when organized around a topic — like #marketing or #project-alpha.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                hintText: 'e.g. marketing',
                border: OutlineInputBorder(),
                prefixIcon: Icon(HugeIconsStroke.hashtag),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty || val == '#') {
                  return 'Enter a valid channel name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Make Private'),
              subtitle: const Text('When a channel is private, it can only be viewed or joined by invitation.'),
              value: _isPrivate,
              onChanged: (val) {
                setState(() {
                  _isPrivate = val;
                });
              },
              secondary: Icon(
                _isPrivate ? Icons.lock : Icons.lock_open,
                color: theme.colorScheme.primary,
              ),
              activeColor: theme.colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Channel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DMMemberSelectorSheet extends ConsumerStatefulWidget {
  final bool isMobile;
  final VoidCallback onClose;
  final VoidCallback onSwitchToChannel;

  const DMMemberSelectorSheet({
    super.key,
    required this.isMobile,
    required this.onClose,
    required this.onSwitchToChannel,
  });

  @override
  ConsumerState<DMMemberSelectorSheet> createState() => _DMMemberSelectorSheetState();
}

class _DMMemberSelectorSheetState extends ConsumerState<DMMemberSelectorSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _loadingUserId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startDM(AltrUser targetUser) async {
    setState(() {
      _loadingUserId = targetUser.userId;
    });

    final workspaceId = ref.read(currentWorkspaceIdProvider) ?? '';
    final currentUserId = ref.read(authStateProvider).value?.uid ?? '';

    try {
      final repo = ref.read(chatRepositoryProvider);
      final dmId = await repo.initializeDM(
        workspaceId: workspaceId,
        currentUserId: currentUserId,
        targetUserId: targetUser.userId,
      );

      // Navigate active canvas to the new DM channel
      ref.read(navIndexProvider.notifier).state = 0; // Navigates to DMs section
      ref.read(activeChatSessionProvider.notifier).state = ActiveChatSession(
        chatId: dmId,
        type: ChatSessionType.dm,
      );
      ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;

      // Close the modal
      widget.onClose();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize direct message: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingUserId = null;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspaceId = ref.watch(currentWorkspaceIdProvider) ?? '';
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

    final membersAsync = ref.watch(workspaceMembersStreamProvider(workspaceId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Members',
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: membersAsync.when(
              data: (members) {
                final query = _searchQuery.toLowerCase().trim();
                final filtered = members.where((m) {
                  // Exclude the current user from DM list selection
                  if (m.userId == currentUserId) return false;
                  return m.displayName.toLowerCase().contains(query) ||
                      m.userName.toLowerCase().contains(query) ||
                      m.emailId.toLowerCase().contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No members found matching "$_searchQuery"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final isItemLoading = _loadingUserId == user.userId;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withAlpha(50),
                        ),
                      ),
                      color: theme.colorScheme.surfaceContainerLow,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getInitialsBgColor(user.displayName),
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName.substring(0, 1).toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('@${user.userName} • ${user.emailId}'),
                        trailing: isItemLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                HugeIconsStroke.chat01,
                                color: theme.colorScheme.primary,
                              ),
                        onTap: _loadingUserId != null ? null : () => _startDM(user),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error loading workspace members: $err',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
