// Packages
import 'package:chat/models/activity_notification.dart';

List<ActivityNotification> getFilteredNotifications(
  List<ActivityNotification> notifications,
  String selectedFilter,
) {
  if (selectedFilter == 'all') {
    return notifications;
  }
  return notifications
      .where((notif) => notif.category == selectedFilter)
      .toList();
}
