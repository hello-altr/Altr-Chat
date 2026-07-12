// Mock Data Configuration for Aero Chat
import 'package:chat/models/activity_notification.dart';
export 'package:chat/models/activity_notification.dart';

// Profile Page Mock Notifications
const List<ActivityNotification> mockNotifications = [
  ActivityNotification(
    chatName: 'Asher',
    preview: 'Hey, can you help me check this code?',
    time: '11:15 AM',
    category: 'all',
  ),
  ActivityNotification(
    chatName: '#project-altr',
    preview: '@aero_user please review layout specs.',
    time: 'Yesterday',
    category: 'mentions',
  ),
  ActivityNotification(
    chatName: 'Registration System',
    preview: 'New agent registered successfully.',
    time: '9:00 AM',
    category: 'registrations',
  ),
  ActivityNotification(
    chatName: '#general',
    preview: 'Welcome to HelloAltr Chat! Let us get started.',
    time: '10:30 AM',
    category: 'all',
  ),
  ActivityNotification(
    chatName: 'Registration System',
    preview: 'Workspace nodes updated.',
    time: 'Monday',
    category: 'registrations',
  ),
];
