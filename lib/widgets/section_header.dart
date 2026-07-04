// Packages
import 'package:material_ui/material_ui.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final double fontSize;

  const SectionHeader({super.key, required this.title, this.fontSize = 12.0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
