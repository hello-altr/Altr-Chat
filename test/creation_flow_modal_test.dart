// Packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/chat/creation_flow_modal.dart';

// Providers
import 'package:chat/providers/appearance_notifier.dart';
import 'package:chat/providers/auth_provider.dart';

// Models
import 'package:chat/models/user_model.dart';

void main() {
  testWidgets('CreationFlowModal Desktop View - Centered Dialog Bounded Constraints', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockUser = AltrUser(
      userId: 'test_uid',
      userName: 'test_user',
      displayName: 'Test User',
      photoUrl: '',
      emailId: 'test@example.com',
      joinedWorkspaces: ['test_ws'],
      activeWorkspaceId: 'test_ws',
      onboardingCompleted: true,
      profileOnboardingCompleted: true,
      workspaceOnboardingCompleted: true,
    );

    // Force wide screen width (Desktop)
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => mockUser),
          deviceIdProvider.overrideWith((ref) => 'test_device'),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showCreationFlowModal(context, isChannel: true);
                  },
                  child: const Text('Open Creation Flow'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Tap to open modal
    await tester.tap(find.text('Open Creation Flow'));
    await tester.pumpAndSettle();

    // Verify it is shown in a Dialog/Card bounded constraint
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    
    // Check if the ChannelCreationSheet is present
    expect(find.text('Channel Name'), findsOneWidget);
  });

  testWidgets('CreationFlowModal Mobile View - Full Screen Scaffold', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockUser = AltrUser(
      userId: 'test_uid',
      userName: 'test_user',
      displayName: 'Test User',
      photoUrl: '',
      emailId: 'test@example.com',
      joinedWorkspaces: ['test_ws'],
      activeWorkspaceId: 'test_ws',
      onboardingCompleted: true,
      profileOnboardingCompleted: true,
      workspaceOnboardingCompleted: true,
    );

    // Force narrow screen width (Mobile)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => mockUser),
          deviceIdProvider.overrideWith((ref) => 'test_device'),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showCreationFlowModal(context, isChannel: true);
                  },
                  child: const Text('Open Creation Flow'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Tap to open modal
    await tester.tap(find.text('Open Creation Flow'));
    await tester.pumpAndSettle();

    // Verify it is shown in a Dialog route but with zero inset padding (full screen)
    final Dialog dialog = tester.widget(find.byType(Dialog));
    expect(dialog.insetPadding, EdgeInsets.zero);
    expect(find.byType(Scaffold), findsNWidgets(2)); // Main home screen scaffold + modal fullscreen scaffold
    
    expect(find.text('Channel Name'), findsOneWidget);
  });

  testWidgets('ChannelName Input Formatting Rules (Reactive Prefixing, Case, Space Removal)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockUser = AltrUser(
      userId: 'test_uid',
      userName: 'test_user',
      displayName: 'Test User',
      photoUrl: '',
      emailId: 'test@example.com',
      joinedWorkspaces: ['test_ws'],
      activeWorkspaceId: 'test_ws',
      onboardingCompleted: true,
      profileOnboardingCompleted: true,
      workspaceOnboardingCompleted: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => mockUser),
          deviceIdProvider.overrideWith((ref) => 'test_device'),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showCreationFlowModal(context, isChannel: true);
                  },
                  child: const Text('Open Creation Flow'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Tap to open modal
    await tester.tap(find.text('Open Creation Flow'));
    await tester.pumpAndSettle();

    final textFieldFinder = find.byType(TextFormField);
    expect(textFieldFinder, findsOneWidget);

    // Type a raw channel name with spaces and uppercase letters
    await tester.enterText(textFieldFinder, 'General Chat Space');
    await tester.pump();

    // Verify the controller formatting formatted it to 'generalchatspace'
    final TextFormField fieldWidget = tester.widget(textFieldFinder);
    expect(fieldWidget.controller?.text, 'generalchatspace');
  });

  testWidgets('CreationFlowModal Responsive Resize Transition on the fly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockUser = AltrUser(
      userId: 'test_uid',
      userName: 'test_user',
      displayName: 'Test User',
      photoUrl: '',
      emailId: 'test@example.com',
      joinedWorkspaces: ['test_ws'],
      activeWorkspaceId: 'test_ws',
      onboardingCompleted: true,
      profileOnboardingCompleted: true,
      workspaceOnboardingCompleted: true,
    );

    // Start with wide screen width (Desktop)
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => mockUser),
          deviceIdProvider.overrideWith((ref) => 'test_device'),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showCreationFlowModal(context, isChannel: true);
                  },
                  child: const Text('Open Creation Flow'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Creation Flow'));
    await tester.pumpAndSettle();

    // Verify it is desktop centered dialog with non-zero inset padding
    final Dialog desktopDialog = tester.widget(find.byType(Dialog));
    expect(desktopDialog.insetPadding, isNot(EdgeInsets.zero));
    expect(find.byType(Card), findsOneWidget);

    // Resize to mobile screen size dynamically on the fly
    tester.view.physicalSize = const Size(400, 800);
    await tester.pump(); // Trigger layout update rebuild

    // Verify it has shifted to zero inset padding (mobile fullscreen dialog wrapper)
    final Dialog mobileDialog = tester.widget(find.byType(Dialog));
    expect(mobileDialog.insetPadding, EdgeInsets.zero);
  });
}
