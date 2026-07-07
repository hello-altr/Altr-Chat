import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hugeicons_pro/hugeicons.dart';

// Providers & Models
import 'package:chat/providers/auth_provider.dart';
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/chat_state_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/nav_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/repositories/chat_repository.dart';
import 'package:chat/enums/layout_mode.dart';

// Widgets
import 'package:chat/widgets/universal_search_bar.dart';
import 'package:chat/widgets/navigation/sidebar_item_tile.dart';
import 'package:chat/widgets/empty_state.dart';

// Actions
import 'package:chat/actions/chat_actions.dart';

enum SidebarSection { channels, dms }

// Helper to generate a initials avatar background color from a string
Color _getInitialsBgColor(String name) {
  final colors = [
    const Color(0xFFF43F5E), // Rose
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
  ];
  return colors[name.hashCode % colors.length];
}

class WorkspaceSidebar extends ConsumerStatefulWidget {
  final SidebarSection initialSection;

  const WorkspaceSidebar({
    super.key,
    required this.initialSection,
  });

  @override
  ConsumerState<WorkspaceSidebar> createState() => _WorkspaceSidebarState();
}

class _WorkspaceSidebarState extends ConsumerState<WorkspaceSidebar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Read the query state based on targeted section
    final initialQuery = ref.read(
      widget.initialSection == SidebarSection.channels
          ? channelSearchQueryProvider
          : dmSearchQueryProvider,
    );
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layoutMode = ref.watch(layoutProvider);
    final isDesktop = layoutMode == LayoutMode.desktop;
    final chatSession = ref.watch(activeChatSessionProvider);
    
    // Choose appropriate search state and labels
    final searchQueryProvider = widget.initialSection == SidebarSection.channels
        ? channelSearchQueryProvider
        : dmSearchQueryProvider;
    final searchQuery = ref.watch(searchQueryProvider);

    // Watch navigation pipeline stream
    final navigationAsync = ref.watch(workspaceNavigationStreamProvider);
    
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

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
                widget.initialSection == SidebarSection.channels
                    ? 'Channels'
                    : 'Direct Messages',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              // Pill search bar
              UniversalSearchBar(
                controller: _searchController,
                hintText: widget.initialSection == SidebarSection.channels
                    ? 'Search channels...'
                    : 'Search chats...',
                searchQuery: searchQuery,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                onClear: () {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              ),
              const SizedBox(height: 16),
              
              // Load the real-time streams
              Expanded(
                child: navigationAsync.when(
                  data: (navData) {
                    final query = searchQuery.toLowerCase();

                    if (widget.initialSection == SidebarSection.channels) {
                      // --- CHANNELS LIST VIEW PAGE ---
                      final filteredChannels = navData.channels.where((ch) {
                        return ch.name.toLowerCase().contains(query) ||
                            ch.lastMessage.toLowerCase().contains(query);
                      }).toList();

                      if (filteredChannels.isEmpty) {
                        return _buildEmptyState(
                          isSearch: searchQuery.isNotEmpty,
                          searchQuery: searchQuery,
                          searchQueryProvider: searchQueryProvider,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: filteredChannels.length,
                        itemBuilder: (context, index) {
                          final channel = filteredChannels[index];
                          final isSelected = chatSession.chatId == channel.id &&
                              chatSession.type == ChatSessionType.channel;
                          return SidebarItemTile(
                            id: channel.id,
                            title: '#${channel.name}',
                            subtitle: channel.lastMessage,
                            time: channel.time,
                            lastMessageTime: channel.lastMessageTime,
                            isSelected: isSelected,
                            icon: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected && isDesktop
                                    ? theme.colorScheme.primary.withAlpha(40)
                                    : theme.colorScheme.surfaceContainerHigh,
                              ),
                              child: Icon(
                                channel.isPrivate
                                    ? HugeIconsStroke.lock
                                    : HugeIconsStroke.hashtag,
                                color: isSelected && isDesktop
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            onTap: () {
                              ref.read(navIndexProvider.notifier).state = 1;
                              ref.read(activeChatSessionProvider.notifier).state = ActiveChatSession(
                                chatId: channel.id,
                                type: ChatSessionType.channel,
                              );
                              ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
                            },
                          );
                        },
                      );
                    } else {
                      // --- DIRECT MESSAGES LIST VIEW PAGE ---
                      final filteredDms = navData.dms.map((dm) {
                        final counterpartId = dm.participants.firstWhere(
                          (id) => id != currentUserId,
                          orElse: () => currentUserId,
                        );
                        final profileAsync = ref.watch(userProfileByIdProvider(counterpartId));
                        final name = profileAsync.value?.displayName ?? 'Loading...';
                        return dm.copyWith(userName: name);
                      }).where((dm) {
                        return dm.userName.toLowerCase().contains(query) ||
                            dm.lastMessage.toLowerCase().contains(query);
                      }).toList();

                      if (filteredDms.isEmpty) {
                        return _buildEmptyState(
                          isSearch: searchQuery.isNotEmpty,
                          searchQuery: searchQuery,
                          searchQueryProvider: searchQueryProvider,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: filteredDms.length,
                        itemBuilder: (context, index) {
                          final dm = filteredDms[index];
                          final isSelected = chatSession.chatId == dm.id &&
                              chatSession.type == ChatSessionType.dm;
                          return SidebarItemTile(
                            id: dm.id,
                            title: dm.userName.isEmpty ? 'Loading...' : dm.userName,
                            subtitle: dm.lastMessage,
                            time: dm.time,
                            lastMessageTime: dm.lastMessageTime,
                            isSelected: isSelected,
                            icon: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected && isDesktop
                                    ? theme.colorScheme.primary.withAlpha(40)
                                    : _getInitialsBgColor(dm.userName.isEmpty ? 'Loading...' : dm.userName),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (dm.userName.isEmpty ? 'L' : dm.userName)
                                    .substring(0, (dm.userName.length > 1 ? 2 : 1))
                                    .toUpperCase(),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected && isDesktop
                                      ? theme.colorScheme.primary
                                      : Colors.white,
                                ),
                              ),
                            ),
                            onTap: () {
                              ref.read(navIndexProvider.notifier).state = 0;
                              ref.read(activeChatSessionProvider.notifier).state = ActiveChatSession(
                                  chatId: dm.id,
                                  type: ChatSessionType.dm,
                              );
                              ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
                            },
                          );
                        },
                      );
                    }
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Error loading chats list: $err",
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isSearch,
    required String searchQuery,
    required StateProvider<String> searchQueryProvider,
  }) {
    if (isSearch) {
      return EmptyStateWidget(
        icon: widget.initialSection == SidebarSection.channels
            ? HugeIconsStroke.hashtag
            : HugeIconsStroke.user,
        title: "No matches found",
        subtitle: 'We couldn\'t find anything matching "$searchQuery".',
        onActionPressed: () {
          _searchController.clear();
          ref.read(searchQueryProvider.notifier).state = '';
        },
        actionLabel: "Clear search",
        actionIcon: Icons.refresh,
      );
    } else {
      return EmptyStateWidget(
        icon: widget.initialSection == SidebarSection.channels
            ? HugeIconsStroke.hashtag
            : HugeIconsStroke.user,
        title: widget.initialSection == SidebarSection.channels
            ? "No channels found"
            : "No conversations found",
        subtitle: widget.initialSection == SidebarSection.channels
            ? "There are no channels available in this workspace."
            : "There are no direct message feeds open right now.",
        onActionPressed: widget.initialSection == SidebarSection.channels
            ? () => ChatActions.triggerCreateChannel(context)
            : () => ChatActions.triggerNewDm(context),
        actionLabel: widget.initialSection == SidebarSection.channels
            ? "Create a Channel"
            : "Find a Member",
        actionIcon: widget.initialSection == SidebarSection.channels
            ? Icons.add
            : Icons.search,
        onSecondaryActionPressed: widget.initialSection == SidebarSection.dms
            ? () => ChatActions.triggerInviteCoworkers(context)
            : null,
        secondaryActionLabel: widget.initialSection == SidebarSection.dms
            ? "Invite Coworkers"
            : null,
        secondaryActionIcon: widget.initialSection == SidebarSection.dms
            ? Icons.person_add
            : null,
      );
    }
  }
}
