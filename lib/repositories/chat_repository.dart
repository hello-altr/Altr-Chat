import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat/models/channel_model.dart';
import 'package:chat/models/dm_model.dart';
import 'package:chat/models/user_model.dart';
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
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (doc.exists && doc.data() != null) {
    return AltrUser.fromMap(doc.data()!, activeWorkspaceId: '');
  }
  return null;
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


