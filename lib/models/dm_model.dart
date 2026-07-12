import 'package:cloud_firestore/cloud_firestore.dart';

class DmModel {
  final String id;
  final List<String> participants;
  final String userName;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final DateTime? lastMessageTime;

  const DmModel({
    required this.id,
    required this.participants,
    required this.userName,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    this.lastMessageTime,
  });

  factory DmModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['last_message_time'] as Timestamp?;
    return DmModel(
      id: doc.id,
      participants: (data['participants'] as List?)?.map((e) => e.toString()).toList().cast<String>() ?? <String>[],
      userName: '', // Will resolve using participant lookup/cache in UI or provider
      lastMessage: data['last_message'] ?? '',
      time: timestamp != null ? _formatTimestamp(timestamp) : '',
      unreadCount: data['unread_count'] ?? 0,
      lastMessageTime: timestamp?.toDate(),
    );
  }

  DmModel copyWith({
    String? id,
    List<String>? participants,
    String? userName,
    String? lastMessage,
    String? time,
    int? unreadCount,
    DateTime? lastMessageTime,
  }) {
    return DmModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      userName: userName ?? this.userName,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }

  static String _formatTimestamp(Timestamp timestamp) {
    final dt = timestamp.toDate();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}
