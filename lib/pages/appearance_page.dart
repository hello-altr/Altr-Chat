// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/theme_provider.dart';
import 'package:chat/providers/settings_provider.dart';

// Widgets
import 'package:chat/widgets/theme_mode_option.dart';
import 'package:chat/widgets/theme_color_option.dart';

// Enums
import 'package:chat/enums/layout_mode.dart';

class AppearanceSettingsPanel extends ConsumerWidget {
  const AppearanceSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;
    final currentThemeMode = ref.watch(themeModeProvider);
    final selectedColor = ref.watch(themeColorOptionProvider);

    Widget themeSelectionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ThemeModeOption(
          mode: ThemeMode.system,
          label: 'Auto',
          isSelected: currentThemeMode == ThemeMode.system,
          selectedColor: selectedColor,
        ),
        const SizedBox(width: 16),
        ThemeModeOption(
          mode: ThemeMode.light,
          label: 'Light',
          isSelected: currentThemeMode == ThemeMode.light,
          selectedColor: selectedColor,
        ),
        const SizedBox(width: 16),
        ThemeModeOption(
          mode: ThemeMode.dark,
          label: 'Dark',
          isSelected: currentThemeMode == ThemeMode.dark,
          selectedColor: selectedColor,
        ),
      ],
    );

    Widget appearanceContent;
    if (isMobile) {
      appearanceContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Mode',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: themeSelectionRow),
        ],
      );
    } else {
      appearanceContent = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Theme Mode',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          themeSelectionRow,
        ],
      );
    }

    Widget colorSelectionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ThemeColorOptionItem(
          option: ThemeColorOption.defaultColor,
          color: const Color(0xff096b5a),
          label: "Default",
          isSelected: selectedColor == ThemeColorOption.defaultColor,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          option: ThemeColorOption.blue,
          color: const Color(0xFF007AFF),
          label: "",
          isSelected: selectedColor == ThemeColorOption.blue,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          option: ThemeColorOption.purple,
          color: const Color(0xFF8E44AD),
          label: "",
          isSelected: selectedColor == ThemeColorOption.purple,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          option: ThemeColorOption.red,
          color: const Color(0xFFFF3B30),
          label: "",
          isSelected: selectedColor == ThemeColorOption.red,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          option: ThemeColorOption.orange,
          color: const Color(0xFFFF9500),
          label: "",
          isSelected: selectedColor == ThemeColorOption.orange,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          option: ThemeColorOption.yellow,
          color: const Color(0xFFFFCC00),
          label: "",
          isSelected: selectedColor == ThemeColorOption.yellow,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          option: ThemeColorOption.green,
          color: const Color(0xFF34C759),
          label: "",
          isSelected: selectedColor == ThemeColorOption.green,
        ),
      ],
    );

    Widget themeContent;
    if (isMobile) {
      themeContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: colorSelectionRow,
          ),
        ],
      );
    } else {
      themeContent = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Color',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          colorSelectionRow,
        ],
      );
    }

    Widget content = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.only(
          top: 24.0,
          bottom: 90,
          left: 16.0,
          right: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Appearance",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Customize how HelloAltr displays layout layers on your viewport workspace canvas.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  appearanceContent,
                  Divider(
                    height: 32,
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                  themeContent,
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              ref.read(activeSettingsPanelProvider.notifier).state =
                  SettingsPanelType.none;
            },
          ),
          title: Text(
            'Appearance',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(child: SingleChildScrollView(child: content)),
      );
    }

    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(child: content)),
    );
  }
}
