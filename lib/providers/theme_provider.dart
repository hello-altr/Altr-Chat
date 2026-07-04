// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum ThemeColorOption {
  defaultColor,
  blue,
  purple,
  red,
  orange,
  yellow,
  green,
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeColorNotifier extends Notifier<ThemeColorOption> {
  @override
  ThemeColorOption build() {
    return ThemeColorOption.defaultColor;
  }

  void setThemeColor(ThemeColorOption option) {
    state = option;
  }
}

final themeColorOptionProvider = NotifierProvider<ThemeColorNotifier, ThemeColorOption>(ThemeColorNotifier.new);
