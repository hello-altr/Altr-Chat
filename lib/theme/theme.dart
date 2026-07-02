import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff096b5a),
      surfaceTint: Color(0xff096b5a),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffa1f2dd),
      onPrimaryContainer: Color(0xff005143),
      secondary: Color(0xff2f6a43),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffb2f1c0),
      onSecondaryContainer: Color(0xff14512d),
      tertiary: Color(0xFF4D662A),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffceeda2),
      onTertiaryContainer: Color(0xff364e14),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff171d1a),
      onSurfaceVariant: Color(0xff3f4945),
      outline: Color(0xff6f7975),
      outlineVariant: Color(0xffbfc9c4),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322f),
      inversePrimary: Color(0xff85d6c1),
      primaryFixed: Color(0xffa1f2dd),
      onPrimaryFixed: Color(0xff00201a),
      primaryFixedDim: Color(0xff85d6c1),
      onPrimaryFixedVariant: Color(0xff005143),
      secondaryFixed: Color(0xffb2f1c0),
      onSecondaryFixed: Color(0xff00210d),
      secondaryFixedDim: Color(0xff97d5a5),
      onSecondaryFixedVariant: Color(0xff14512d),
      tertiaryFixed: Color(0xffceeda2),
      onTertiaryFixed: Color(0xff112000),
      tertiaryFixedDim: Color(0xffb3d088),
      onTertiaryFixedVariant: Color(0xff364e14),
      surfaceDim: Color(0xffd5dbd7),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f0),
      surfaceContainer: Color(0xffe9efea),
      surfaceContainerHigh: Color(0xffe4eae5),
      surfaceContainerHighest: Color(0xffdee4df),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003e33),
      surfaceTint: Color(0xff096b5a),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff237a69),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff003f1e),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff3f7950),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff263c04),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff5b7538),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff0c1210),
      onSurfaceVariant: Color(0xff2f3835),
      outline: Color(0xff4b5551),
      outlineVariant: Color(0xff656f6b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322f),
      inversePrimary: Color(0xff85d6c1),
      primaryFixed: Color(0xff237a69),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff006051),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff3f7950),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff25603a),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff5b7538),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff445c22),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc2c8c3),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f0),
      surfaceContainer: Color(0xffe4eae5),
      surfaceContainerHigh: Color(0xffd8ded9),
      surfaceContainerHighest: Color(0xffcdd3ce),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff00332a),
      surfaceTint: Color(0xff096b5a),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff005346),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff003418),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff17542f),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff1d3200),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff385017),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff252e2b),
      outlineVariant: Color(0xff424b48),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322f),
      inversePrimary: Color(0xff85d6c1),
      primaryFixed: Color(0xff005346),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003a30),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff17542f),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff003b1c),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff385017),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff233902),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb4bab6),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffecf2ed),
      surfaceContainer: Color(0xffdee4df),
      surfaceContainerHigh: Color(0xffd0d6d1),
      surfaceContainerHighest: Color(0xffc2c8c3),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff85d6c1),
      surfaceTint: Color(0xff85d6c1),
      onPrimary: Color(0xff00382e),
      primaryContainer: Color(0xff005143),
      onPrimaryContainer: Color(0xffa1f2dd),
      secondary: Color(0xff97d5a5),
      onSecondary: Color(0xff00391b),
      secondaryContainer: Color(0xff14512d),
      onSecondaryContainer: Color(0xffb2f1c0),
      tertiary: Color(0xffb3d088),
      onTertiary: Color(0xff203600),
      tertiaryContainer: Color(0xff364e14),
      onTertiaryContainer: Color(0xffceeda2),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffdee4df),
      onSurfaceVariant: Color(0xffbfc9c4),
      outline: Color(0xff89938f),
      outlineVariant: Color(0xff3f4945),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4df),
      inversePrimary: Color(0xff096b5a),
      primaryFixed: Color(0xffa1f2dd),
      onPrimaryFixed: Color(0xff00201a),
      primaryFixedDim: Color(0xff85d6c1),
      onPrimaryFixedVariant: Color(0xff005143),
      secondaryFixed: Color(0xffb2f1c0),
      onSecondaryFixed: Color(0xff00210d),
      secondaryFixedDim: Color(0xff97d5a5),
      onSecondaryFixedVariant: Color(0xff14512d),
      tertiaryFixed: Color(0xffceeda2),
      onTertiaryFixed: Color(0xff112000),
      tertiaryFixedDim: Color(0xffb3d088),
      onTertiaryFixedVariant: Color(0xff364e14),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff343b37),
      surfaceContainerLowest: Color(0xff0a0f0d),
      surfaceContainerLow: Color(0xff171d1a),
      surfaceContainer: Color(0xff1b211e),
      surfaceContainerHigh: Color(0xff252b28),
      surfaceContainerHighest: Color(0xff303633),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff9aecd6),
      surfaceTint: Color(0xff85d6c1),
      onPrimary: Color(0xff002c24),
      primaryContainer: Color(0xff4e9f8c),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffacebba),
      onSecondary: Color(0xff002d14),
      secondaryContainer: Color(0xff629e72),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffc8e79c),
      onTertiary: Color(0xff182b00),
      tertiaryContainer: Color(0xff7e9a58),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd4dfda),
      outline: Color(0xffaab4b0),
      outlineVariant: Color(0xff88938e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4df),
      inversePrimary: Color(0xff005244),
      primaryFixed: Color(0xffa1f2dd),
      onPrimaryFixed: Color(0xff001510),
      primaryFixedDim: Color(0xff85d6c1),
      onPrimaryFixedVariant: Color(0xff003e33),
      secondaryFixed: Color(0xffb2f1c0),
      onSecondaryFixed: Color(0xff001507),
      secondaryFixedDim: Color(0xff97d5a5),
      onSecondaryFixedVariant: Color(0xff003f1e),
      tertiaryFixed: Color(0xffceeda2),
      onTertiaryFixed: Color(0xff091400),
      tertiaryFixedDim: Color(0xffb3d088),
      onTertiaryFixedVariant: Color(0xff263c04),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff404643),
      surfaceContainerLowest: Color(0xff040806),
      surfaceContainerLow: Color(0xff191f1c),
      surfaceContainer: Color(0xff232926),
      surfaceContainerHigh: Color(0xff2e3431),
      surfaceContainerHighest: Color(0xff393f3c),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffb3ffea),
      surfaceTint: Color(0xff85d6c1),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff81d2bd),
      onPrimaryContainer: Color(0xff000e0a),
      secondary: Color(0xffbfffcc),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xff93d1a1),
      onSecondaryContainer: Color(0xff000f04),
      tertiary: Color(0xffdcfbaf),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffafcc85),
      onTertiaryContainer: Color(0xff060e00),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffe8f2ed),
      outlineVariant: Color(0xffbbc5c0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4df),
      inversePrimary: Color(0xff005244),
      primaryFixed: Color(0xffa1f2dd),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff85d6c1),
      onPrimaryFixedVariant: Color(0xff001510),
      secondaryFixed: Color(0xffb2f1c0),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xff97d5a5),
      onSecondaryFixedVariant: Color(0xff001507),
      tertiaryFixed: Color(0xffceeda2),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffb3d088),
      onTertiaryFixedVariant: Color(0xff091400),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff4b514e),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1b211e),
      surfaceContainer: Color(0xff2c322f),
      surfaceContainerHigh: Color(0xff373d3a),
      surfaceContainerHighest: Color(0xff424845),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.surface,
     canvasColor: colorScheme.surface,
     appBarTheme: AppBarTheme(
       backgroundColor: colorScheme.surfaceContainer,
       elevation: 0,
       scrolledUnderElevation: 0,
       centerTitle: false,
     ),
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
