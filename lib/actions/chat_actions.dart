// Packages
import 'package:material_ui/material_ui.dart';

class ChatActions {
  static void triggerCreateChannel(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Triggering Workspace Channel Creation Wizard...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void triggerNewDm(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Triggering Global Directory Search Drawer...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
