// Packages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Widgets
import 'package:chat/widgets/navigation/workspace_sidebar.dart';

class WorkspaceChannelsTree extends ConsumerWidget {
  const WorkspaceChannelsTree({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WorkspaceSidebar(
      initialSection: SidebarSection.channels,
    );
  }
}

class ChannelsStageView extends StatelessWidget {
  const ChannelsStageView({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkspaceChannelsTree();
  }
}
