// Packages
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/workspace_flow_canvas.dart';

// Enums & Values
import 'package:chat/enums/onboarding_enums.dart';

class WorkspaceOnboardingPage extends StatelessWidget {
  const WorkspaceOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 840;
          if (isMobile) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                // Intercept back action to prevent dropping context
              },
              child: const WorkspaceFlowCanvas(
                contextType: WorkspaceFlowContext.appStart,
              ),
            );
          } else {
            final theme = Theme.of(context);
            return Scaffold(
              backgroundColor: theme.colorScheme.surface,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 680,
                    maxHeight: 600,
                  ),
                  child: Card(
                    elevation: 12,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: theme.colorScheme.surfaceContainer,
                    child: const WorkspaceFlowCanvas(
                      contextType: WorkspaceFlowContext.appStart,
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
