// Packages
import 'package:material_ui/material_ui.dart';

class AltrComponentTheme {
  static DialogThemeData dialogThemeData() {
    return DialogThemeData(
      // ignore: deprecated_member_use
      barrierColor: Colors.black.withOpacity(0.45), // Enforces uniform translucent backdrop across app dialog segments
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    );
  }

  static CardThemeData cardThemeData() {
    return CardThemeData(
      clipBehavior: Clip.antiAlias, // Globally isolates inner view bleeding past rounded rounded parent paths
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 2.0,
    );
  }

  static InputDecorationTheme inputDecorationThemeData(ColorScheme colorScheme) {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
      ),
    );
  }
}
