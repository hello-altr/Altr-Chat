// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/appearance_notifier.dart';

// Widgets
import 'package:chat/widgets/theme_preview.dart';

class ThemeModeOption extends ConsumerWidget {
  final ThemeMode mode;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final bool isMobile;

  const ThemeModeOption({
    super.key,
    required this.mode,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        ref.read(appearanceProvider.notifier).updateThemeMode(mode);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isMobile
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          ThemePreview(
            mode: mode,
            isSelected: isSelected,
            selectedColor: selectedColor,
            isMobile: isMobile,
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
