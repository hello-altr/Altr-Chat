// Packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nativeapi/nativeapi.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

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
import 'package:chat/theme/app_theme.dart'; 
import 'package:chat/values.dart';

// Firebase
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    final window = WindowManager.instance.getCurrent();
    window?.setMinimumSize(kMinWindowSize.width, kMinWindowSize.height);
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); 
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const AltrChat(),
  ));
}

final splashDelayProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(seconds: 2));
});

class AltrChat extends ConsumerWidget {
  const AltrChat({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearanceState = ref.watch(appearanceProvider);
    final currentThemeMode = appearanceState.themeMode;
    final accentSeedColor = appearanceState.accentSeedColor;
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
      theme: AltrTheme.buildTheme(ThemeMode.light, accentSeedColor),
      darkTheme: AltrTheme.buildTheme(ThemeMode.dark, accentSeedColor),
      themeMode: currentThemeMode,
    );
  }
}
