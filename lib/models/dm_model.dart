class DmModel {
  final String userName;
  final String lastMessage;
  final String time;
  final int unreadCount;

  const DmModel({
    required this.userName,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
  });
}
