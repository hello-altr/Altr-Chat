// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/chat_state_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/nav_provider.dart';

// Widgets
import 'package:chat/widgets/universal_search_bar.dart';
import 'package:chat/widgets/empty_state.dart';

// Actions
import 'package:chat/actions/chat_actions.dart';

// Enums & Dummy Data
import 'package:chat/enums/layout_mode.dart';
import 'package:chat/dummy_data.dart';

// Helper to generate a premium background hue from a string
Color getInitialsBgColor(String name) {
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

class DirectMessagesList extends ConsumerStatefulWidget {
  const DirectMessagesList({super.key});

  @override
  ConsumerState<DirectMessagesList> createState() => _DirectMessagesListState();
}

class _DirectMessagesListState extends ConsumerState<DirectMessagesList> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(dmSearchQueryProvider));
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
    final searchQuery = ref.watch(dmSearchQueryProvider);

    final filteredDms = mockDms.where((dm) {
      final query = searchQuery.toLowerCase();
      return dm.userName.toLowerCase().contains(query) ||
          dm.lastMessage.toLowerCase().contains(query);
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
                'Direct Messages',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              // Stylized modern pill search bar
              UniversalSearchBar(
                controller: _searchController,
                hintText: 'Search chats...',
                searchQuery: searchQuery,
                onChanged: (value) {
                  ref.read(dmSearchQueryProvider.notifier).state = value;
                },
                onClear: () {
                  _searchController.clear();
                  ref.read(dmSearchQueryProvider.notifier).state = '';
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredDms.isEmpty
                    ? EmptyStateWidget(
                        icon: HugeIconsStroke.user,
                        title: "No conversations found",
                        subtitle: searchQuery.isNotEmpty
                            ? 'We couldn\'t find any active direct messages matching "$searchQuery".'
                            : "There are no direct message feeds open right now.",
                        onActionPressed: searchQuery.isNotEmpty
                            ? () {
                                _searchController.clear();
                                ref.read(dmSearchQueryProvider.notifier).state = '';
                              }
                            : () => ChatActions.triggerNewDm(context),
                        actionLabel: searchQuery.isNotEmpty ? "Clear search" : "Find a Member",
                        actionIcon: searchQuery.isNotEmpty ? Icons.refresh : Icons.search,
                        onSecondaryActionPressed: searchQuery.isNotEmpty
                            ? () => ChatActions.triggerNewDm(context)
                            : () => ChatActions.triggerInviteCoworkers(context),
                        secondaryActionLabel: searchQuery.isNotEmpty ? "Find a Member" : "Invite Coworkers",
                        secondaryActionIcon: searchQuery.isNotEmpty ? Icons.search : Icons.person_add,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90), // Spacing for floating pill
                        itemCount: filteredDms.length,
                        itemBuilder: (context, index) {
                          final dm = filteredDms[index];
                          final isSelected = activeChatId == dm.userName && chatSession.type == ChatSessionType.dm;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: InkWell(
                              onTap: () {
                                // Update active navigation state index to DMs (index 0)
                                ref.read(navIndexProvider.notifier).state = 0;
                                
                                // Populate active chat session
                                ref.read(activeChatSessionProvider.notifier).state = ActiveChatSession(
                                  chatId: dm.userName,
                                  type: ChatSessionType.dm,
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
                                    // User Avatar representation
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected && layoutMode == LayoutMode.desktop
                                            ? theme.colorScheme.primary.withAlpha(40)
                                            : getInitialsBgColor(dm.userName),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        dm.userName.substring(0, dm.userName.length > 1 ? 2 : 1).toUpperCase(),
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected && layoutMode == LayoutMode.desktop
                                              ? theme.colorScheme.primary
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // User details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dm.userName,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: isSelected && layoutMode == LayoutMode.desktop
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dm.lastMessage,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Time and Badge Column on the right
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dm.time,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                                          ),
                                        ),
                                        if (dm.unreadCount > 0) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 20,
                                            height: 20,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '${dm.unreadCount}',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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

class DmsStageView extends StatelessWidget {
  const DmsStageView({super.key});

  @override
  Widget build(BuildContext context) {
    return const DirectMessagesList();
  }
}
