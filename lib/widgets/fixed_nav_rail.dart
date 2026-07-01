// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/universal_action_button.dart';

// Providers
import 'package:chat/providers/nav_provider.dart';

class FixedNavRail extends ConsumerWidget {
  const FixedNavRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navIndexProvider);
    final navItems = ref.watch(aeroNavItemsProvider);
    final theme = Theme.of(context);
    final railButtonKey = GlobalKey();

    return NavigationRail(
      selectedIndex: selectedIndex,
      extended: false,
      elevation: null,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      labelType: NavigationRailLabelType.none,

      onDestinationSelected: (index) {
        ref.read(navIndexProvider.notifier).state = index;
      },
      // Bottom Utility '+' Action Node
      leading: SizedBox(height: 4),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Tooltip(
          message: 'Quick Actions',
          child: UniversalActionButton(
            buttonKey: railButtonKey,
            isDesktop: true,
          ),
        ),
      ),
      trailingAtBottom: true,
      destinations: List.generate(navItems.length, (index) {
        final item = navItems[index];
        return NavigationRailDestination(
          padding: .symmetric(vertical: 4.0),
          icon: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Icon(item.icon, color: theme.colorScheme.onSurfaceVariant),
          ),
          selectedIcon: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Icon(item.activeIcon, color: theme.colorScheme.primary),
          ),
          label: Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selectedIndex == index
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        );
      }),
    );
  }
}
