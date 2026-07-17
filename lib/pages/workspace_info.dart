import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:characters/characters.dart';

// Providers & Layout
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/enums/layout_mode.dart';

// Reusable Widgets
import 'package:chat/widgets/section_header.dart';
import 'package:chat/widgets/details_row.dart';
import 'package:chat/widgets/action_button.dart';

class WorkspaceInfoPage extends ConsumerStatefulWidget {
  const WorkspaceInfoPage({super.key});

  @override
  ConsumerState<WorkspaceInfoPage> createState() => _WorkspaceInfoPageState();
}

class _WorkspaceInfoPageState extends ConsumerState<WorkspaceInfoPage> {
  bool _isEditingName = false;
  bool _isSavingName = false;
  late TextEditingController _nameController;

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

  Future<void> _shareInviteCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite code "$code" copied to clipboard!'),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _changeVisibility(BuildContext context, String workspaceId, String currentVisibility) async {
    final theme = Theme.of(context);
    final nextVisibility = currentVisibility.toLowerCase() == 'discoverable' ? 'private' : 'discoverable';
    
    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .update({'visibility': nextVisibility});
      ref.invalidate(userWorkspacesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update visibility: $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateWorkspaceName(String workspaceId) async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() {
      _isSavingName = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .update({'name': newName});
      ref.invalidate(userWorkspacesProvider);
      if (mounted) {
        setState(() {
          _isEditingName = false;
          _isSavingName = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingName = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update workspace name: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editWorkspaceIcon(BuildContext context, String workspaceId, String currentEmoji) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return _EmojiSelectorDialog(
          currentEmoji: currentEmoji,
          onSelected: (newEmoji) async {
            final theme = Theme.of(context);
            try {
              await FirebaseFirestore.instance
                  .collection('workspaces')
                  .doc(workspaceId)
                  .update({
                'logo': newEmoji,
                'emoji': newEmoji,
              });
              ref.invalidate(userWorkspacesProvider);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            } catch (e) {
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update workspace icon: $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;
    final workspace = ref.watch(currentWorkspaceProvider);

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
                title: const Text('Workspace Info'),
              )
            : null,
        body: const Center(
          child: Text('No active workspace selected.'),
        ),
      );
    }

    final workspaceId = workspace['id'] ?? '';
    final workspaceName = workspace['name'] ?? 'Unnamed Workspace';
    final workspaceEmoji = workspace['logo'] ?? workspace['emoji'] ?? '💼';
    final visibility = workspace['visibility'] ?? 'private';
    final creatorId = workspace['created_by'] ?? '';

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
              title: Text(
                'Workspace Info',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
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
                  // Centered Workspace Icon / Emoji Card
                  Center(
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => _editWorkspaceIcon(context, workspaceId, workspaceEmoji),
                          customBorder: const CircleBorder(),
                          child: Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withAlpha(20),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant.withAlpha(100),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  workspaceEmoji,
                                  style: const TextStyle(fontSize: 44),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 12,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_isEditingName) ...[
                          Text(
                            workspaceName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: TextField(
                              controller: _nameController,
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText: 'Workspace Name',
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
                                            onPressed: () => _updateWorkspaceName(workspaceId),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.primary, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                _isEditingName = false;
                                                _nameController.text = workspaceName;
                                              });
                                            },
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                              ),
                              onSubmitted: (_) => _updateWorkspaceName(workspaceId),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Invite Code: $workspaceId',
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
                          icon: HugeIconsStroke.globe02,
                          label: 'Visibility',
                          onTap: () => _changeVisibility(context, workspaceId, visibility),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ActionButton(
                          icon: _isEditingName ? HugeIconsStroke.checkmarkCircle01 : HugeIconsStroke.edit02,
                          label: _isEditingName ? 'Save' : 'Edit Name',
                          onTap: () {
                            if (_isEditingName) {
                              _updateWorkspaceName(workspaceId);
                            } else {
                              setState(() {
                                _isEditingName = true;
                                _nameController.text = workspaceName;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ActionButton(
                          icon: HugeIconsStroke.copyLink,
                          label: 'Share Code',
                          onTap: () => _shareInviteCode(context, workspaceId),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Details Card
                  const SectionHeader(title: 'Workspace Details', fontSize: 11.0),
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
                          icon: HugeIconsStroke.passport,
                          label: 'WORKSPACE ID',
                          value: workspaceId,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1),
                        ),
                        DetailsRow(
                          icon: HugeIconsStroke.user,
                          label: 'CREATOR ID',
                          value: creatorId.isNotEmpty ? creatorId : 'System Onboarding',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1),
                        ),
                        DetailsRow(
                          icon: HugeIconsStroke.view,
                          label: 'VISIBILITY',
                          value: visibility.toUpperCase(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiSelectorDialog extends StatefulWidget {
  final String currentEmoji;
  final Function(String) onSelected;

  const _EmojiSelectorDialog({
    required this.currentEmoji,
    required this.onSelected,
  });

  @override
  State<_EmojiSelectorDialog> createState() => _EmojiSelectorDialogState();
}

class _EmojiSelectorDialogState extends State<_EmojiSelectorDialog> {
  static const List<String> _availableEmojis = [
    '🏢', '🚀', '💡', '🎨', '🎮', '📚', '🎵', '⚽', '⚙️', '🛡️', '🩺', '🌍'
  ];

  late String _selectedEmoji;
  bool _showCustomInput = false;
  final TextEditingController _customController = TextEditingController();
  String? _customError;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.currentEmoji;
    if (!_availableEmojis.contains(_selectedEmoji)) {
      _showCustomInput = true;
      _customController.text = _selectedEmoji;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    if (_showCustomInput) {
      final text = _customController.text.trim();
      if (text.isEmpty) {
        setState(() {
          _customError = 'Please enter an emoji';
        });
        return;
      }
      if (text.characters.length != 1) {
        setState(() {
          _customError = 'Only 1 emoji is allowed';
        });
        return;
      }
      widget.onSelected(text);
    } else {
      widget.onSelected(_selectedEmoji);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Select Workspace Icon'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: _availableEmojis.length,
              itemBuilder: (context, idx) {
                final emoji = _availableEmojis[idx];
                final isSelected = emoji == _selectedEmoji && !_showCustomInput;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                      _showCustomInput = false;
                      _customError = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withAlpha(80),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(HugeIconsStroke.keyboard, size: 18),
              label: const Text('Custom Emoji'),
              onPressed: () {
                setState(() {
                  _showCustomInput = true;
                  _customError = null;
                });
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (_showCustomInput) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customController,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28),
                decoration: InputDecoration(
                  labelText: 'Enter Custom Emoji',
                  errorText: _customError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLength: 5,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                onChanged: (val) {
                  if (_customError != null) {
                    setState(() {
                      _customError = null;
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _validateAndSubmit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
