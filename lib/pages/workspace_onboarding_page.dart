// Packages
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/onboarding/workspace_flow_canvas.dart';

// Enums
import 'package:chat/enums/onboarding_enums.dart';

class WorkspaceOnboardingPage extends StatefulWidget {
  final WorkspaceFlowContext contextType;
  final VoidCallback? onCompleted;

  const WorkspaceOnboardingPage({
    super.key,
    this.contextType = WorkspaceFlowContext.appStart,
    this.onCompleted,
  });

  @override
  State<WorkspaceOnboardingPage> createState() => _WorkspaceOnboardingPageState();
}

class _WorkspaceOnboardingPageState extends State<WorkspaceOnboardingPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 840) {
          // Mobile Structural Presentation Shell
          return Scaffold(
            body: PopScope(
              canPop: widget.contextType == WorkspaceFlowContext.settingsHub, // Intercepts hardware back gestures at appStart
              child: WorkspaceFlowCanvas(
                contextType: widget.contextType,
                onCompleted: widget.onCompleted,
              ),
            ),
          );
        } else {
          // Desktop Structural Presentation Shell
          final isAppStart = widget.contextType == WorkspaceFlowContext.appStart;
          return Scaffold(
            backgroundColor: isAppStart
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            body: Stack(
              children: [
                // Translucent backdrop scrim layer mask blocking background interactions
                ModalBarrier(
                  // ignore: deprecated_member_use
                  color: isAppStart ? Colors.transparent : Colors.black.withOpacity(0.45),
                  dismissible: false,
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
                    child: Card(
                      clipBehavior: Clip.antiAlias, // Explicit anti-aliasing clipping mask boundary
                      child: WorkspaceFlowCanvas(
                        contextType: widget.contextType,
                        onCompleted: widget.onCompleted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
