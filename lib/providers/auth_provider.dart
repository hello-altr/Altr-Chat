// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';

// Models & Repositories
import 'package:chat/repositories/user_repository.dart';
import 'package:chat/models/user_model.dart';

// Repositories & Services
import 'package:chat/services/device_service.dart';

// Provides continuous reactive exposure of the active Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) {
    log('Auth state changes stream emitted user UID: ${user?.uid ?? "null"}', name: 'Auth');
    return user;
  });
});

final userProfileProvider = FutureProvider<AltrUser?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) {
    log('No active auth state user found. Returning null profile.', name: 'Auth');
    return null;
  }

  final deviceIdAsync = ref.watch(deviceIdProvider);
  final deviceId = deviceIdAsync.value;
  if (deviceId == null) {
    return null;
  }

  log('Auth state found. Syncing user ${authState.uid} to Firestore...', name: 'Auth');
  final userRepository = UserRepository();
  await userRepository.syncGoogleUserToFirestore(authState);
  log('User profile synced. Querying Firestore document...', name: 'Auth');

  final doc = await FirebaseFirestore.instance.collection('users').doc(authState.uid).get();
  if (doc.exists && doc.data() != null) {
    final deviceDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(authState.uid)
        .collection('current_workspaces')
        .doc(deviceId)
        .get();
    final currentWorkspace = deviceDoc.data()?['current_workspace'] as String? ?? '';
    final altrUser = AltrUser.fromMap(doc.data()!, currentWorkspace: currentWorkspace);
    log('Successfully loaded AltrUser profile: ${altrUser.emailId}', name: 'Auth');
    return altrUser;
  }
  log('User document not found in Firestore collection for UID: ${authState.uid}', name: 'Auth');
  return null;
});

final deviceIdProvider = FutureProvider<String>((ref) async {
  return await DeviceService.getDeviceId();
});

final currentWorkspaceIdProvider = Provider<String?>((ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return null;
  final selected = user.currentWorkspace;
  if (selected.isNotEmpty) return selected;
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
  log('Starting Google Sign-In process...', name: 'Auth');
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb
          ? '1085731614579-8da3in5pd6rbtefa256c6jgrgc7djdhd.apps.googleusercontent.com'
          : null,
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      log('Google Sign-In was cancelled by the user.', name: 'Auth');
      return;
    }
    log('Google Sign-In successful: ${googleUser.email}. Requesting credentials...', name: 'Auth');

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    log('Authenticating credentials with Firebase...', name: 'Auth');
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    log('Firebase Sign-In successful: ${userCredential.user?.uid}', name: 'Auth');
  } catch (e) {
    log('Authentication process encountered an error: $e', error: e, name: 'Auth');
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

