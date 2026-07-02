// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Layout Shell
import 'package:chat/layout_shell.dart';

// Providers
import 'package:chat/providers/theme_provider.dart';

// Theme & Utils
import 'package:chat/theme/theme.dart';
import 'package:chat/utils/util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AltrChat()));
}

class AltrChat extends ConsumerWidget {
  const AltrChat({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextTheme textTheme = createTextTheme(context, "Inter", "Montserrat");
    MaterialTheme theme = MaterialTheme(textTheme);
    final currentThemeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LayoutShell(),
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: currentThemeMode,
    );
  }
}
