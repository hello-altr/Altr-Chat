// Packages
import 'package:material_ui/material_ui.dart';

// Theme
import 'component_overrides.dart';

class AltrTheme {
  static ThemeData buildTheme(ThemeMode mode, Color seedColor) {
    final brightness = mode == ThemeMode.dark ? Brightness.dark : Brightness.light;

    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: baseColorScheme,
      dialogTheme: AltrComponentTheme.dialogThemeData(),
      cardTheme: AltrComponentTheme.cardThemeData(),
      inputDecorationTheme: AltrComponentTheme.inputDecorationThemeData(baseColorScheme),
      // Enforce solid, clean system surface colors on the Scaffold canvas layers
      scaffoldBackgroundColor: baseColorScheme.surface,
    );
  }
}
