// Packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/appearance_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppearanceNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial appearance state uses defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(appearanceProvider);
      expect(state.themeMode, ThemeMode.system);
      expect(state.accentSeedColor, const Color(0xff096b5a));
    });

    test('updateThemeMode updates state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appearanceProvider.notifier);
      
      notifier.updateThemeMode(ThemeMode.dark);
      expect(container.read(appearanceProvider).themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('altr_theme_mode'), 'dark');
    });

    test('updateAccentColor updates state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appearanceProvider.notifier);
      
      notifier.updateAccentColor(Colors.red);
      expect(container.read(appearanceProvider).accentSeedColor, Colors.red);

      final prefs = await SharedPreferences.getInstance();
      // ignore: deprecated_member_use
      expect(prefs.getString('altr_accent_seed'), Colors.red.value.toRadixString(16));
    });

    test('AppearanceNotifier restores saved state on reconstruction', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('altr_theme_mode', 'dark');
      // ignore: deprecated_member_use
      await prefs.setString('altr_accent_seed', Colors.red.value.toRadixString(16));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger initial build
      container.read(appearanceProvider);

      // Wait for _loadFromPrefs asynchronous execution to finish
      await Future.delayed(const Duration(milliseconds: 50));

      final finalState = container.read(appearanceProvider);
      expect(finalState.themeMode, ThemeMode.dark);
      expect(finalState.accentSeedColor.value, Colors.red.value);
    });
  });
}
