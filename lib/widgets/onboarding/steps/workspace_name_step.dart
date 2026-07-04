// Packages
import 'package:material_ui/material_ui.dart';

class WorkspaceNameStep extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onNext;

  const WorkspaceNameStep({
    super.key,
    required this.nameController,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Name your workspace',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a clear name for your organization. You can edit this later in settings.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            key: const Key('workspace_name_field'),
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Workspace Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a workspace name')),
                  );
                  return;
                }
                onNext();
              },
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
