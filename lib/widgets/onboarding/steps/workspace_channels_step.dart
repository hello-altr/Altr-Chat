// Packages
import 'package:material_ui/material_ui.dart';

class WorkspaceChannelsStep extends StatelessWidget {
  final List<String> selectedChannels;
  final ValueChanged<List<String>> onChannelsChanged;
  final VoidCallback onNext;

  const WorkspaceChannelsStep({
    super.key,
    required this.selectedChannels,
    required this.onChannelsChanged,
    required this.onNext,
  });

  static const List<String> _availableChannels = [
    '#general',
    '#announcements',
    '#random',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bootstrap Channels',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select which channel filters to initialize in this new workspace.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableChannels.map((channel) {
                final isSelected = selectedChannels.contains(channel);
                return FilterChip(
                  label: Text(
                    channel,
                    style: TextStyle(
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    final updated = List<String>.from(selectedChannels);
                    if (val) {
                      if (!updated.contains(channel)) {
                        updated.add(channel);
                      }
                    } else {
                      // Keep at least one channel
                      if (updated.length > 1) {
                        updated.remove(channel);
                      }
                    }
                    onChannelsChanged(updated);
                  },
                  selectedColor: theme.colorScheme.primary,
                  checkmarkColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
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
}
