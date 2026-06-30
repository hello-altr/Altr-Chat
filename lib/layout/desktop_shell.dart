// Packages
import 'package:material_ui/material_ui.dart';

class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Boundary Rail (Navigation PageRail for Ecosystem Jumps)
          NavigationRail(
            selectedIndex: 0,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.chat),
                label: Text('Aero Chat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.school),
                label: Text('Aero Learn'),
              ),
            ],
          ),
          // Column 1: Left Workspace Sidebar (Fixed Width)
          const SizedBox(
            width: 300,
            child:
                Placeholder(),
            // TODO: Replace with actual content
          ),
          // Column 2: Central Communication Stage
          const Expanded(
            child: Placeholder(),
            // TODO: Replace with actual content
          ),
          // Column 3: Contextual Right Sidebar Panel (Permanent at >= 1200dp)
          const SizedBox(width: 360, child: Placeholder()),
          // TODO: Replace with actual content
        ],
      ),
    );
  }
}
