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

class AppearanceNotifier extends Notifier<AppearanceState> {
  static const String _themeModeKey = "altr_theme_mode";
  static const String _accentSeedKey = "altr_accent_seed";

  @override
  AppearanceState build() {
    _loadFromPrefs();
    return AppearanceState(
      themeMode: ThemeMode.system,
      accentSeedColor: const Color(0xff096b5a),
    );
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
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

      Future.microtask(() {
        if (ref.mounted) {
          state = AppearanceState(
            themeMode: mode,
            accentSeedColor: seed,
          );
        }
      });
    } catch (_) {
      // If error occurs, fallback to defaults
    }
  }

  void updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr = "system";
      if (mode == ThemeMode.light) modeStr = "light";
      if (mode == ThemeMode.dark) modeStr = "dark";
      await prefs.setString(_themeModeKey, modeStr);
    } catch (_) {}
  }

  void updateAccentColor(Color seed) async {
    state = state.copyWith(accentSeedColor: seed);
    try {
      final prefs = await SharedPreferences.getInstance();
      // ignore: deprecated_member_use
      await prefs.setString(_accentSeedKey, seed.value.toRadixString(16));
    } catch (_) {}
  }
}

final appearanceProvider = NotifierProvider<AppearanceNotifier, AppearanceState>(AppearanceNotifier.new);
