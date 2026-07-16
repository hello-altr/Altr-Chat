import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat/models/channel_model.dart';

class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;
}

void main() {
  group('ChannelModel Tests', () {
    test('fromFirestore parses user_groups correctly', () {
      final doc = FakeDocumentSnapshot('channel_1', {
        'name': 'General',
        'is_private': false,
        'is_archived': false,
        'last_message': 'Hello world',
        'unread_count': 2,
        'warning_count': 0,
        'created_by': 'user_admin',
        'members': ['user_1', 'user_2'],
        'managers': ['user_admin'],
        'user_groups': ['group_devs', 'group_designers'],
      });

      final channel = ChannelModel.fromFirestore(doc);

      expect(channel.id, 'channel_1');
      expect(channel.name, 'General');
      expect(channel.isPrivate, false);
      expect(channel.isArchived, false);
      expect(channel.lastMessage, 'Hello world');
      expect(channel.unreadCount, 2);
      expect(channel.warningCount, 0);
      expect(channel.createdBy, 'user_admin');
      expect(channel.members, ['user_1', 'user_2']);
      expect(channel.managers, ['user_admin']);
      expect(channel.userGroups, ['group_devs', 'group_designers']);
    });

    test('fromFirestore defaults user_groups to empty list when absent', () {
      final doc = FakeDocumentSnapshot('channel_2', {
        'name': 'Random',
        'is_private': true,
        'members': ['user_3'],
      });

      final channel = ChannelModel.fromFirestore(doc);

      expect(channel.id, 'channel_2');
      expect(channel.name, 'Random');
      expect(channel.isPrivate, true);
      expect(channel.userGroups, isEmpty);
    });
  });
}
