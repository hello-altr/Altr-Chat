// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import 'dart:async';

// Models
import 'package:chat/models/message_model.dart';
import 'package:chat/models/channel_model.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/models/dm_model.dart';

// Providers
import 'package:chat/providers/auth_provider.dart';

// Repositories
import 'package:chat/repositories/user_cache_repository.dart';
import 'package:chat/utils/provider_extension.dart';

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
    dev.log(
      'createChannel called with workspaceId: "$workspaceId", channelName: "$channelName", type: "$type", currentUserId: "$currentUserId"',
      name: 'ChatRepository',
    );
    final cleanName = channelName.replaceAll(' ', '').toLowerCase();
    final String nameInput = cleanName.startsWith('#') ? cleanName : '#$cleanName';
    final String displayName = nameInput.replaceAll('#', '');

    final docRef = _firestore
        .collection('chats')
        .doc(workspaceId)
        .collection('channels')
        .doc();

    dev.log('Creating channel at path: "${docRef.path}"', name: 'ChatRepository');

    try {
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
      dev.log('Successfully created channel document in Firestore.', name: 'ChatRepository');
    } catch (e, stack) {
      dev.log(
        'Failed to set channel document in Firestore: $e',
        name: 'ChatRepository',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
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
        .collection('chats')
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
        .collection('chats')
        .doc(workspaceId)
        .collection('channels')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChannelModel.fromFirestore(doc))
          .where((ch) => !ch.isArchived)
          .where((ch) => !ch.isPrivate || ch.members.contains(userId))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Stream<List<DmModel>> watchDms(String workspaceId, String userId) {
    return _firestore
        .collection('chats')
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

  Future<void> clearChatHistory({
    required String workspaceId,
    required String id,
    required bool isChannel,
  }) async {
    final docRef = _firestore
        .collection('chats')
        .doc(workspaceId)
        .collection(isChannel ? 'channels' : 'dms')
        .doc(id);

    if (isChannel) {
      await docRef.update({
        'last_message': 'History cleared',
        'last_message_time': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.update({
        'last_message': 'History cleared',
        'last_message_preview': 'History cleared',
        'last_message_time': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteChat({
    required String workspaceId,
    required String id,
    required bool isChannel,
  }) async {
    final docRef = _firestore
        .collection('chats')
        .doc(workspaceId)
        .collection(isChannel ? 'channels' : 'dms')
        .doc(id);

    // Delete all messages in the subcollection first to avoid residual data in Firestore
    final messagesSnapshot = await docRef.collection('messages').get();
    if (messagesSnapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await docRef.delete();
  }
}

// Providers
final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

final workspaceChannelsStreamProvider = StreamProvider.autoDispose.family<List<ChannelModel>, String>((ref, workspaceId) {
  // Prevent duplicate baseline fetches during temporary workspace configuration adjustments
  ref.keepAliveFor(const Duration(minutes: 5));
  if (workspaceId.isEmpty) return Stream.value([]);
  final repo = ref.watch(chatRepositoryProvider);
  final authUser = ref.watch(authStateProvider).value;
  final userId = authUser?.uid ?? '';
  return repo.watchChannels(workspaceId, userId);
});

final channelsStreamProvider = workspaceChannelsStreamProvider;

final workspaceDmsStreamProvider = StreamProvider.autoDispose.family<List<DmModel>, String>((ref, workspaceId) {
  // Prevent duplicate baseline fetches during temporary workspace configuration adjustments
  ref.keepAliveFor(const Duration(minutes: 5));
  if (workspaceId.isEmpty) return Stream.value([]);
  final repo = ref.watch(chatRepositoryProvider);
  final authUser = ref.watch(authStateProvider).value;
  final userId = authUser?.uid ?? '';
  return repo.watchDms(workspaceId, userId);
});

final dmsStreamProvider = workspaceDmsStreamProvider;

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
final userProfileByIdProvider = FutureProvider.autoDispose.family<AltrUser?, String>((ref, userId) async {
  // Prevent duplicate baseline fetches during temporary workspace configuration adjustments
  ref.keepAliveFor(const Duration(minutes: 5));

  // Check ChatRepository cache first (populated by workspaceMembersStreamProvider)
  final chatRepo = ref.watch(chatRepositoryProvider);
  if (chatRepo.hasCachedUser(userId)) {
    return chatRepo.getCachedUser(userId);
  }

  // Watch only the changes of the specific user in the cache map to avoid unnecessary rebuilds/flickers
  final cachedUser = ref.watch(userCacheRepositoryProvider.select((map) => map[userId]));
  if (cachedUser != null) {
    return cachedUser;
  }

  return ref.watch(userCacheRepositoryProvider.notifier).getUser(userId);
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
      .collection('chats')
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
      .collection('chats')
      .doc(workspaceId)
      .collection('dms')
      .doc(dmId)
      .snapshots()
      .map((doc) => doc.exists ? DmModel.fromFirestore(doc) : null);
});

final channelMessagesStreamProvider = StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, channelId) {
  ref.keepAliveFor(const Duration(minutes: 5));
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  if (workspaceId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('chats')
      .doc(workspaceId)
      .collection('channels')
      .doc(channelId)
      .collection('messages')
      .orderBy('time', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
  });
});

final dmMessagesStreamProvider = StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, dmId) {
  ref.keepAliveFor(const Duration(minutes: 5));
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  if (workspaceId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('chats')
      .doc(workspaceId)
      .collection('dms')
      .doc(dmId)
      .collection('messages')
      .orderBy('time', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
  });
});


