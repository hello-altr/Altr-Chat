// Packages
import 'package:google_fonts/google_fonts.dart';
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

    // Build the Inter + Montserrat GoogleFonts text theme statically
    final baseTextTheme = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;

    final bodyTextTheme = GoogleFonts.getTextTheme("Inter", baseTextTheme);
    final displayTextTheme = GoogleFonts.getTextTheme("Montserrat", baseTextTheme);

    final textTheme = displayTextTheme.copyWith(
      bodyLarge: bodyTextTheme.bodyLarge,
      bodyMedium: bodyTextTheme.bodyMedium,
      bodySmall: bodyTextTheme.bodySmall,
      labelLarge: bodyTextTheme.labelLarge,
      labelMedium: bodyTextTheme.labelMedium,
      labelSmall: bodyTextTheme.labelSmall,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: baseColorScheme,
      textTheme: textTheme.apply(
        bodyColor: baseColorScheme.onSurface,
        displayColor: baseColorScheme.onSurface,
      ),
      dialogTheme: AltrComponentTheme.dialogThemeData(),
      cardTheme: AltrComponentTheme.cardThemeData(),
      inputDecorationTheme: AltrComponentTheme.inputDecorationThemeData(baseColorScheme),
      // Enforce solid, clean system surface colors on the Scaffold canvas layers
      scaffoldBackgroundColor: baseColorScheme.surface,
    );
  }
}
