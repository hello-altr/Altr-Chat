// Packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';

// Layout Shell
import 'package:chat/layout_shell.dart';

// Providers
import 'package:chat/providers/appearance_notifier.dart';
import 'package:chat/providers/auth_provider.dart';

// Services
import 'package:chat/services/window_config.dart';

// Pages
import 'package:chat/pages/workspace_onboarding_page.dart';
import 'package:chat/pages/onboarding_page.dart';
import 'package:chat/pages/welcome_page.dart';
import 'package:chat/pages/splash_page.dart';

// Theme & Utils
import 'package:chat/theme/app_theme.dart';

// Firebase
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely configures desktop windows on macOS without breaking the Web
  if (!kIsWeb) {
    configureDesktopWindow();
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure Firestore offline persistence/local cache settings
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  final prefs = await SharedPreferences.getInstance();

  final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
  if (isFirstLaunch) {
    log('First Launch', name: 'Launch');
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}
    await prefs.setBool('is_first_launch', false);
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AltrChat(),
    ),
  );
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

          if (altrUser.joinedWorkspaces.isEmpty) {
            return const WorkspaceOnboardingPage();
          }

          final activeWorkspaceId = altrUser.activeWorkspaceId;
          if (activeWorkspaceId.isEmpty) {
            final fallbackWorkspace = altrUser.joinedWorkspaces.first;
            FirebaseFirestore.instance
                .collection('users')
                .doc(altrUser.userId)
                .collection('devices')
                .doc(deviceId)
                .set({
                  'device_id': deviceId,
                  'active_workspace_id': fallbackWorkspace,
                  'last_active': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
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
