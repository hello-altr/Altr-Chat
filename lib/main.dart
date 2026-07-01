// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Layout Shell
import 'package:chat/layout_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AltrChat()));
}

class AltrChat extends StatelessWidget {
  const AltrChat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LayoutShell(),
      
      // Strict enforcement of your PRD Material 3 requirement
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0066FF),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0066FF),
        brightness: Brightness.dark,
      ),
    );
  }
}
