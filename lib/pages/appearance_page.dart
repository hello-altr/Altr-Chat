// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat/providers/auth_provider.dart';

// Providers
import 'package:chat/providers/appearance_notifier.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/layout_provider.dart';

// Widgets
import 'package:chat/widgets/theme_color_option.dart';
import 'package:chat/widgets/theme_mode_option.dart';

// Enums
import 'package:chat/enums/layout_mode.dart';

class AppearanceSettingsPanel extends ConsumerWidget {
  const AppearanceSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;
    final appearance = ref.watch(appearanceProvider);
    final currentThemeMode = appearance.themeMode;
    final selectedColor = appearance.accentSeedColor;

    Widget themeSelectionRow = Row(
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      children: [
        isMobile
            ? Expanded(
                child: ThemeModeOption(
                  mode: ThemeMode.system,
                  label: 'Auto',
                  isSelected: currentThemeMode == ThemeMode.system,
                  selectedColor: selectedColor,
                  isMobile: isMobile,
                ),
              )
            : ThemeModeOption(
                mode: ThemeMode.system,
                label: 'Auto',
                isSelected: currentThemeMode == ThemeMode.system,
                selectedColor: selectedColor,
                isMobile: isMobile,
              ),
        const SizedBox(width: 16),
        isMobile
            ? Expanded(
                child: ThemeModeOption(
                  mode: ThemeMode.light,
                  label: 'Light',
                  isSelected: currentThemeMode == ThemeMode.light,
                  selectedColor: selectedColor,
                  isMobile: isMobile,
                ),
              )
            : ThemeModeOption(
                mode: ThemeMode.light,
                label: 'Light',
                isSelected: currentThemeMode == ThemeMode.light,
                selectedColor: selectedColor,
                isMobile: isMobile,
              ),
        const SizedBox(width: 16),
        isMobile
            ? Expanded(
                child: ThemeModeOption(
                  mode: ThemeMode.dark,
                  label: 'Dark',
                  isSelected: currentThemeMode == ThemeMode.dark,
                  selectedColor: selectedColor,
                  isMobile: isMobile,
                ),
              )
            : ThemeModeOption(
                mode: ThemeMode.dark,
                label: 'Dark',
                isSelected: currentThemeMode == ThemeMode.dark,
                selectedColor: selectedColor,
                isMobile: isMobile,
              ),
      ],
    );

    Widget appearanceContent;
    if (isMobile) {
      appearanceContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          themeSelectionRow,
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
          color: const Color(0xff096b5a),
          label: "Default",
          isSelected: selectedColor == const Color(0xff096b5a),
          isMobile: false,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          color: const Color(0xFF007AFF),
          label: "",
          isSelected: selectedColor == const Color(0xFF007AFF),
          isMobile: false,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          color: const Color(0xFF8E44AD),
          label: "",
          isSelected: selectedColor == const Color(0xFF8E44AD),
          isMobile: false,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          color: const Color(0xFFFF3B30),
          label: "",
          isSelected: selectedColor == const Color(0xFFFF3B30),
          isMobile: false,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          color: const Color(0xFFFF9500),
          label: "",
          isSelected: selectedColor == const Color(0xFFFF9500),
          isMobile: false,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          color: const Color(0xFFFFCC00),
          label: "",
          isSelected: selectedColor == const Color(0xFFFFCC00),
          isMobile: false,
        ),
        const SizedBox(width: 10),
        ThemeColorOptionItem(
          color: const Color(0xFF34C759),
          label: "",
          isSelected: selectedColor == const Color(0xFF34C759),
          isMobile: false,
        ),
      ],
    );

    Widget colorSelectionWrap = Wrap(
      spacing: 14.0,
      runSpacing: 14.0,
      children: [
        ThemeColorOptionItem(
          color: const Color(0xff096b5a),
          label: "Default",
          isSelected: selectedColor == const Color(0xff096b5a),
          isMobile: true,
        ),
        ThemeColorOptionItem(
          color: const Color(0xFF007AFF),
          label: "",
          isSelected: selectedColor == const Color(0xFF007AFF),
          isMobile: true,
        ),
        ThemeColorOptionItem(
          color: const Color(0xFF8E44AD),
          label: "",
          isSelected: selectedColor == const Color(0xFF8E44AD),
          isMobile: true,
        ),
        ThemeColorOptionItem(
          color: const Color(0xFFFF3B30),
          label: "",
          isSelected: selectedColor == const Color(0xFFFF3B30),
          isMobile: true,
        ),
        ThemeColorOptionItem(
          color: const Color(0xFFFF9500),
          label: "",
          isSelected: selectedColor == const Color(0xFFFF9500),
          isMobile: true,
        ),
        ThemeColorOptionItem(
          color: const Color(0xFFFFCC00),
          label: "",
          isSelected: selectedColor == const Color(0xFFFFCC00),
          isMobile: true,
        ),
        ThemeColorOptionItem(
          color: const Color(0xFF34C759),
          label: "",
          isSelected: selectedColor == const Color(0xFF34C759),
          isMobile: true,
        ),
      ],
    );

    Widget themeContent;
    if (isMobile) {
      themeContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accent Color',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          colorSelectionWrap,
        ],
      );
    } else {
      themeContent = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Accent Color',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          colorSelectionRow,
        ],
      );
    }

    final bubbleModeAsync = ref.watch(bubbleModeProvider);
    final bubbleMode = bubbleModeAsync.value ?? false;

    Widget bubbleModeToggleContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bubble Mode',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Convert chats into message bubbles, like in WhatsApp',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: bubbleMode,
          onChanged: (newValue) async {
            final authUser = ref.read(authStateProvider).value;
            if (authUser != null) {
              await FirebaseFirestore.instance
                  .collection('user')
                  .doc(authUser.uid)
                  .collection('preferences')
                  .doc('appearance')
                  .set({
                'bubble_mode': newValue,
              }, SetOptions(merge: true));
            }
          },
          activeColor: theme.colorScheme.primary,
        ),
      ],
    );

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
                  Divider(
                    height: 32,
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                  bubbleModeToggleContent,
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
