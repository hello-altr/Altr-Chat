// Packages
import 'package:material_ui/material_ui.dart';

class ThemePreviewWindow extends StatelessWidget {
  final bool isDark;
  final bool isSplit;
  final Color selectedColor;

  const ThemePreviewWindow({
    super.key,
    required this.isDark,
    required this.isSplit,
    required this.selectedColor,
  });

  Widget _buildDot(Color color) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seedColor = selectedColor;
    final hsl = HSLColor.fromColor(seedColor);

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
              padding: const EdgeInsets.only(left: 3, top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Red, Yellow, Green window dots
                  _buildDot(const Color(0xFFFF5F56)),
                  const SizedBox(width: 2),
                  _buildDot(const Color(0xFFFFBD2E)),
                  const SizedBox(width: 2),
                  _buildDot(const Color(0xFF27C93F)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
