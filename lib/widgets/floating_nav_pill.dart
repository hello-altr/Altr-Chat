// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/universal_action_button.dart';

// Providers
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/nav_provider.dart';

class FloatingNavPill extends ConsumerWidget {
  final bool isDesktop;

  const FloatingNavPill({
    super.key,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey actionButtonKey = GlobalKey();
    final selectedIndex = ref.watch(navIndexProvider);
    final theme = Theme.of(context);

    // Watch layout-specific navigation items configuration
    final navItems = ref.watch(
      isDesktop ? desktopNavItemsProvider : mobileNavItemsProvider,
    );

    final content = Row(
      children: [
        // --- PILL 1: The Main Navigation Bar Window Container ---
        Expanded(
          child: Container(
            height: isDesktop ? 54 : 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isDesktop ? 28 : 44),
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
              borderRadius: BorderRadius.circular(isDesktop ? 28 : 44),
              child: Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(navItems.length, (index) {
                    final item = navItems[index];
                    final isSelected = selectedIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          ref.read(navIndexProvider.notifier).state = index;
                          ref.read(activeChatSessionProvider.notifier).state = const ActiveChatSession();
                          ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.fastOutSlowIn,
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 10 : 16,
                                vertical: isDesktop ? 2 : 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                                size: isDesktop ? 18 : 22,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: isDesktop ? 9 : 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        const SizedBox(width: 8),
        // --- PILL 2: Pinned Standalone Action Overlay Capsule ---
        UniversalActionButton(
          buttonKey: actionButtonKey,
          isDesktop: isDesktop,
        ),
      ],
    );

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: content,
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        child: content,
      ),
    );
  }
}