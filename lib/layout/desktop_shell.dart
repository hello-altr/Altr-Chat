// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/chat_state_provider.dart';
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/nav_provider.dart';

// Widgets
import 'package:chat/widgets/floating_nav_pill.dart';

// Pages
import 'package:chat/pages/profile_and_settings_page.dart';
import 'package:chat/pages/shared_chat_canvas.dart';
import 'package:chat/pages/channels_page.dart';
import 'package:chat/pages/dms_page.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  double _sidebarWidth = 400.0;
  late PageController _sidebarPageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(navIndexProvider);
    _sidebarPageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _sidebarPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navIndexProvider);
    final chatSession = ref.watch(activeChatSessionProvider);
    final isProfileActive = ref.watch(isProfileActiveInSettingsDesktopProvider);
    final theme = Theme.of(context);

    // Listen to tab selection changes to animate the horizontal PageView directory
    ref.listen<int>(navIndexProvider, (previous, next) {
      if (_sidebarPageController.hasClients && next != _sidebarPageController.page?.round()) {
        _sidebarPageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
        );
      }
    });

    // Column 2 Layout Selector (Main Content View)
    final Widget centralViewCanvas = switch (selectedIndex) {
      0 => chatSession.type == ChatSessionType.dm && chatSession.chatId != null
          ? SharedChatCanvas(
              chatId: chatSession.chatId,
              isReadOnly: false,
              key: ValueKey('dm-${chatSession.chatId}'),
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
      1 => chatSession.type == ChatSessionType.channel && chatSession.chatId != null
          ? SharedChatCanvas(
              chatId: chatSession.chatId,
              isReadOnly: false,
              key: ValueKey('channel-${chatSession.chatId}'),
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
          // Column 1: Left Directory Drawer Panel (Variable Width, Swipeable)
          SizedBox(
            width: _sidebarWidth,
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _sidebarPageController,
                    onPageChanged: (index) {
                      ref.read(navIndexProvider.notifier).state = index;
                      // Clear chat session trace
                      ref.read(activeChatSessionProvider.notifier).state = const ActiveChatSession();
                      ref.read(isProfileActiveInSettingsDesktopProvider.notifier).state = false;
                    },
                    children: const [
                      DirectMessagesList(),
                      WorkspaceChannelsTree(),
                      SettingsIndexHub(),
                    ],
                  ),
                ),
                const FloatingNavPill(isDesktop: true),
              ],
            ),
          ),

          // Resize drag handle divider
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(240.0, 480.0);
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: Container(
                width: 10,
                color: Colors.transparent,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Column 2: Central Context Communication Stage Canvas
          Expanded(child: centralViewCanvas),
        ],
      ),
    );
  }
}
