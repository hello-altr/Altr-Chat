import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons_pro/hugeicons.dart';

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
          
      // Visibility updated successfully, no snackbar shown
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

  Future<void> _editInfo(BuildContext context, String workspaceId, String currentName, String currentEmoji) async {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: currentName);
    final emojiController = TextEditingController(text: currentEmoji);
    
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Workspace Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(
                  labelText: 'Workspace Emoji / Icon',
                  hintText: 'e.g. 🚀',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Workspace Name',
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
                final newName = nameController.text.trim();
                final newEmoji = emojiController.text.trim();
                if (newName.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('workspaces')
                        .doc(workspaceId)
                        .update({
                      'name': newName,
                      'logo': newEmoji,
                      'emoji': newEmoji,
                    });
                    
                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update workspace: $e'),
                          backgroundColor: theme.colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
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
                        const SizedBox(height: 16),
                        Text(
                          workspaceName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
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
                          icon: HugeIconsStroke.edit02,
                          label: 'Edit Info',
                          onTap: () => _editInfo(context, workspaceId, workspaceName, workspaceEmoji),
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
