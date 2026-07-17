// Packages
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final DateTime? timestamp;
  final String? quotedMessageContent;
  final String? quotedMessageSenderName;
  final bool isEdited;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.timestamp,
    this.quotedMessageContent,
    this.quotedMessageSenderName,
    this.isEdited = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = (data['timestamp'] ?? data['time']) as Timestamp?;
    return MessageModel(
      id: doc.id,
      senderId: data['sender_id'] ?? data['senderId'] ?? '',
      content: data['content'] ?? data['message'] ?? '',
      timestamp: timestamp?.toDate(),
      quotedMessageContent: data['quoted_message_content'],
      quotedMessageSenderName: data['quoted_message_sender_name'],
      isEdited: data['is_edited'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'content': content,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
      'quoted_message_content': quotedMessageContent,
      'quoted_message_sender_name': quotedMessageSenderName,
      'is_edited': isEdited,
    };
  }
}
