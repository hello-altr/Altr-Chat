// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/chat_state_provider.dart';
import 'package:chat/providers/layout_provider.dart';

// Enums
import 'package:chat/enums/layout_mode.dart';

// Pages
import 'package:chat/pages/chat_page.dart';

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

class WorkspaceChannelsTree extends ConsumerWidget {
  const WorkspaceChannelsTree({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeChatId = ref.watch(activeChatIdProvider);
    final layoutMode = ref.watch(layoutProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Channels',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              // Stylized modern search bar
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search channels...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                    prefixIcon: Icon(
                      HugeIconsStroke.search01,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90), // Spacing for floating pill
                  itemCount: mockChannels.length,
                  itemBuilder: (context, index) {
                    final channel = mockChannels[index];
                    final isSelected = activeChatId == channel.name;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: InkWell(
                        onTap: () {
                          // Set active chat ID
                          ref.read(activeChatIdProvider.notifier).state = channel.name;
                          ref.read(isProfileActiveInSettingsDesktopProvider.notifier).state = false;

                          if (layoutMode == LayoutMode.mobile) {
                            // On Mobile, navigate to ChatPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  chatId: channel.name,
                                  isChannel: true,
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected && layoutMode == LayoutMode.desktop
                                ? theme.colorScheme.primaryContainer.withAlpha(150)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected && layoutMode == LayoutMode.desktop
                                  ? theme.colorScheme.primary.withAlpha(80)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Channel Icon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected && layoutMode == LayoutMode.desktop
                                      ? theme.colorScheme.primary.withAlpha(40)
                                      : theme.colorScheme.surfaceContainerHigh,
                                ),
                                child: Icon(
                                  channel.isPrivate
                                      ? HugeIconsStroke.lock
                                      : HugeIconsStroke.hashtag,
                                  color: isSelected && layoutMode == LayoutMode.desktop
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Channel Title and Last Message
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '#${channel.name}',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: isSelected && layoutMode == LayoutMode.desktop
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          channel.time,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      channel.lastMessage,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Badges (Unread & Warnings)
                              if (channel.unreadCount > 0 || channel.warningCount > 0) ...[
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (channel.unreadCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${channel.unreadCount}',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (channel.warningCount > 0) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.error,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          HugeIconsStroke.alert02,
                                          color: theme.colorScheme.onError,
                                          size: 10,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChannelsStageView extends StatelessWidget {
  const ChannelsStageView({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkspaceChannelsTree();
  }
}
