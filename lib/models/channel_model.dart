import 'package:cloud_firestore/cloud_firestore.dart';

class ChannelModel {
  final String id;
  final String name;
  final bool isPrivate;
  final bool isArchived;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final int warningCount;
  final DateTime? lastMessageTime;
  final String createdBy;
  final List<String> members;
  final List<String> managers;

  const ChannelModel({
    required this.id,
    required this.name,
    required this.isPrivate,
    this.isArchived = false,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.warningCount,
    this.lastMessageTime,
    required this.createdBy,
    required this.members,
    required this.managers,
  });

  factory ChannelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['last_message_time'] as Timestamp?;
    return ChannelModel(
      id: doc.id,
      name: data['name'] ?? '',
      isPrivate: data['is_private'] ?? false,
      isArchived: data['is_archived'] ?? false,
      lastMessage: data['last_message'] ?? '',
      time: timestamp != null ? _formatTimestamp(timestamp) : '',
      unreadCount: data['unread_count'] ?? 0,
      warningCount: data['warning_count'] ?? 0,
      lastMessageTime: timestamp?.toDate(),
      createdBy: data['created_by'] ?? '',
      members: (data['members'] as List?)?.map((e) => e.toString()).toList().cast<String>() ?? <String>[],
      managers: (data['managers'] as List?)?.map((e) => e.toString()).toList().cast<String>() ?? <String>[],
    );
  }

  static String _formatTimestamp(Timestamp timestamp) {
    final dt = timestamp.toDate();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}
