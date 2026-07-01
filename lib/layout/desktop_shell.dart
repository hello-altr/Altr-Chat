// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Providers & Decoupled Widgets
import 'package:chat/providers/nav_provider.dart';
import 'package:chat/widgets/fixed_nav_rail.dart'; // Import your clean rail widget

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navIndexProvider);
    final theme = Theme.of(context);

    // Map Column 1 lists based on shared nav context
    final Widget leftSidebarPane;
    switch (selectedIndex) {
      case 0:
        leftSidebarPane = const Center(child: Text("Direct Messages List"));
        break;
      case 1:
        leftSidebarPane = const Center(child: Text("Workspace Channels Tree"));
        break;
      case 2:
        leftSidebarPane = const Center(child: Text("Announcements History"));
        break;
      case 3:
        leftSidebarPane = const Center(child: Text("Settings Index Hub"));
        break;
      default:
        leftSidebarPane = const SizedBox.shrink();
    }

    // Map Column 2 stage content canvas views
    final Widget centralFeedStage;
    switch (selectedIndex) {
      case 0:
      case 1:
        centralFeedStage = const Center(
          child: Text("Active Messaging Canvas Feed"),
        );
        break;
      case 2:
        centralFeedStage = const Center(
          child: Text("Read-Only Notice Board Display"),
        );
        break;
      case 3:
        centralFeedStage = const Center(
          child: Text("Account and Bio Matrix Editor"),
        );
        break;
      default:
        centralFeedStage = const SizedBox.shrink();
    }

    return Scaffold(
      body: Row(
        children: [
          // Mount your cleanly decoupled navigation component instantly!
          const FixedNavRail(),

          // Column 1: Left Directory Drawer Panel (Fixed Width)
          SizedBox(width: 300, child: leftSidebarPane),

          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant,
          ),

          // Column 2: Central Context Communication Stage Canvas
          Expanded(child: centralFeedStage),
        ],
      ),
    );
  }
}
