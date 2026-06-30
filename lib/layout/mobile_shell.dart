// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/layout_provider.dart';

class MobileShell extends ConsumerWidget {
  const MobileShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(layoutProvider);

    return Scaffold(
      // TODO: Replace with actual content
      body: const Placeholder(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // Blur overlay backing rules derived from your PRD UI framework specifications
          color: Theme.of(context).colorScheme.surface.withAlpha(200),
        ),
        child: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.chat), label: 'Chats'),
            NavigationDestination(icon: Icon(Icons.hub), label: 'Aero Hub'),
            NavigationDestination(
              icon: Icon(Icons.school),
              label: 'Aero Learn',
            ),
          ],
        ),
      ),
    );
  }
}
