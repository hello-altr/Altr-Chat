// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/floating_nav_pill.dart';

// Providers
import 'package:chat/providers/nav_provider.dart';
import 'package:chat/providers/chat_session_provider.dart';

// Pages
import 'package:chat/pages/profile_and_settings_page.dart';
import 'package:chat/pages/shared_chat_canvas.dart';
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

    // Listen for tab taps inside the FloatingNavPill to animate the PageView smoothly
    ref.listen<int>(navIndexProvider, (previous, next) {
      if (_pageController.hasClients && next != _pageController.page?.round()) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
        );
      }
    });

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
              ChannelsStageView(),     // Index 0 (Home default landing base)
              DmsStageView(),          // Index 1
              SettingsIndexHub(),      // Index 2
              ProfileStageView(),      // Index 3
            ],
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

          // Layer 3: Main Navigation Pill (Only visible when overlay slide layer is detached)
          if (chatSession.type == ChatSessionType.none)
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