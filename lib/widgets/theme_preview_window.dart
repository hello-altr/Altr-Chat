// Packages
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat/providers/appearance_notifier.dart';

class ThemePreviewWindow extends ConsumerWidget {
  final bool isDark;
  final bool isSplit;
  final Color selectedColor;
  final bool isMobile;

  const ThemePreviewWindow({
    super.key,
    required this.isDark,
    required this.isSplit,
    required this.selectedColor,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seedColor = selectedColor;
    final hsl = HSLColor.fromColor(seedColor);

    final bubbleMode = ref.watch(bubbleModeProvider).value ?? false;

    final lightWallpaper = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        hsl.withLightness(0.92).withSaturation(0.85).toColor(),
        hsl.withLightness(0.72).withSaturation(0.90).toColor(),
        hsl.withLightness(0.48).withSaturation(0.90).toColor(),
      ],
    );

    final darkWallpaper = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        hsl.withLightness(0.22).withSaturation(0.45).toColor(),
        hsl.withLightness(0.12).withSaturation(0.55).toColor(),
        hsl.withLightness(0.06).withSaturation(0.65).toColor(),
      ],
    );

    final wallpaper = isDark ? darkWallpaper : lightWallpaper;
    final panelColor = isDark
        ? const Color(0xFF0F172A).withAlpha(200)
        : const Color(0xFFF1F5F9).withAlpha(200);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      decoration: BoxDecoration(gradient: wallpaper),
      child: Stack(
        children: [
          // Top Panel / Menu Bar representation
          Positioned(
            top: 4,
            left: 4,
            right: 4,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.centerLeft,
              child: Container(
                width: isSplit ? 10 : 16,
                height: 2,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          // Content Card / App Window body representation
          Positioned(
            bottom: 0,
            right: 0,
            left: isSplit ? 4 : 8,
            top: 18,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 2,
                    offset: const Offset(-1, -1),
                  ),
                ],
              ),
              padding: isMobile
                  ? const EdgeInsets.symmetric(horizontal: 4, vertical: 6)
                  : const EdgeInsets.only(left: 3, top: 3, right: 3),
              child: isMobile
                  ? (bubbleMode
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Bubble 1 (left)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: isSplit ? 20 : 36,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(2),
                                    topRight: Radius.circular(2),
                                    bottomRight: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Bubble 2 (right - themed)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: isSplit ? 26 : 48,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: selectedColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(2),
                                    topRight: Radius.circular(2),
                                    bottomLeft: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Bubble 3 (left)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: isSplit ? 30 : 54,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(2),
                                    topRight: Radius.circular(2),
                                    bottomRight: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Bubble 4 (right - themed)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: isSplit ? 22 : 40,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: selectedColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(2),
                                    topRight: Radius.circular(2),
                                    bottomLeft: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Bubble 5 (left)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: isSplit ? 16 : 30,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(2),
                                    topRight: Radius.circular(2),
                                    bottomRight: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLinearPreviewRow(isDark, isSplit ? 20 : 36, false, selectedColor),
                            const SizedBox(height: 5),
                            _buildLinearPreviewRow(isDark, isSplit ? 26 : 48, true, selectedColor),
                            const SizedBox(height: 5),
                            _buildLinearPreviewRow(isDark, isSplit ? 30 : 54, false, selectedColor),
                            const SizedBox(height: 5),
                            _buildLinearPreviewRow(isDark, isSplit ? 22 : 40, true, selectedColor),
                            const SizedBox(height: 5),
                            _buildLinearPreviewRow(isDark, isSplit ? 16 : 30, false, selectedColor),
                          ],
                        ))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Simulated horizontal navigation sidebar
                        Container(
                          width: isSplit ? 14 : 20,
                          margin: const EdgeInsets.only(right: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < 3; i++) ...[
                                Container(
                                  width: isSplit ? 8 : 14,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                            ],
                          ),
                        ),
                        // Divider line
                        Container(
                          width: 0.5,
                          height: 30, // Limit height to avoid overflow/bleeding
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                        const SizedBox(width: 3),
                        // Messaging feeds panel blocks
                        Expanded(
                          child: bubbleMode
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Bubble 1 (left)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: isSplit ? 12 : 24,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(1),
                                            topRight: Radius.circular(1),
                                            bottomRight: Radius.circular(1),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    // Bubble 2 (right - themed)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        width: isSplit ? 16 : 30,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: selectedColor,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(1),
                                            topRight: Radius.circular(1),
                                            bottomLeft: Radius.circular(1),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    // Bubble 3 (left)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: isSplit ? 18 : 34,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(1),
                                            topRight: Radius.circular(1),
                                            bottomRight: Radius.circular(1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildDesktopLinearPreviewRow(isDark, isSplit ? 12 : 24, false, selectedColor),
                                    const SizedBox(height: 3),
                                    _buildDesktopLinearPreviewRow(isDark, isSplit ? 16 : 30, true, selectedColor),
                                    const SizedBox(height: 3),
                                    _buildDesktopLinearPreviewRow(isDark, isSplit ? 18 : 34, false, selectedColor),
                                  ],
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinearPreviewRow(bool isDark, double width, bool isCurrentUser, Color selectedColor) {
    final avatarColor = isCurrentUser
        ? selectedColor
        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: avatarColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCurrentUser) ...[
                Container(
                  width: width * 0.4,
                  height: 2,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Container(
                width: width,
                height: 4,
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? selectedColor
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLinearPreviewRow(bool isDark, double width, bool isCurrentUser, Color selectedColor) {
    final avatarColor = isCurrentUser
        ? selectedColor
        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: avatarColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCurrentUser) ...[
                Container(
                  width: width * 0.4,
                  height: 1,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(0.5),
                  ),
                ),
                const SizedBox(height: 1),
              ],
              Container(
                width: width,
                height: 2,
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? selectedColor
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
