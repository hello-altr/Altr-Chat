class ChannelModel {
  final String name;
  final bool isPrivate;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final int warningCount;

  const ChannelModel({
    required this.name,
    required this.isPrivate,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.warningCount,
  });
}
