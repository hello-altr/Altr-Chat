class ActivityNotification {
  final String chatName;
  final String preview;
  final String time;
  final String category; // 'all', 'mentions', 'registrations'

  const ActivityNotification({
    required this.chatName,
    required this.preview,
    required this.time,
    required this.category,
  });
}
