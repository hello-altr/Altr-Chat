// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Layouts
import 'package:chat/layout/desktop_shell.dart';
import 'package:chat/layout/mobile_shell.dart';

// Providers
import 'package:chat/providers/layout_provider.dart';

// Enums
import 'package:chat/enums/layout_mode.dart';

class LayoutShell extends ConsumerWidget {
  const LayoutShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final LayoutMode mode = constraints.maxWidth < 840
            ? LayoutMode.mobile
            : LayoutMode.desktop;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final oldMode = ref.read(layoutProvider);
          if (oldMode != mode) {
            ref.read(layoutProvider.notifier).state = mode;
          }
        });

        switch (mode) {
          case LayoutMode.mobile:
            return const MobileShell();
          case LayoutMode.desktop:
            return const DesktopShell();
        }
      },
    );
  }
}
