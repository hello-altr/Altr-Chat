// Mock Data Configuration for Aero Chat
import 'package:chat/models/activity_notification.dart';
import 'package:chat/models/channel_model.dart';
import 'package:chat/models/dm_model.dart';

export 'package:chat/models/activity_notification.dart';
export 'package:chat/models/channel_model.dart';
export 'package:chat/models/dm_model.dart';

// Premium mock data source for Workspace Channels
const List<ChannelModel> mockChannels = [
  ChannelModel(
    name: 'general',
    isPrivate: false,
    lastMessage: 'Welcome to HelloAltr Chat! Let us get started.',
    time: '10:30 AM',
    unreadCount: 2,
    warningCount: 0,
  ),
  ChannelModel(
    name: 'project-altr',
    isPrivate: true,
    lastMessage: 'We should review the new layout specs carefully.',
    time: 'Yesterday',
    unreadCount: 0,
    warningCount: 1,
  ),
  ChannelModel(
    name: 'design-assets',
    isPrivate: false,
    lastMessage: 'References are uploaded to /docs directory.',
    time: 'Monday',
    unreadCount: 5,
    warningCount: 0,
  ),
  ChannelModel(
    name: 'announcements',
    isPrivate: false,
    lastMessage: 'Version 1.0 architecture launch today!',
    time: 'Jul 1',
    unreadCount: 0,
    warningCount: 0,
  ),
  ChannelModel(
    name: 'random',
    isPrivate: false,
    lastMessage: 'Check out this cool new glassmorphism visualizer!',
    time: '2 days ago',
    unreadCount: 0,
    warningCount: 0,
  ),
];

// Premium mock data source for Direct Messages
const List<DmModel> mockDms = [
  DmModel(
    userName: 'Asher',
    lastMessage: 'Hey, can you help me check this code?',
    time: '11:15 AM',
    unreadCount: 1,
  ),
  DmModel(
    userName: 'Sophia',
    lastMessage: 'The designs look amazing! Let us go ahead.',
    time: '9:45 AM',
    unreadCount: 0,
  ),
  DmModel(
    userName: 'Benjamin',
    lastMessage: 'I will join the call in 5 mins.',
    time: 'Yesterday',
    unreadCount: 0,
  ),
  DmModel(
    userName: 'Olivia',
    lastMessage: 'Let us catch up later.',
    time: 'Monday',
    unreadCount: 3,
  ),
  DmModel(
    userName: 'Emma',
    lastMessage: 'Thanks for the review!',
    time: 'Jun 28',
    unreadCount: 0,
  ),
];

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
