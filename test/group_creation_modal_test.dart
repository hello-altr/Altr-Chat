import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat/widgets/chat/group_creation_modal.dart';
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/widgets/chat/chat_feed_canvas.dart';

void main() {
  testWidgets('GroupCreationModal Flow - Page 1 Name and Handle validations', (WidgetTester tester) async {
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

    // Force wide screen
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
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showGroupCreationModal(context, 'test_ws');
                  },
                  child: const Text('Open Group Creation'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Tap to open group creation modal
    await tester.tap(find.text('Open Group Creation'));
    await tester.pumpAndSettle();

    expect(find.text('Create a User Group'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);

    // Verify continue button is disabled
    final continueBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
    expect(continueBtn.enabled, isFalse);

    // Enter group name
    await tester.enterText(find.byType(TextFormField).first, 'Engineering Team');
    await tester.pumpAndSettle();

    // Verify default handle preview is set automatically
    expect(find.text('@engineering-team'), findsOneWidget);

    // Toggle custom handle customization
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // Verify customized textfield appeared and prefilled with default handle
    expect(find.byType(TextFormField), findsNWidgets(2));
    final customHandleField = find.byType(TextFormField).last;
    expect(tester.widget<TextFormField>(customHandleField).controller?.text, 'engineering-team');

    // Change custom handle to something custom
    await tester.enterText(customHandleField, 'devs');
    await tester.pumpAndSettle();

    final updatedContinueBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
    expect(updatedContinueBtn.enabled, isTrue);

    // Continue to page 2
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();

    // Verify we transitioned to Page 2
    expect(find.text('Add Users'), findsOneWidget);
  });

  testWidgets('GroupCreationModal Flow - Handle Uniqueness validation shows error and disables continue', (WidgetTester tester) async {
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
          workspaceUserGroupsProvider('test_ws').overrideWith((ref) => Stream.value([
            {'id': 'g1', 'name': 'Dev Group', 'handle': 'devs', 'members': []}
          ])),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showGroupCreationModal(context, 'test_ws');
                  },
                  child: const Text('Open Group Creation'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Tap to open group creation modal
    await tester.tap(find.text('Open Group Creation'));
    await tester.pumpAndSettle();

    // Enter group name which creates handle 'devs' (which is already taken)
    await tester.enterText(find.byType(TextFormField).first, 'devs');
    await tester.pumpAndSettle();

    // Verify inline error text is shown
    expect(find.text('This group handle is already taken in this workspace.'), findsOneWidget);

    // Verify continue button is disabled
    final continueBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
    expect(continueBtn.enabled, isFalse);

    // Change group name to something unique
    await tester.enterText(find.byType(TextFormField).first, 'Unique Team');
    await tester.pumpAndSettle();

    // Verify inline error text is gone
    expect(find.text('This group handle is already taken in this workspace.'), findsNothing);

    // Verify continue button is now enabled
    final continueBtnUnique = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
    expect(continueBtnUnique.enabled, isTrue);
  });
}
