// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/nav_provider.dart';

// Widgets
import 'package:chat/widgets/workspace_dropdown_switcher.dart';
import 'package:chat/widgets/chat/user_group_info_panel.dart';
import 'package:chat/widgets/chat/channel_info_modal.dart';
import 'package:chat/widgets/floating_nav_pill.dart';
import 'package:chat/widgets/empty_state.dart';

// Pages
import 'package:chat/pages/shared_chat_canvas.dart';
import 'package:chat/pages/notifications_page.dart';
import 'package:chat/pages/appearance_page.dart';
import 'package:chat/pages/workspace_info.dart';
import 'package:chat/pages/channels_page.dart';
import 'package:chat/pages/settings_page.dart';
import 'package:chat/pages/profile_page.dart';
import 'package:chat/pages/user_page.dart';
import 'package:chat/pages/dms_page.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  double _sidebarWidth = 400.0;
  double _profileSidebarWidth = 350.0;
  late PageController _sidebarPageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(navIndexProvider);
    _sidebarPageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _sidebarPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navIndexProvider);
    final chatSession = ref.watch(activeChatSessionProvider);
    final activeSettingsPanel = ref.watch(activeSettingsPanelProvider);
    final currentSettingsTab = ref.watch(currentSettingsTabProvider);
    final theme = Theme.of(context);

    // Listen to tab selection changes to animate the horizontal PageView directory
    ref.listen<int>(navIndexProvider, (previous, next) {
      if (_sidebarPageController.hasClients && next != _sidebarPageController.page?.round()) {
        if (previous != null && (next - previous).abs() > 1) {
          _sidebarPageController.jumpToPage(next);
        } else {
          _sidebarPageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    });

    // Column 2 Layout Selector (Main Content View)
    final Widget centralViewCanvas = switch (selectedIndex) {
      0 => chatSession.type == ChatSessionType.dm && chatSession.chatId != null
          ? SharedChatCanvas(
              chatId: chatSession.chatId,
              isReadOnly: false,
              key: ValueKey('dm-${chatSession.chatId}'),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    HugeIconsStroke.chat01,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Active DMs Chat Space Preview",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a conversation to start chatting.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
      1 => chatSession.type == ChatSessionType.channel && chatSession.chatId != null
          ? SharedChatCanvas(
              chatId: chatSession.chatId,
              isReadOnly: false,
              key: ValueKey('channel-${chatSession.chatId}'),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    HugeIconsStroke.hashtag,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Active Channels Chat Space Preview",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a channel to view the workspace.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
      2 => switch (currentSettingsTab) {
          SettingsPanelType.profile => const ProfileCardInspector(),
          SettingsPanelType.appearance => const AppearanceSettingsPanel(),
          SettingsPanelType.workspaceInfo => const WorkspaceInfoPage(),
          SettingsPanelType.usersAndGroups => const UsersAndGroupsPage(),
          SettingsPanelType.notifications => const NotificationsPanelPage(),
          _ => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420.0),
                child: const EmptyStateWidget(
                  icon: Icons.palette_outlined,
                  title: "Appearance Settings",
                  subtitle: "Select a configuration option from the index tier panel to begin personalization profiles.",
                ),
              ),
            ),
        },
      _ => const SizedBox.shrink(),
    };

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: _sidebarWidth,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: _sidebarPageController,
                            onPageChanged: (index) {
                              ref.read(navIndexProvider.notifier).state = index;
                              // Clear chat session trace if it doesn't match the new tab type
                              final currentSession = ref.read(activeChatSessionProvider);
                              if (index == 0 && currentSession.type != ChatSessionType.dm) {
                                ref.read(activeChatSessionProvider.notifier).state = const ActiveChatSession();
                              } else if (index == 1 && currentSession.type != ChatSessionType.channel) {
                                ref.read(activeChatSessionProvider.notifier).state = const ActiveChatSession();
                              } else if (index == 2) {
                                ref.read(activeChatSessionProvider.notifier).state = const ActiveChatSession();
                              }
                              ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
                              ref.read(currentSettingsTabProvider.notifier).state = SettingsPanelType.none;
                            },
                            children: const [
                              DirectMessagesList(),
                              WorkspaceChannelsTree(),
                              SettingsIndexHub(),
                            ],
                          ),
                        ),
                        const FloatingNavPill(isDesktop: true),
                      ],
                    ),
                    Positioned(
                      top: 12.0 + MediaQuery.of(context).padding.top,
                      right: 16.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              ref.read(activeSettingsPanelProvider.notifier).state =
                                  activeSettingsPanel == SettingsPanelType.notifications
                                      ? SettingsPanelType.none
                                      : SettingsPanelType.notifications;
                            },
                            child: Tooltip(
                              message: 'Notifications',
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: activeSettingsPanel == SettingsPanelType.notifications
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: activeSettingsPanel == SettingsPanelType.notifications
                                        ? theme.colorScheme.primary.withAlpha(100)
                                        : theme.colorScheme.outlineVariant.withAlpha(100),
                                  ),
                                ),
                                child: Icon(
                                  activeSettingsPanel == SettingsPanelType.notifications
                                      ? HugeIconsSolid.notification02
                                      : HugeIconsStroke.notification02,
                                  size: 22,
                                  color: activeSettingsPanel == SettingsPanelType.notifications
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const WorkspaceDropdownSwitcher(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 1px Divider
              Container(
                width: 1,
                color: theme.colorScheme.outlineVariant.withAlpha(120),
              ),

              // Column 2: Central Context Communication Stage Canvas
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: centralViewCanvas),
                    if ((selectedIndex == 0 || selectedIndex == 1 || (selectedIndex == 2 && currentSettingsTab == SettingsPanelType.usersAndGroups)) &&
                        (activeSettingsPanel == SettingsPanelType.profile ||
                         activeSettingsPanel == SettingsPanelType.notifications ||
                         activeSettingsPanel == SettingsPanelType.channelInfo ||
                         activeSettingsPanel == SettingsPanelType.userGroupInfo)) ...[
                      // 1px Divider
                      Container(
                        width: 1,
                        color: theme.colorScheme.outlineVariant.withAlpha(120),
                      ),
                      SizedBox(
                        width: _profileSidebarWidth,
                        child: switch (activeSettingsPanel) {
                          SettingsPanelType.profile => const ProfileCardInspector(),
                          SettingsPanelType.notifications => const NotificationsPanelPage(),
                          SettingsPanelType.channelInfo => const ChannelInfoPanel(),
                          SettingsPanelType.userGroupInfo => const UserGroupInfoPanel(),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Resize drag handle overlay (Left Sidebar)
          Positioned(
            left: _sidebarWidth - 5,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(400.0, 520.0);
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 10,
                  color: Colors.transparent,
                ),
              ),
            ),
          ),

          // Resize drag handle overlay (Right Settings Sidebar)
          if ((selectedIndex == 0 || selectedIndex == 1) &&
              (activeSettingsPanel == SettingsPanelType.profile ||
               activeSettingsPanel == SettingsPanelType.notifications ||
               activeSettingsPanel == SettingsPanelType.channelInfo))
            Positioned(
              right: _profileSidebarWidth - 5,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _profileSidebarWidth = (_profileSidebarWidth - details.delta.dx).clamp(300.0, 500.0);
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: 10,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
