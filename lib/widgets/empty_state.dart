// Package
import 'package:material_ui/material_ui.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final IconData? actionIcon; // Allow custom icons for actions to stay contextual

  // Secondary actions support
  final VoidCallback? onSecondaryActionPressed;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onActionPressed,
    this.actionLabel,
    this.actionIcon,
    this.onSecondaryActionPressed,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPrimary = onActionPressed != null && actionLabel != null;
    final hasSecondary = onSecondaryActionPressed != null && secondaryActionLabel != null;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Organic Visual Anchor Layer
              Stack(
                alignment: Alignment.center,
                children: [
                  // A soft, out-of-focus organic backdrop blur bubble
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                          theme.colorScheme.secondaryContainer.withValues(alpha: 0.02),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // The actual welcoming container bubble with an organic smooth shadow
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 40,
                      color: theme.colorScheme.primary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              
              // 2. Clear & Warm Copy Hierarchy
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // 3. Actions Row / Column
              if (hasPrimary || hasSecondary) ...[
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 240;

                    final List<Widget> buttons = [
                      if (hasPrimary)
                        FilledButton.icon(
                          onPressed: onActionPressed,
                          icon: Icon(actionIcon ?? Icons.add, size: 18),
                          label: Text(
                            actionLabel!,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      if (hasSecondary)
                        OutlinedButton.icon(
                          onPressed: onSecondaryActionPressed,
                          icon: Icon(secondaryActionIcon ?? Icons.link, size: 18),
                          label: Text(
                            secondaryActionLabel!,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                    ];

                    if (buttons.length == 1) {
                      return buttons.first;
                    }

                    if (isNarrow) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buttons[0],
                          const SizedBox(height: 12),
                          buttons[1],
                        ],
                      );
                    } else {
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: buttons,
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}