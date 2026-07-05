// Packages
import 'package:material_ui/material_ui.dart';

class SegmentedOnboardingProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStepIndex;

  const SegmentedOnboardingProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStepIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> children = [];
    for (int index = 0; index < totalSteps; index++) {
      final isCompleted = index < currentStepIndex;
      final isActive = index == currentStepIndex;

      children.add(
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              return Container(
                height: 4.0,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(100),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: isCompleted
                          ? maxWidth
                          : (isActive ? maxWidth : 0.0),
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      if (index < totalSteps - 1) {
        children.add(const SizedBox(width: 6));
      }
    }

    return Row(
      children: children,
    );
  }
}
