// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/floating_nav_pill.dart';

class MobileShell extends ConsumerWidget {
  const MobileShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch index changes from the navigation pill provider hook
    final navIndex = ref.watch(mobileNavIndexProvider);

    // Map content view stages dynamically without destructive route replacements
    final Widget currentStageView;
    switch (navIndex) {
      case 0:
        currentStageView = const Center(
          child: Text("Chats Directory Feed Pane"),
        );
        break;
      case 1:
        currentStageView = const Center(
          child: Text("Aero Hub Functional Arena"),
        );
        break;
      case 2:
        currentStageView = const Center(
          child: Text("Aero Learn LMS Module Space"),
        );
        break;
      default:
        currentStageView = const Placeholder();
    }

    return Scaffold(
      // Extends content underneath the floating pill boundaries to activate translucent lookovers
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: currentStageView),
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
