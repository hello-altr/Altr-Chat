// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';

// Models & Repositories
import 'package:chat/repositories/user_repository.dart';
import 'package:chat/models/user_model.dart';

// Repositories & Services
import 'package:chat/services/device_service.dart';

// Provides continuous reactive exposure of the active Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProfileProvider = FutureProvider<AltrUser?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;


  final userRepository = UserRepository();
  await userRepository.syncGoogleUserToFirestore(authState);

  final doc = await FirebaseFirestore.instance.collection('users').doc(authState.uid).get();
  if (doc.exists && doc.data() != null) {
    return AltrUser.fromMap(doc.data()!);
  }
  return null;
});

final deviceIdProvider = FutureProvider<String>((ref) async {
  return await DeviceService.getDeviceId();
});

final currentWorkspaceIdProvider = Provider<String?>((ref) {
  final user = ref.watch(userProfileProvider).value;
  final deviceId = ref.watch(deviceIdProvider).value;
  if (user == null) return null;
  final selected = deviceId != null ? user.currentWorkspaces[deviceId] : null;
  if (selected != null && selected.isNotEmpty) return selected;
  return user.activeWorkspaces.isNotEmpty ? user.activeWorkspaces.first : null;
});

final userWorkspacesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null || user.activeWorkspaces.isEmpty) return [];

  final List<Map<String, dynamic>> workspaces = [];
  for (final wsId in user.activeWorkspaces) {
    final doc = await FirebaseFirestore.instance.collection('workspaces').doc(wsId).get();
    if (doc.exists && doc.data() != null) {
      workspaces.add(doc.data()!);
    }
  }
  return workspaces;
});

final currentWorkspaceProvider = Provider<Map<String, dynamic>?>((ref) {
  final workspaces = ref.watch(userWorkspacesProvider).value ?? [];
  final activeId = ref.watch(currentWorkspaceIdProvider);
  if (activeId == null) return null;
  
  for (final ws in workspaces) {
    if (ws['id'] == activeId) {
      return ws;
    }
  }
  return null;
});

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb
          ? '1085731614579-8da3in5pd6rbtefa256c6jgrgc7djdhd.apps.googleusercontent.com'
          : null,
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Authentication failed: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

