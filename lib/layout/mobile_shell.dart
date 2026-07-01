// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/floating_nav_pill.dart';

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
    // Read the initial state (Index 1) to boot natively straight into Channels
    final initialIndex = ref.read(mobileNavIndexProvider);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for tab taps inside the FloatingNavPill to animate the PageView smoothly
    ref.listen<int>(mobileNavIndexProvider, (previous, next) {
      if (next != _pageController.page?.round()) {
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
          // Infinite canvas stage mapping to your verified [DMs, Channels, Updates, Profile] matrix
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              // Write swipe transitions back up into your global Riverpod provider state
              ref.read(mobileNavIndexProvider.notifier).state = index;
            },
            children: const [
              Center(child: Text("DMs Stage View")), // Index 0
              Center(child: Text("Channels Stage View")), // Index 1 (Home Base)
              Center(child: Text("Updates Stage View")), // Index 2
              Center(child: Text("Profile Stage View")), // Index 3
            ],
          ),

          // Floating overlay layers remain persistently fixed over the viewport
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavPill(),
          ),
        ],
      ),
    );
  }
}