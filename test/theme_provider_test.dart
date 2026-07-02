// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/theme_provider.dart';

void main() {
  group('ThemeModeNotifier Tests', () {
    test('Initial theme mode is ThemeMode.system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('setThemeMode updates the theme mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      
      notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
