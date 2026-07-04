// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Providers
import 'package:chat/providers/auth_provider.dart';

// Models
import 'package:chat/models/user_model.dart';

// Main
import 'package:chat/main.dart';

void main() {
  testWidgets('Aero Chat Layout Shell Smoke Test', (WidgetTester tester) async {
    final mockUser = AltrUser(
      userId: 'test_uid',
      userName: 'test_user',
      displayName: 'Test User',
      photoUrl: '',
      emailId: 'test@example.com',
      activeWorkspaces: ['test_ws'],
      currentWorkspaces: {'test_device': 'test_ws'},
      onboardingCompleted: true,
      profileOnboardingCompleted: true,
      workspaceOnboardingCompleted: true,
    );

    // Build our app under a ProviderScope with overrides and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => mockUser),
          splashDelayProvider.overrideWith((ref) => null),
          deviceIdProvider.overrideWith((ref) => 'test_device'),
        ],
        child: const AltrChat(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the Channels view and navigation elements loaded successfully
    expect(find.text('Channels'), findsAtLeastNWidgets(1));
    
    // Verify that the DMs navigation icon label is present
    expect(find.text('DMs'), findsAtLeastNWidgets(1));
  });
}
