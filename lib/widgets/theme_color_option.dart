// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/appearance_notifier.dart';

class ThemeColorOptionItem extends ConsumerWidget {
  final Color color;
  final String label;
  final bool isSelected;

  const ThemeColorOptionItem({
    super.key,
    required this.color,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        ref.read(appearanceProvider.notifier).updateAccentColor(color);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2.0)
                  : null,
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : (label.isEmpty
                        ? Colors.transparent
                        : theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
