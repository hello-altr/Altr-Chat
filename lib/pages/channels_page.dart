// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/chat_state_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/nav_provider.dart';
import 'package:chat/providers/settings_provider.dart';

// Widgets
import 'package:chat/widgets/empty_state.dart';

// Actions
import 'package:chat/actions/chat_actions.dart';

// Enums & Dummy Data
import 'package:chat/enums/layout_mode.dart';
import 'package:chat/dummy_data.dart';

class WorkspaceChannelsTree extends ConsumerStatefulWidget {
  const WorkspaceChannelsTree({super.key});

  @override
  ConsumerState<WorkspaceChannelsTree> createState() => _WorkspaceChannelsTreeState();
}

class _WorkspaceChannelsTreeState extends ConsumerState<WorkspaceChannelsTree> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(channelSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatSession = ref.watch(activeChatSessionProvider);
    final activeChatId = chatSession.chatId;
    final layoutMode = ref.watch(layoutProvider);
    final searchQuery = ref.watch(channelSearchQueryProvider);

    final filteredChannels = mockChannels.where((channel) {
      return channel.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

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
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(channelSearchQueryProvider.notifier).state = value;
                  },
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
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(channelSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredChannels.isEmpty
                    ? EmptyStateWidget(
                        icon: HugeIconsStroke.hashtag,
                        title: "No channels found",
                        subtitle: searchQuery.isNotEmpty
                            ? 'We couldn\'t find any channel matching "$searchQuery".'
                            : "There are no channels available in this workspace.",
                        onActionPressed: searchQuery.isNotEmpty
                            ? () {
                                _searchController.clear();
                                ref.read(channelSearchQueryProvider.notifier).state = '';
                              }
                            : () => ChatActions.triggerCreateChannel(context),
                        actionLabel: searchQuery.isNotEmpty ? "Clear search" : "Create a Channel",
                        actionIcon: searchQuery.isNotEmpty ? Icons.refresh : Icons.add,
                        onSecondaryActionPressed: searchQuery.isNotEmpty
                            ? () => ChatActions.triggerCreateChannel(context)
                            : null,
                        secondaryActionLabel: searchQuery.isNotEmpty ? "Create a Channel" : null,
                        secondaryActionIcon: searchQuery.isNotEmpty ? Icons.add : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90), // Spacing for floating pill
                        itemCount: filteredChannels.length,
                        itemBuilder: (context, index) {
                          final channel = filteredChannels[index];
                          final isSelected = activeChatId == channel.name && chatSession.type == ChatSessionType.channel;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: InkWell(
                              onTap: () {
                                // Update active navigation state index to Channels (index 1)
                                ref.read(navIndexProvider.notifier).state = 1;
                                
                                // Populate active chat session
                                ref.read(activeChatSessionProvider.notifier).state = ActiveChatSession(
                                  chatId: channel.name,
                                  type: ChatSessionType.channel,
                                );
                                
                                ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
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
                                              Expanded(
                                                child: Text(
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
                                              ),
                                              const SizedBox(width: 8),
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
                                    // Badges Column
                                    if (channel.unreadCount > 0 || channel.warningCount > 0) ...[
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.center,
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
