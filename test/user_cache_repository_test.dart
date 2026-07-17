import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/repositories/user_cache_repository.dart';

// Fake implementations for Firestore classes to count reads
class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final bool _exists;

  FakeDocumentSnapshot(this._data, this._exists);

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;
}

class FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final bool _exists;
  int getCalls = 0;

  FakeDocumentReference(this._data, this._exists);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    getCalls++;
    return FakeDocumentSnapshot(_data, _exists);
  }
}

class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final bool _exists;
  final Map<String, FakeDocumentReference> _docs = {};

  FakeCollectionReference(this._data, this._exists);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return _docs.putIfAbsent(path ?? '', () => FakeDocumentReference(_data, _exists));
  }
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, dynamic>? _data;
  final bool _exists;
  final Map<String, FakeCollectionReference> _collections = {};

  FakeFirebaseFirestore({Map<String, dynamic>? data, bool exists = true})
      : _data = data,
        _exists = exists;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _collections.putIfAbsent(path, () => FakeCollectionReference(_data, _exists));
  }
}

void main() {
  group('UserCacheRepository / UserCacheNotifier Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late Map<String, dynamic> testUserData;

    setUp(() {
      testUserData = {
        'user_id': 'user_123',
        'user_name': 'john_doe',
        'display_name': 'John Doe',
        'photo_url': 'https://example.com/photo.jpg',
        'email_id': 'john@example.com',
        'joined_workspaces': ['ws_1'],
        'onboarding_completed': true,
        'profile_onboarding_completed': true,
        'workspace_onboarding_completed': true,
      };
      fakeFirestore = FakeFirebaseFirestore(data: testUserData, exists: true);
    });

    test('Cache miss calls Firestore, parses user, and atomically updates cache map state', () async {
      final container = ProviderContainer(
        overrides: [
          userCacheRepositoryProvider.overrideWith(() => UserCacheNotifier(firestore: fakeFirestore)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userCacheRepositoryProvider.notifier);

      // Verify initial state is empty
      expect(container.read(userCacheRepositoryProvider), isEmpty);

      // Fetch user profile (Cache Miss)
      final user = await notifier.getUser('user_123');

      expect(user, isNotNull);
      expect(user!.userId, 'user_123');
      expect(user.displayName, 'John Doe');

      // Verify state was atomically updated
      final stateMap = container.read(userCacheRepositoryProvider);
      expect(stateMap.containsKey('user_123'), isTrue);
      expect(stateMap['user_123']!.displayName, 'John Doe');

      // Verify that the Firestore document reference was queried exactly once
      final docRef = fakeFirestore.collection('users').doc('user_123') as FakeDocumentReference;
      expect(docRef.getCalls, 1);
    });

    test('Cache hit returns cached user profile from memory immediately without network calls (0 new reads)', () async {
      final container = ProviderContainer(
        overrides: [
          userCacheRepositoryProvider.overrideWith(() => UserCacheNotifier(firestore: fakeFirestore)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userCacheRepositoryProvider.notifier);

      // Fetch once (Cache Miss)
      await notifier.getUser('user_123');

      final docRef = fakeFirestore.collection('users').doc('user_123') as FakeDocumentReference;
      expect(docRef.getCalls, 1);

      // Fetch second time (Cache Hit)
      final userCached = await notifier.getUser('user_123');
      expect(userCached, isNotNull);
      expect(userCached!.displayName, 'John Doe');

      // Verify that Firestore getCalls remains at 1 (0 new network database reads)
      expect(docRef.getCalls, 1);
    });

    test('Multiple sequential/parallel lookups for the same user only trigger 1 network database read', () async {
      final container = ProviderContainer(
        overrides: [
          userCacheRepositoryProvider.overrideWith(() => UserCacheNotifier(firestore: fakeFirestore)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userCacheRepositoryProvider.notifier);

      // Trigger multiple lookups simultaneously
      final results = await Future.wait<AltrUser?>([
        notifier.getUser('user_123'),
        notifier.getUser('user_123'),
        notifier.getUser('user_123'),
      ]);

      // Verify all resolved correctly
      for (final user in results) {
        expect(user, isNotNull);
        expect(user!.displayName, 'John Doe');
      }

      // Verify Firestore was read exactly once
      final docRef = fakeFirestore.collection('users').doc('user_123') as FakeDocumentReference;
      expect(docRef.getCalls, 1);
    });
  });
}
