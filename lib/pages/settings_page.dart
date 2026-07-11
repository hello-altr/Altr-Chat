// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Providers
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/layout_provider.dart';

// Enums
import 'package:chat/enums/layout_mode.dart';

// Widgets
import 'package:chat/widgets/section_header.dart';
import 'package:chat/widgets/setting_item.dart';

// Services
import 'package:chat/services/show_signout_dialog.dart';
import 'package:chat/services/add_workspace_flow.dart';

// Component 1: SettingsIndexHub (Column 1 on Desktop / Segment on Mobile)
class SettingsIndexHub extends ConsumerStatefulWidget {
  const SettingsIndexHub({super.key});

  @override
  ConsumerState<SettingsIndexHub> createState() => _SettingsIndexHubState();
}

class _SettingsIndexHubState extends ConsumerState<SettingsIndexHub> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ref.watch(layoutProvider) == LayoutMode.desktop;
    final activeSettingsPanel = ref.watch(activeSettingsPanelProvider);

    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.displayName ?? 'Aero User';
    final emailId = currentUser?.email ?? 'user@helloaltr.com';
    final photoUrl = currentUser?.photoURL;
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'A';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Settings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 90,
                ),
                children: [
                  // macOS Apple ID Card Row
                  GestureDetector(
                    onTap: () {
                      ref.read(activeSettingsPanelProvider.notifier).state =
                          SettingsPanelType.profile;
                      if (isDesktop) {
                        ref.read(activeChatSessionProvider.notifier).state =
                            const ActiveChatSession();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            activeSettingsPanel == SettingsPanelType.profile &&
                                isDesktop
                            ? theme.colorScheme.primaryContainer.withAlpha(120)
                            : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              activeSettingsPanel ==
                                      SettingsPanelType.profile &&
                                  isDesktop
                              ? theme.colorScheme.primary.withAlpha(100)
                              : theme.colorScheme.outlineVariant.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: photoUrl == null
                                  ? LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.secondary,
                                      ],
                                    )
                                  : null,
                              image: photoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(photoUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: photoUrl != null
                                ? null
                                : Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  emailId,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            HugeIconsStroke.arrowRight01,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wallet Section
                  const SectionHeader(title: 'Ledger & Wallet'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.surfaceContainerHigh,
                          theme.colorScheme.surfaceContainerHigh.withAlpha(180),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              HugeIconsStroke.walletAdd01,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Digital Wallet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ledger: active-helloaltr-v1',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ledger Status',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withAlpha(100),
                                ),
                              ),
                              child: const Text(
                                'Synchronized',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Workspaces Section
                  const SectionHeader(title: 'Workspaces'),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      children: [
                        SettingItem(
                          icon: HugeIconsStroke.passport,
                          title: 'Workspace Info',
                          isSelected: activeSettingsPanel == SettingsPanelType.workspaceInfo && isDesktop,
                          trailing: Icon(
                            HugeIconsStroke.arrowRight01,
                            color: activeSettingsPanel == SettingsPanelType.workspaceInfo && isDesktop
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          onTap: () {
                            ref.read(activeSettingsPanelProvider.notifier).state =
                                SettingsPanelType.workspaceInfo;
                            if (isDesktop) {
                              ref.read(activeChatSessionProvider.notifier).state =
                                  const ActiveChatSession();
                            }
                          },
                        ),
                        SettingItem(
                          icon: HugeIconsStroke.userGroup,
                          title: 'Users & User Groups',
                          isSelected: activeSettingsPanel == SettingsPanelType.usersAndGroups && isDesktop,
                          trailing: Icon(
                            HugeIconsStroke.arrowRight01,
                            color: activeSettingsPanel == SettingsPanelType.usersAndGroups && isDesktop
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          onTap: () {
                            ref.read(activeSettingsPanelProvider.notifier).state =
                                SettingsPanelType.usersAndGroups;
                            if (isDesktop) {
                              ref.read(activeChatSessionProvider.notifier).state =
                                  const ActiveChatSession();
                            }
                          },
                        ),
                        SettingItem(
                          icon: HugeIconsStroke.hashtag,
                          title: 'Add Workspace',
                          trailing: Icon(
                            HugeIconsStroke.arrowRight01,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          onTap: () {
                            openAddWorkspaceFlow(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // General Section
                  const SectionHeader(title: 'General'),
                  Container(
                    decoration: BoxDecoration(
                      color: activeSettingsPanel == SettingsPanelType.appearance && isDesktop
                          ? theme.colorScheme.primaryContainer.withAlpha(120)
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: activeSettingsPanel == SettingsPanelType.appearance && isDesktop
                            ? theme.colorScheme.primary.withAlpha(100)
                            : theme.colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      children: [
                        SettingItem(
                          icon: HugeIconsStroke.settings01,
                          title: 'Appearance',
                          trailing: Icon(
                            HugeIconsStroke.arrowRight01,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          onTap: () {
                            ref
                                    .read(activeSettingsPanelProvider.notifier)
                                    .state =
                                SettingsPanelType.appearance;
                            if (isDesktop) {
                              ref
                                      .read(activeChatSessionProvider.notifier)
                                      .state =
                                  const ActiveChatSession();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Session / Account Section
                  const SectionHeader(title: 'Account'),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      children: [
                        SettingItem(
                          icon: HugeIconsStroke.logout01,
                          title: 'Sign Out',
                          trailing: Icon(
                            HugeIconsStroke.arrowRight01,
                            color: theme.colorScheme.error,
                            size: 18,
                          ),
                          onTap: () => showSignOutDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 