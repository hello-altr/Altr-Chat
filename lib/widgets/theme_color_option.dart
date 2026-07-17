// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/appearance_notifier.dart';

class ThemeColorOptionItem extends ConsumerWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final bool isMobile;

  const ThemeColorOptionItem({
    super.key,
    required this.color,
    required this.label,
    required this.isSelected,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final circleSize = isMobile ? 48.0 : 40.0;
    return GestureDetector(
      onTap: () {
        ref.read(appearanceProvider.notifier).updateAccentColor(color);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: circleSize,
        height: circleSize,
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
    );
  }
}
