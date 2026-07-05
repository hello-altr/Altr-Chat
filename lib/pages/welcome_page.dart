// Packages
import 'package:material_ui/material_ui.dart';
import 'package:chat/values.dart';

// Providers
import 'package:chat/providers/auth_provider.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= kDesktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        body: Center(
          child: Card(
            color: theme.colorScheme.surfaceContainer,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  // TODO: Replace with custom icon manually
                  const SizedBox(
                    width: 100,
                    height: 100,
                    child: Placeholder(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Altr Chat',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 80),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => signInWithGoogle(context),
                      child: const Text('Continue with Google'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                // TODO: Replace with custom icon manually
                const SizedBox(
                  width: 100,
                  height: 100,
                  child: Placeholder(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Altr Chat',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => signInWithGoogle(context),
                    child: const Text('Continue with Google'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

typedef WelcomeAuthenticationView = WelcomePage;

