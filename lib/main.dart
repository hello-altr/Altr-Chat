// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

// Layout Shell
import 'package:chat/layout_shell.dart';

// Providers
import 'package:chat/providers/appearance_notifier.dart';
import 'package:chat/providers/auth_provider.dart';

// Pages
import 'package:chat/pages/workspace_onboarding_page.dart';
import 'package:chat/pages/onboarding_page.dart';
import 'package:chat/pages/welcome_page.dart';
import 'package:chat/pages/splash_page.dart';

// Theme & Utils
import 'package:chat/theme/theme.dart';
import 'package:chat/utils/util.dart';

// Firebase
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); 
  runApp(const ProviderScope(child: AltrChat()));
}

final splashDelayProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(seconds: 2));
});

class AltrChat extends ConsumerWidget {
  const AltrChat({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextTheme textTheme = createTextTheme(context, "Inter", "Montserrat");
    MaterialTheme theme = MaterialTheme(textTheme);
    final appearance = ref.watch(appearanceProvider);
    final currentThemeMode = appearance.themeMode;
    final accentSeedColor = appearance.accentSeedColor;
    final deviceIdAsync = ref.watch(deviceIdProvider);
    final userProfile = ref.watch(userProfileProvider);
    final splashDelay = ref.watch(splashDelayProvider);

    final Widget homeScreen;
    if (splashDelay.isLoading || deviceIdAsync.isLoading) {
      homeScreen = const SplashLoadingView();
    } else {
      final deviceId = deviceIdAsync.value ?? '';
      homeScreen = userProfile.when(
        data: (altrUser) {
          if (altrUser == null) {
            return const WelcomeAuthenticationView();
          }
          if (!altrUser.profileOnboardingCompleted) {
            return const ProfileOnboardingPage();
          }
          
          final activeWorkspaceId = altrUser.currentWorkspaces[deviceId];
          if (activeWorkspaceId == null || activeWorkspaceId.isEmpty) {
            return const WorkspaceOnboardingPage();
          }
          return const LayoutShell();
        },
        loading: () => const SplashLoadingView(),
        error: (err, stack) => const WelcomeAuthenticationView(),
      );
    }


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: homeScreen,
      theme: theme.light(accentSeedColor),
      darkTheme: theme.dark(accentSeedColor),
      themeMode: currentThemeMode,
    );
  }
}
