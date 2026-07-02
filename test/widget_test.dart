// Pacakges
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat/main.dart';

void main() {
  testWidgets('Aero Chat Layout Shell Smoke Test', (WidgetTester tester) async {
    // Build our app under a ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AltrChat()));

    // Verify that the Channels view and navigation elements loaded successfully
    expect(find.text('Channels'), findsAtLeastNWidgets(1));
    
    // Verify that the DMs navigation icon label is present
    expect(find.text('DMs'), findsAtLeastNWidgets(1));
  });
}
