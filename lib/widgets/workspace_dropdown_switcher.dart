// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/auth_provider.dart';

// Services
import 'package:chat/services/add_workspace_flow.dart';
import 'package:chat/services/device_service.dart';

class WorkspaceDropdownSwitcher extends ConsumerWidget {
  const WorkspaceDropdownSwitcher({super.key});

  Future<void> _switchWorkspace(WidgetRef ref, BuildContext context, String workspaceId) async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      try {
        final deviceId = await DeviceService.getDeviceId();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('devices')
            .doc(deviceId)
            .set({
          'device_id': deviceId,
          'active_workspace_id': workspaceId,
          'last_active': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        ref.invalidate(userProfileProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to switch workspace: $e"),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(userWorkspacesProvider);
    final currentWorkspace = ref.watch(currentWorkspaceProvider);
    final theme = Theme.of(context);

    return workspacesAsync.when(
      data: (workspaces) {
        if (workspaces.isEmpty) return const SizedBox.shrink();
        
        final currentLogo = currentWorkspace?['logo'] ?? '🏢';
        final currentName = currentWorkspace?['name'] ?? 'Select Workspace';
        final currentId = currentWorkspace?['id'];

        return PopupMenuButton<String>(
          tooltip: 'Switch Workspace: $currentName',
          onSelected: (value) {
            if (value == 'add_workspace') {
              openAddWorkspaceFlow(context);
            } else {
              _switchWorkspace(ref, context, value);
            }
          },
          itemBuilder: (context) {
            final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[
              ...workspaces.map((ws) {
                final id = ws['id'] as String;
                final logo = ws['logo'] as String? ?? '🏢';
                final name = ws['name'] as String? ?? 'Workspace';
                final isCurrent = id == currentId;

                return PopupMenuItem<String>(
                  value: id,
                  child: Row(
                    children: [
                      Text(
                        logo,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Icon(
                          Icons.check,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                    ],
                  ),
                );
              }),
            ];

            items.add(const PopupMenuDivider());
            items.add(
              PopupMenuItem<String>(
                value: 'add_workspace',
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Workspace',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );

            return items;
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withAlpha(100),
              ),
            ),
            child: Text(
              currentLogo,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
