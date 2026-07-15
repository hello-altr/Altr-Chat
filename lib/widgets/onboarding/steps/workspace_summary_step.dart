// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'dart:math';

// Providers
import 'package:chat/providers/auth_provider.dart';

// Services
import 'package:chat/services/device_service.dart';

class WorkspaceSummaryStep extends ConsumerStatefulWidget {
  final String name;
  final String logo;
  final List<String> modules;
  final List<String> channels;
  final String visibility;
  final VoidCallback? onCompleted;

  const WorkspaceSummaryStep({
    super.key,
    required this.name,
    required this.logo,
    required this.modules,
    required this.channels,
    required this.visibility,
    this.onCompleted,
  });

  @override
  ConsumerState<WorkspaceSummaryStep> createState() => _WorkspaceSummaryStepState();
}

class _WorkspaceSummaryStepState extends ConsumerState<WorkspaceSummaryStep> {
  bool _isLaunching = false;

  Future<void> _launchWorkspace() async {
    setState(() {
      _isLaunching = true;
    });

    final user = ref.read(authStateProvider).value;
    final name = widget.name.trim();

    try {
      if (user == null) throw Exception("User is unauthenticated.");
      if (name.isEmpty) throw Exception("Workspace name is empty.");

      final deviceId = await DeviceService.getDeviceId();
      
      // Generate 6 character uppercase alphanumeric workspace code
      final rnd = Random();
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final workspaceId = String.fromCharCodes(Iterable.generate(
          6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
      
      final batch = FirebaseFirestore.instance.batch();

      final workspaceRef = FirebaseFirestore.instance.collection('workspaces').doc(workspaceId);
      batch.set(workspaceRef, {
        'id': workspaceId,
        'name': name,
        'logo': widget.logo,
        'modules': widget.modules,
        'visibility': widget.visibility.toLowerCase(),
        'members': [user.uid],
        'created_by': user.uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      for (final channelName in widget.channels) {
        final channelRef = FirebaseFirestore.instance
            .collection('chats')
            .doc(workspaceId)
            .collection('channels')
            .doc();
        batch.set(channelRef, {
          'name': channelName.replaceAll('#', ''),
          'is_private': false,
          'is_archived': false,
          'members': [user.uid],
          'created_at': FieldValue.serverTimestamp(),
          'last_message': 'Workspace channel created.',
          'last_message_time': FieldValue.serverTimestamp(),
        });
      }

      final deviceRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId);
      batch.set(deviceRef, {
        'device_id': deviceId,
        'active_workspace_id': workspaceId,
        'last_active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(userRef, {
        'joined_workspaces': FieldValue.arrayUnion([workspaceId]),
        'workspace_onboarding_completed': true,
      });

      await batch.commit();
      ref.invalidate(userProfileProvider);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            final theme = Theme.of(dialogContext);
            return AlertDialog(
              title: const Text('Workspace Created!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your workspace has been successfully created. '
                    'Share this invitation code with your team to let them join:',
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(100),
                        ),
                      ),
                      child: SelectableText(
                        workspaceId,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                          letterSpacing: 4.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    if (widget.onCompleted != null) {
                      widget.onCompleted!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go to Workspace'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to launch workspace: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Details',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your configuration parameters below before launching the workspace.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow('Name', widget.name.trim(), theme),
                    const Divider(height: 24),
                    _buildSummaryRow('Logo', widget.logo, theme),
                    const Divider(height: 24),
                    _buildSummaryRow('Modules', widget.modules.join(', '), theme),
                    const Divider(height: 24),
                    _buildSummaryRow('Channels', widget.channels.join(', '), theme),
                    const Divider(height: 24),
                    _buildSummaryRow('Visibility', widget.visibility, theme),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLaunching ? null : _launchWorkspace,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLaunching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Launch Workspace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
