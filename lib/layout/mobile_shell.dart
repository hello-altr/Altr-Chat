// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/workspace_dropdown_switcher.dart';
import 'package:chat/widgets/floating_nav_pill.dart';

// Providers
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/nav_provider.dart';

// Pages
import 'package:chat/pages/shared_chat_canvas.dart';
import 'package:chat/pages/settings_page.dart';
import 'package:chat/pages/channels_page.dart';
import 'package:chat/pages/dms_page.dart';

class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key});

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(navIndexProvider);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatSession = ref.watch(activeChatSessionProvider);
    final selectedIndex = ref.watch(navIndexProvider);
    final activeSettingsPanel = ref.watch(activeSettingsPanelProvider);

    // Listen for tab taps inside the FloatingNavPill to animate the PageView smoothly
    ref.listen<int>(navIndexProvider, (previous, next) {
      if (_pageController.hasClients && next != _pageController.page?.round()) {
        if (previous != null && (next - previous).abs() > 1) {
          _pageController.jumpToPage(next);
        } else {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    });

    final showNavPill = chatSession.type == ChatSessionType.none && activeSettingsPanel == SettingsPanelType.none;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Layer 1: Core underlying PageView grid lanes
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              // Write swipe transitions back up into global Riverpod provider state
              ref.read(navIndexProvider.notifier).state = index;
            },
            children: const [
              DmsStageView(),          // Index 0
              ChannelsStageView(),     // Index 1 (Home default landing base)
              SettingsIndexHub(),      // Index 2
            ],
          ),
          // Layer 1.5: Fixed Top-Right Workspace Switcher
          if (showNavPill)
            Positioned(
              top: 12.0 + MediaQuery.of(context).padding.top,
              right: 16.0,
              child: const WorkspaceDropdownSwitcher(),
            ),

          // Layer 2: RESPONSIVE FULL-BLEED ACTIVE OVERLAY
          // Captures absolute mobile priority focus whenever a chat session is declared active globally
          if (chatSession.type != ChatSessionType.none && chatSession.chatId != null)
            Positioned.fill(
              child: SharedChatCanvas(
                chatId: chatSession.chatId,
                isReadOnly: false,
              ),
            ),

          // Layer 2.5: Profile full-screen stack overlay
          if (selectedIndex == 2 && activeSettingsPanel == SettingsPanelType.profile)
            const Positioned.fill(
              child: ProfileCardInspector(),
            ),

          // Layer 2.6: Appearance full-screen stack overlay
          if (selectedIndex == 2 && activeSettingsPanel == SettingsPanelType.appearance)
            const Positioned.fill(
              child: AppearanceSettingsPanel(),
            ),

          // Layer 3: Main Navigation Pill (Only visible when overlay slide layer is detached)
          if (showNavPill)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavPill(isDesktop: false),
            ),
        ],
      ),
    );
  }
}