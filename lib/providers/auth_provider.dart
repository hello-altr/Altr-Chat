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

