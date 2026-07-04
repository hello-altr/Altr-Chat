// Packages
import 'package:material_ui/material_ui.dart';

class WorkspaceModulesStep extends StatelessWidget {
  final List<String> selectedModules;
  final ValueChanged<List<String>> onModulesChanged;
  final VoidCallback onNext;

  const WorkspaceModulesStep({
    super.key,
    required this.selectedModules,
    required this.onModulesChanged,
    required this.onNext,
  });

  static const List<String> _availableModules = [
    'Altr Chats',
    'Altr LMS',
    'Altr Hub',
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
            'Initialize Feature Modules',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select which default tools you want to make available immediately.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _availableModules.length,
              itemBuilder: (context, idx) {
                final module = _availableModules[idx];
                final isSelected = selectedModules.contains(module);
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withAlpha(50)
                      : theme.colorScheme.surfaceContainerLow,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      final updated = List<String>.from(selectedModules);
                      if (val == true) {
                        if (!updated.contains(module)) {
                          updated.add(module);
                        }
                      } else {
                        // Prevent clearing Altr Chats since it is the core module
                        if (module != 'Altr Chats') {
                          updated.remove(module);
                        }
                      }
                      onModulesChanged(updated);
                    },
                    title: Text(
                      module,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      module == 'Altr Chats'
                          ? 'Real-time collaborative channels & DMs'
                          : module == 'Altr LMS'
                              ? 'Interactive learning materials & courses'
                              : 'Unified dashboard widgets & portals',
                      style: theme.textTheme.bodySmall,
                    ),
                    secondary: Icon(
                      module == 'Altr Chats'
                          ? Icons.chat_bubble_outline
                          : module == 'Altr LMS'
                              ? Icons.school_outlined
                              : Icons.widgets_outlined,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    activeColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
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
