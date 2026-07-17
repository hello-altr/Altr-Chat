// Packages
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

class UniversalSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String searchQuery;

  const UniversalSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(
        color: theme.colorScheme.outlineVariant.withAlpha(80),
      ),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
        ),
        prefixIcon: Icon(
          HugeIconsStroke.search01,
          color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
          size: 20,
        ),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHigh,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
