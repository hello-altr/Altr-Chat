// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/theme_provider.dart';

// Widgets
import 'package:chat/widgets/theme_preview.dart';

class ThemeModeOption extends ConsumerWidget {
  final ThemeMode mode;
  final String label;
  final bool isSelected;
  final ThemeColorOption selectedColor;

  const ThemeModeOption({
    super.key,
    required this.mode,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThemePreview(
            mode: mode,
            isSelected: isSelected,
            selectedColor: selectedColor,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
