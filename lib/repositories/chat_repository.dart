// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// Models
import 'package:chat/models/channel_model.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/models/dm_model.dart';

// Providers
import 'package:chat/providers/auth_provider.dart';

class WorkspaceNavigationState {
  final List<ChannelModel> channels;
  final List<DmModel> dms;

  const WorkspaceNavigationState({
    required this.channels,
    required this.dms,
  });
}

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, AltrUser> _userProfileCache = {};

  bool hasCachedUser(String userId) => _userProfileCache.containsKey(userId);
  AltrUser? getCachedUser(String userId) => _userProfileCache[userId];
  void cacheUser(String userId, AltrUser user) {
    _userProfileCache[userId] = user;
  }

  Future<void> createChannel({
    required String workspaceId,
    required String channelName,
    required String type,
    required String currentUserId,
  }) async {
    final cleanName = channelName.replaceAll(' ', '').toLowerCase();
    final String nameInput = cleanName.startsWith('#') ? cleanName : '#$cleanName';
    final String displayName = nameInput.replaceAll('#', '');

    final docRef = _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('channels')
        .doc();

    await docRef.set({
      'channel_name': nameInput,
      'name': displayName,
      'type': type,
      'is_private': type == 'private',
      'created_by': currentUserId,
      'created_at': FieldValue.serverTimestamp(),
      'is_archived': false,
      'last_message': 'Workspace channel created.',
      'last_message_time': FieldValue.serverTimestamp(),
      'unread_count': 0,
      'warning_count': 0,
      'members': [currentUserId],
    });
  }

  Future<String> initializeDM({
    required String workspaceId,
    required String currentUserId,
    required String targetUserId,
  }) async {
    final String dmId = currentUserId.compareTo(targetUserId) < 0
        ? '${currentUserId}_$targetUserId'
        : '${targetUserId}_$currentUserId';

    final dmRef = _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('dms')
        .doc(dmId);

    DocumentSnapshot snapshot;
    try {
      snapshot = await dmRef.get(const GetOptions(source: Source.cache));
    } catch (_) {
      snapshot = await dmRef.get();
    }

    if (!snapshot.exists) {
      final batch = _firestore.batch();
      batch.set(dmRef, {
        'participants': [currentUserId, targetUserId],
        'last_message_time': FieldValue.serverTimestamp(),
        'last_message_preview': 'Room opened',
        'last_message': 'Room opened',
        'unread_count': 0,
      });
      await batch.commit();
    }
    return dmId;
  }

  Stream<List<ChannelModel>> watchChannels(String workspaceId, String userId) {
    return _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('channels')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChannelModel.fromFirestore(doc))
          .where((ch) => !ch.isArchived)
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Stream<List<DmModel>> watchDms(String workspaceId, String userId) {
    return _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('dms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DmModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final timeA = a.lastMessageTime;
        final timeB = b.lastMessageTime;
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); // Descending (newest first)
      });
      return list;
    });
  }

  Stream<WorkspaceNavigationState> watchWorkspaceNavigation(String workspaceId, String userId) {
    final channelStream = watchChannels(workspaceId, userId);
    final dmStream = watchDms(workspaceId, userId);

    StreamController<WorkspaceNavigationState>? controller;
    StreamSubscription? channelSub;
    StreamSubscription? dmSub;

    List<ChannelModel> lastChannels = [];
    List<DmModel> lastDms = [];

    void emit() {
      if (controller != null && !controller.isClosed) {
        controller.add(WorkspaceNavigationState(channels: lastChannels, dms: lastDms));
      }
    }

    controller = StreamController<WorkspaceNavigationState>(
      onListen: () {
        channelSub = channelStream.listen(
          (channels) {
            lastChannels = channels;
            emit();
          },
          onError: (e) => controller?.addError(e),
        );
        dmSub = dmStream.listen(
          (dms) {
            lastDms = dms;
            emit();
          },
          onError: (e) => controller?.addError(e),
        );
      },
      onCancel: () {
        channelSub?.cancel();
        dmSub?.cancel();
      },
    );

    return controller.stream;
  }
}

// Providers
final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

final channelsStreamProvider = StreamProvider.family<List<ChannelModel>, String>((ref, workspaceId) {
  final repo = ref.watch(chatRepositoryProvider);
  final authUser = ref.watch(authStateProvider).value;
  final userId = authUser?.uid ?? '';
  return repo.watchChannels(workspaceId, userId);
});

final dmsStreamProvider = StreamProvider.family<List<DmModel>, String>((ref, workspaceId) {
  final repo = ref.watch(chatRepositoryProvider);
  final authUser = ref.watch(authStateProvider).value;
  final userId = authUser?.uid ?? '';
  return repo.watchDms(workspaceId, userId);
});

final workspaceNavigationStreamProvider = StreamProvider<WorkspaceNavigationState>((ref) {
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  final authUser = ref.watch(authStateProvider).value;
  
  if (workspaceId == null || authUser == null) {
    return Stream.value(const WorkspaceNavigationState(channels: [], dms: []));
  }

  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchWorkspaceNavigation(workspaceId, authUser.uid);
});

// User Profile Resolver for DMs display name resolution
final userProfileByIdProvider = FutureProvider.family<AltrUser?, String>((ref, userId) async {
  final repo = ref.watch(chatRepositoryProvider);
  if (repo.hasCachedUser(userId)) {
    return repo.getCachedUser(userId);
  }

  // Try fetching from local cache first
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get(const GetOptions(source: Source.cache));
    if (doc.exists && doc.data() != null) {
      final user = AltrUser.fromMap(doc.data()!, activeWorkspaceId: '');
      repo.cacheUser(userId, user);
      return user;
    }
  } catch (_) {}

  // Fallback to server
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (doc.exists && doc.data() != null) {
    final user = AltrUser.fromMap(doc.data()!, activeWorkspaceId: '');
    repo.cacheUser(userId, user);
    return user;
  }
  return null;
});

// Stream Provider for Workspace Members
final workspaceMembersStreamProvider = StreamProvider.family<List<AltrUser>, String>((ref, workspaceId) {
  final repo = ref.watch(chatRepositoryProvider);
  return FirebaseFirestore.instance
      .collection('users')
      .where('joined_workspaces', arrayContains: workspaceId)
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs
        .map((doc) => AltrUser.fromMap(doc.data(), activeWorkspaceId: workspaceId))
        .toList();
    // Cache the resolved users in memory as well
    for (final user in list) {
      repo.cacheUser(user.userId, user);
    }
    return list;
  });
});

// Workspace Meta Provider for unread tracking badges
final workspaceMetaProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, activeWorkspaceId) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .collection('workspace_meta')
      .doc(activeWorkspaceId)
      .snapshots()
      .map((doc) => doc.data());
});

// Streams to monitor specific active channel or DM
final activeChannelProvider = StreamProvider.family<ChannelModel?, String>((ref, channelId) {
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  if (workspaceId == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('workspaces')
      .doc(workspaceId)
      .collection('channels')
      .doc(channelId)
      .snapshots()
      .map((doc) => doc.exists ? ChannelModel.fromFirestore(doc) : null);
});

final activeDmProvider = StreamProvider.family<DmModel?, String>((ref, dmId) {
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  if (workspaceId == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('workspaces')
      .doc(workspaceId)
      .collection('dms')
      .doc(dmId)
      .snapshots()
      .map((doc) => doc.exists ? DmModel.fromFirestore(doc) : null);
});


