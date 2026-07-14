// Packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class AppearanceState {
  final ThemeMode themeMode;
  final Color accentSeedColor;

  AppearanceState({
    required this.themeMode,
    required this.accentSeedColor,
  });

  AppearanceState copyWith({
    ThemeMode? themeMode,
    Color? accentSeedColor,
  }) {
    return AppearanceState(
      themeMode: themeMode ?? this.themeMode,
      accentSeedColor: accentSeedColor ?? this.accentSeedColor,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class AppearanceNotifier extends Notifier<AppearanceState> {
  static const String _themeModeKey = "altr_theme_mode";
  static const String _accentSeedKey = "altr_accent_seed";

  @override
  AppearanceState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    final themeStr = prefs.getString(_themeModeKey);
    ThemeMode mode = ThemeMode.system;
    if (themeStr != null) {
      if (themeStr == "light") mode = ThemeMode.light;
      if (themeStr == "dark") mode = ThemeMode.dark;
    }

    final accentStr = prefs.getString(_accentSeedKey);
    Color seed = const Color(0xff096b5a);
    if (accentStr != null) {
      final parsedInt = int.tryParse(accentStr, radix: 16);
      if (parsedInt != null) {
        seed = Color(parsedInt);
      }
    }

    return AppearanceState(
      themeMode: mode,
      accentSeedColor: seed,
    );
  }

  void updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      String modeStr = "system";
      if (mode == ThemeMode.light) modeStr = "light";
      if (mode == ThemeMode.dark) modeStr = "dark";
      await prefs.setString(_themeModeKey, modeStr);
    } catch (_) {}
  }

  void updateAccentColor(Color seed) async {
    state = state.copyWith(accentSeedColor: seed);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      // ignore: deprecated_member_use
      await prefs.setString(_accentSeedKey, seed.value.toRadixString(16));
    } catch (_) {}
  }
}

final appearanceProvider = NotifierProvider<AppearanceNotifier, AppearanceState>(AppearanceNotifier.new);

class BubbleModeNotifier extends Notifier<bool> {
  static const String _bubbleModeKey = "altr_bubble_mode";

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_bubbleModeKey) ?? false;
  }

  Future<void> setBubbleMode(bool value) async {
    state = value;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(_bubbleModeKey, value);
    } catch (_) {}
  }
}

final bubbleModeProvider = NotifierProvider<BubbleModeNotifier, bool>(BubbleModeNotifier.new);

