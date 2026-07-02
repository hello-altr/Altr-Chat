// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Layouts
import 'package:chat/layout/desktop_shell.dart';
import 'package:chat/layout/mobile_shell.dart';

// Providers
import 'package:chat/providers/chat_state_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/nav_provider.dart';

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
            final currentIndex = ref.read(navIndexProvider);
            
            // Sync navigation tab state transition metrics
            if (mode == LayoutMode.desktop) {
              // Transition: Mobile -> Desktop
              // Mobile tabs: 0(Channels), 1(DMs), 2(Settings), 3(Profile)
              // Desktop tabs: 0(Channels), 1(DMs), 2(Settings)
              if (currentIndex == 2) {
                // If on Settings in mobile, load settings on desktop with settings dashboard active in Column 2
                ref.read(isProfileActiveInSettingsDesktopProvider.notifier).state = false;
                ref.read(navIndexProvider.notifier).state = 2;
              } else if (currentIndex == 3) {
                // If on Profile in mobile, load settings on desktop and set ProfileCardInspector as active Column 2
                ref.read(isProfileActiveInSettingsDesktopProvider.notifier).state = true;
                ref.read(navIndexProvider.notifier).state = 2;
              }
            } else {
              // Transition: Desktop -> Mobile
              // Desktop tabs: 0(Channels), 1(DMs), 2(Settings)
              // Mobile tabs: 0(Channels), 1(DMs), 2(Settings), 3(Profile)
              if (currentIndex == 2) {
                final isProfileActive = ref.read(isProfileActiveInSettingsDesktopProvider);
                if (isProfileActive) {
                  ref.read(navIndexProvider.notifier).state = 3; // Profile
                } else {
                  ref.read(navIndexProvider.notifier).state = 2; // Settings
                }
              }
            }

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
