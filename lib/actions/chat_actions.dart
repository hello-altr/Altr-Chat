// Packages
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/chat/creation_flow_modal.dart';

class ChatActions {
  static void triggerCreateChannel(BuildContext context) {
    showCreationFlowModal(context, isChannel: true);
  }

  static void triggerNewDm(BuildContext context) {
    showCreationFlowModal(context, isChannel: false);
  }

  static void triggerInviteCoworkers(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Triggering Invite Coworkers Modal...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
