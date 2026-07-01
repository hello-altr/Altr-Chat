// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/chat_state_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/nav_provider.dart';

// Widgets
import 'package:chat/widgets/floating_nav_pill.dart';

// Pages
import 'package:chat/pages/profile_and_settings_page.dart';
import 'package:chat/pages/channels_page.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:chat/pages/dms_page.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navIndexProvider);
    final activeChatId = ref.watch(activeChatIdProvider);
    final isProfileActive = ref.watch(isProfileActiveInSettingsDesktopProvider);
    final theme = Theme.of(context);

    // Column 1 Layout Selector (Sidebar Column - Fixed Width 300)
    final Widget leftDirectorySidebar = switch (selectedIndex) {
      0 => const DirectMessagesList(),
      1 => const WorkspaceChannelsTree(),
      2 => const SettingsIndexHub(),
      _ => const SizedBox.shrink(),
    };

    // Column 2 Layout Selector (Main Content View)
    final Widget centralViewCanvas = switch (selectedIndex) {
      0 => activeChatId != null
          ? ChatPage(
              chatId: activeChatId,
              isChannel: false,
              key: ValueKey('dm-$activeChatId'),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    HugeIconsStroke.chat01,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Active DMs Chat Space Preview",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a conversation to start chatting.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
      1 => activeChatId != null
          ? ChatPage(
              chatId: activeChatId,
              isChannel: true,
              key: ValueKey('channel-$activeChatId'),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    HugeIconsStroke.hashtag,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Active Channels Chat Space Preview",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a channel to view the workspace.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
      2 => isProfileActive
          ? const ProfileCardInspector()
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    HugeIconsStroke.settings01,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Aero Settings Details Canvas",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Click the profile banner or preferences to view details.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
      _ => const SizedBox.shrink(),
    };

    return Scaffold(
      body: Row(
        children: [
          // Column 1: Left Directory Drawer Panel (Fixed Width 300)
          SizedBox(
            width: 300,
            child: Column(
              children: [
                Expanded(child: leftDirectorySidebar),
                const FloatingNavPill(isDesktop: true),
              ],
            ),
          ),

          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant,
          ),

          // Column 2: Central Context Communication Stage Canvas
          Expanded(child: centralViewCanvas),
        ],
      ),
    );
  }
}
