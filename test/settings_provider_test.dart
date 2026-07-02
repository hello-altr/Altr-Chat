// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Providers
import 'package:chat/providers/settings_provider.dart';

void main() {
  group('activeSettingsPanelProvider Tests', () {
    test('Initial active settings panel is SettingsPanelType.none', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(activeSettingsPanelProvider), SettingsPanelType.none);
    });

    test('Updating activeSettingsPanelProvider updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.profile;
      expect(container.read(activeSettingsPanelProvider), SettingsPanelType.profile);

      container.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.appearance;
      expect(container.read(activeSettingsPanelProvider), SettingsPanelType.appearance);

      container.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
      expect(container.read(activeSettingsPanelProvider), SettingsPanelType.none);
    });
  });
}
