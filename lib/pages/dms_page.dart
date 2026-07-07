// Packages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Widgets
import 'package:chat/widgets/navigation/workspace_sidebar.dart';

class DirectMessagesList extends ConsumerWidget {
  const DirectMessagesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WorkspaceSidebar(
      initialSection: SidebarSection.dms,
    );
  }
}

class DmsStageView extends StatelessWidget {
  const DmsStageView({super.key});

  @override
  Widget build(BuildContext context) {
    return const DirectMessagesList();
  }
}
