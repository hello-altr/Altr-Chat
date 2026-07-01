// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

final mobileNavIndexProvider = StateProvider<int>((ref) => 1);

class FloatingNavPill extends ConsumerWidget {
  const FloatingNavPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey actionButtonKey = GlobalKey();

    final selectedIndex = ref.watch(mobileNavIndexProvider);
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> navItems = [
      {
        'icon': HugeIconsStroke.chat01,
        'activeIcon': HugeIconsSolid.chat01,
        'label': 'DMS',
      },
      {
        'icon': HugeIconsStroke.hashtag,
        'activeIcon': HugeIconsSolid.hashtag,
        'label': 'Channels',
      },
      {
        'icon': HugeIconsStroke.megaphone01,
        'activeIcon': HugeIconsSolid.megaphone01,
        'label': 'Updates',
      },
      {
        'icon': HugeIconsStroke.userCircle02,
        'activeIcon': HugeIconsSolid.userCircle02,
        'label': 'Profile',
      },
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        child: Row(
          children: [
            // --- PILL 1: The Main Navigation Bar Window Container ---
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withAlpha(25),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    color: theme.colorScheme.surface.withAlpha(160),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(navItems.length, (index) {
                        final item = navItems[index];
                        final isSelected = selectedIndex == index;

                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              ref.read(mobileNavIndexProvider.notifier).state =
                                  index;
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.fastOutSlowIn,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: isSelected
                                        ? theme.colorScheme.primaryContainer
                                        : Colors.transparent,
                                  ),
                                  child: Icon(
                                    isSelected
                                        ? item['activeIcon']
                                        : item['icon'],
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['label'],
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ), // Strict Apple layout margin gap alignment
            // --- PILL 2: Pinned Standalone Action Overlay Capsule ---
            IconButton(
              key: actionButtonKey,
              onPressed: () =>
                  _showQuickActionMenu(context, actionButtonKey, theme),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(56, 56),
                maximumSize: const Size(56, 56),
                shape: const CircleBorder(),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionMenu(
    BuildContext context,
    GlobalKey actionButtonKey,
    ThemeData theme,
  ) async {
    // 1. Extract the physical layout boundaries of the specific button node
    final RenderBox? buttonBox =
        actionButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null) return;

    // 2. Fetch the absolute pixel coordinates of the floating icon circle container
    final Offset buttonOffset = buttonBox.localToGlobal(Offset.zero);
    final Size buttonSize = buttonBox.size;

    // 3. Construct a bounded window directly over the icon radius layer
    // This tells showMenu explicitly where the popup must materialize
    final RelativeRect menuPosition = RelativeRect.fromLTRB(
      buttonOffset.dx,
      buttonOffset.dy -
          110, // Forces the container upwards by subtracting height vectors
      buttonOffset.dx + buttonSize.width,
      buttonOffset.dy,
    );

    // 4. Instantiate the Material 3 flat container box overlay
    await showMenu<String>(
      context: context,
      position: menuPosition,
      elevation: 3,
      color: theme
          .colorScheme
          .surfaceContainerHigh, // Solid M3 design target block [cite: 748]
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem<String>(
          value: 'new_dm',
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'New Direct Message',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'create_channel',
          child: Row(
            children: [
              Icon(Icons.tag, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Create Channel',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'new_dm':
          // Handle DM generation state mutations [cite: 1112]
          break;
        case 'create_channel':
          // Handle workspace creation wizard loops [cite: 1091]
          break;
      }
    });
  }
}
