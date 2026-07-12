import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String content;
  final DateTime? timestamp;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.content,
    this.timestamp,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['timestamp'] as Timestamp?;
    return MessageModel(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? '',
      senderPhotoUrl: data['sender_photo_url'] ?? '',
      content: data['content'] ?? '',
      timestamp: timestamp?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_photo_url': senderPhotoUrl,
      'content': content,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
    };
  }
}
