import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat/models/user_model.dart';

class UserCacheNotifier extends Notifier<Map<String, AltrUser>> {
  final FirebaseFirestore _firestore;
  final Map<String, Future<AltrUser?>> _inFlightRequests = {};

  UserCacheNotifier({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Map<String, AltrUser> build() {
    return const {};
  }

  Future<AltrUser?> getUser(String userId) async {
    // Check 1 (Local Hit)
    if (state.containsKey(userId)) {
      return state[userId];
    }

    // Reuse outstanding request if one is in flight
    if (_inFlightRequests.containsKey(userId)) {
      return _inFlightRequests[userId];
    }

    // Check 2 (Network Fallback)
    final future = () async {
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final user = AltrUser.fromMap(doc.data()!, activeWorkspaceId: '');
          state = {...state, userId: user};
          return user;
        }
      } catch (_) {
        // Fallback/error handling
      } finally {
        _inFlightRequests.remove(userId);
      }
      return null;
    }();

    _inFlightRequests[userId] = future;
    return future;
  }
}

final userCacheRepositoryProvider = NotifierProvider<UserCacheNotifier, Map<String, AltrUser>>(() {
  return UserCacheNotifier();
});
