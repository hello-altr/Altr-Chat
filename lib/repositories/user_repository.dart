// Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Services
import 'package:chat/services/device_service.dart';

class HandleAlreadyTakenException implements Exception {
  final String message;
  HandleAlreadyTakenException([this.message = 'Username handle is already taken.']);

  @override
  String toString() => 'HandleAlreadyTakenException: $message';
}

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> reserveUsername({
    required String authenticatedUid,
    required String requestedHandle,
  }) async {
    final handleRef = _firestore.collection('handles').doc(requestedHandle.toLowerCase());
    final userProfileRef = _firestore.collection('users').doc(authenticatedUid);

    await _firestore.runTransaction((transaction) async {
      final handleDoc = await transaction.get(handleRef);
      if (handleDoc.exists) {
        throw HandleAlreadyTakenException();
      }

      transaction.set(handleRef, {
        'user_id': authenticatedUid,
        'assigned_at': FieldValue.serverTimestamp(),
      });

      transaction.update(userProfileRef, {
        'user_name': requestedHandle,
      });
    });
  }

  Future<void> syncGoogleUserToFirestore(User firebaseAuthUser) async {
    final deviceId = await DeviceService.getDeviceId();
    final userRef = _firestore.collection('users').doc(firebaseAuthUser.uid);

    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(userRef);

      if (docSnapshot.exists) {
        // Case A (Document Already Exists): Execute atomic field update only on the device matrix block
        // to preserve prior user profile configuration overrides.
        final data = docSnapshot.data();
        final currentWorkspaces = data?['current_workspaces'] as Map?;
        final existingValue = currentWorkspaces?[deviceId] ?? '';

        transaction.update(userRef, {
          'current_workspaces.$deviceId': existingValue,
        });
      } else {
        // Case B (First Time Sign-In Detected): Initialize a brand new document record
        final String email = firebaseAuthUser.email ?? '';
        String userName = 'Altr Member';
        if (email.isNotEmpty && email.contains('@')) {
          userName = email.split('@')[0];
        } else {
          userName = 'altr_${firebaseAuthUser.uid.substring(0, 5)}';
        }

        transaction.set(userRef, {
          'user_id': firebaseAuthUser.uid,
          'user_name': userName,
          'display_name': firebaseAuthUser.displayName ?? 'Altr Member',
          'photo_url': firebaseAuthUser.photoURL ?? '',
          'email_id': email,
          'active_workspaces': <String>[],
          'current_workspaces': {deviceId: ""},
          'onboarding_completed': false,
          'profile_onboarding_completed': false,
          'workspace_onboarding_completed': false,
        });
      }
    });
  }
}

