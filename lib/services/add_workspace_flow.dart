// Packages
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/onboarding/workspace_flow_canvas.dart';

// Enums
import 'package:chat/enums/onboarding_enums.dart';

void openAddWorkspaceFlow(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final isMobile = width < 840;

  if (isMobile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: WorkspaceFlowCanvas(
            contextType: WorkspaceFlowContext.settingsHub,
          ),
        ),
      ),
    );
  } else {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
              child: Card(
                elevation: 12,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: theme.colorScheme.surfaceContainer,
                child: WorkspaceFlowCanvas(
                  contextType: WorkspaceFlowContext.settingsHub,
                  onCompleted: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
