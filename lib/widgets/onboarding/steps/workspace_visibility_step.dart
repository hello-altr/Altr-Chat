// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/auth_provider.dart';

// Values
import 'package:chat/exclusions.dart';

class WorkspaceVisibilityStep extends ConsumerWidget {
  final String selectedVisibility;
  final ValueChanged<String> onVisibilityChanged;
  final VoidCallback onNext;

  const WorkspaceVisibilityStep({
    super.key,
    required this.selectedVisibility,
    required this.onVisibilityChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Parse user's email domain and check constraints
    final user = ref.watch(authStateProvider).value;
    final email = user?.email ?? '';
    bool isExcluded = false;
    if (email.isNotEmpty && email.contains('@')) {
      final domain = email.split('@').last.toLowerCase();
      isExcluded = excludedWorkspaceDomains.contains(domain);
    }

    // Force fallback to 'Private' if domain is excluded
    if (isExcluded && selectedVisibility != 'Private') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onVisibilityChanged('Private');
      });
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visibility Rules',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose whether this workspace is open to discovery or hidden from public registries.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                // Private Card (Always available)
                _buildVisibilityCard(
                  title: 'Private Only',
                  description: 'Workspace is hidden. Members can only join by a direct alphanumeric token.',
                  isSelected: selectedVisibility == 'Private',
                  onTap: () => onVisibilityChanged('Private'),
                  theme: theme,
                ),
                const SizedBox(height: 16),

                // Discoverable Card (Disabled if domain is excluded)
                _buildVisibilityCard(
                  title: 'Discoverable',
                  description: 'Workspace can be searched and joined by users sharing your verified domain.',
                  isSelected: selectedVisibility == 'Discoverable',
                  onTap: isExcluded ? null : () => onVisibilityChanged('Discoverable'),
                  theme: theme,
                  disabled: isExcluded,
                ),

                if (isExcluded) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error.withAlpha(100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your authenticated email domain is restricted under domain constraints. Discoverable workspaces are locked out.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Text('Next'),
              label: const Icon(Icons.arrow_forward, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityCard({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback? onTap,
    required ThemeData theme,
    bool disabled = false,
  }) {
    final opacity = disabled ? 0.45 : 1.0;
    return Opacity(
      opacity: opacity,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withAlpha(80),
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected
            ? theme.colorScheme.primaryContainer.withAlpha(50)
            : theme.colorScheme.surfaceContainerHigh,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(
                  title == 'Private Only' ? Icons.lock_outline : Icons.public_outlined,
                  size: 28,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
