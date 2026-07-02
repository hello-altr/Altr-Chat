// Packages
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:flutter/material.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28), // Pill shape border radius
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              HugeIconsStroke.search01,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
              size: 20,
            ),
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: onClear,
                  ),
              )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
