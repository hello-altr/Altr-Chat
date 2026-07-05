// Packages
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hugeicons_pro/hugeicons.dart';

Future<void> showSignOutDialog(BuildContext context) async {
  final theme = Theme.of(context);
  final confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final dialog = AlertDialog(
        constraints: const BoxConstraints(maxWidth: 400),
        title: Row(
          children: [
            Icon(HugeIconsStroke.logout01, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out? You will need to sign in again to access your chats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      );

      return dialog;
    },
  );

  if (confirm == true) {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }
}
