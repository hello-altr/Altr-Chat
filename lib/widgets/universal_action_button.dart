// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Actions
import 'package:chat/actions/chat_actions.dart';

class UniversalActionButton extends ConsumerWidget {
  final GlobalKey buttonKey;
  final bool isDesktop;

  const UniversalActionButton({
    super.key,
    required this.buttonKey,
    this.isDesktop = false,
  });

  void _showQuickActionMenu(BuildContext context, ThemeData theme) async {
    final RenderBox? buttonBox = buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null) return;

    final Offset offset = buttonBox.localToGlobal(Offset.zero);
    final Size size = buttonBox.size;

    // Compute layout matrix coordinates contextually based on responsive mode
    final RelativeRect position = isDesktop
        ? RelativeRect.fromLTRB(
            offset.dx + size.width + 8, // Shift right clear of the desktop rail lines
            offset.dy - 60,            // Center vertically alongside the trigger circle
            offset.dx + size.width + 220,
            offset.dy + size.height,
          )
        : RelativeRect.fromLTRB(
            offset.dx,
            offset.dy - 110,           // Shift vertically upward above the mobile nav capsule
            offset.dx + size.width,
            offset.dy,
          );

    await showMenu<String>(
      context: context,
      position: position,
      elevation: 3,
      color: theme.colorScheme.surfaceContainerHigh, // Solid M3 container block
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem<String>(
          value: 'new_dm',
          child: Row(
            children: [
              Icon(HugeIconsStroke.chat01, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text('New Direct Message', style: TextStyle(color: theme.colorScheme.onSurface)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'create_channel',
          child: Row(
            children: [
              Icon(HugeIconsStroke.hashtag, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text('Create Channel', style: TextStyle(color: theme.colorScheme.onSurface)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null || !context.mounted) return;
      switch (value) {
        case 'new_dm':
          ChatActions.triggerNewDm(context);
          break;
        case 'create_channel':
          ChatActions.triggerCreateChannel(context);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return IconButton(
      key: buttonKey, // Anchor the physical geometric finder targets natively here
      onPressed: () => _showQuickActionMenu(context, theme),
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        minimumSize: const Size(56, 56),
        maximumSize: const Size(56, 56),
        shape: const CircleBorder(),
        elevation: isDesktop ? 2 : 0, // Match the elevation strategy of each view shell
      ),
      icon: const Icon(HugeIconsSolid.plusSign, size: 24),
    );
  }
}