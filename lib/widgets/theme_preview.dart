// Packages
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/theme_preview_window.dart';

class ThemePreview extends StatelessWidget {
  final ThemeMode mode;
  final bool isSelected;
  final Color selectedColor;
  final bool isMobile;

  const ThemePreview({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.selectedColor,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: isMobile ? 120 : 120,
      height: isMobile ? 220 : 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withAlpha(80),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: mode == ThemeMode.system
            ? Row(
                children: [
                  Expanded(
                    child: ThemePreviewWindow(
                      isDark: false,
                      isSplit: true,
                      selectedColor: selectedColor,
                      isMobile: isMobile,
                    ),
                  ),
                  Expanded(
                    child: ThemePreviewWindow(
                      isDark: true,
                      isSplit: true,
                      selectedColor: selectedColor,
                      isMobile: isMobile,
                    ),
                  ),
                ],
              )
            : ThemePreviewWindow(
                isDark: mode == ThemeMode.dark,
                isSplit: false,
                selectedColor: selectedColor,
                isMobile: isMobile,
              ),
      ),
    );
  }
}
