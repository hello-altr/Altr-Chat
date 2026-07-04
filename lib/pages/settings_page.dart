// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Custom Widgets
import 'package:chat/widgets/workspace_flow_canvas.dart';

// Providers
import 'package:chat/providers/chat_session_provider.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/theme_provider.dart';
import 'package:chat/providers/auth_provider.dart';

// Widgets
import 'package:chat/widgets/empty_state.dart';

// Enums & Dummy Data
import 'package:chat/enums/layout_mode.dart';
import 'package:chat/theme/theme.dart';
import 'package:chat/dummy_data.dart';

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
                  _buildSectionHeader('Ledger & Wallet'),
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
                  _buildSectionHeader('Workspaces'),
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
                        _buildSettingItem(
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
                  _buildSectionHeader('General'),
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
                        _buildSettingItem(
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
                  _buildSectionHeader('Account'),
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
                        _buildSettingItem(
                          icon: HugeIconsStroke.logout01,
                          title: 'Sign Out',
                          trailing: Icon(
                            HugeIconsStroke.arrowRight01,
                            color: theme.colorScheme.error,
                            size: 18,
                          ),
                          onTap: () => _showSignOutDialog(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final dialog = AlertDialog(
          constraints: BoxConstraints(maxWidth: 400),
          title: Row(
            children: [
              Icon(HugeIconsStroke.logout01, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              const Text('Sign Out'),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out? You will need to sign in again to access your chats.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );

        return dialog;
      },
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// Component 2: ProfileCardInspector (Column 2 Central Canvas on Desktop / Top Segment on Mobile)
class ProfileCardInspector extends ConsumerStatefulWidget {
  const ProfileCardInspector({super.key});

  @override
  ConsumerState<ProfileCardInspector> createState() =>
      _ProfileCardInspectorState();
}

class _ProfileCardInspectorState extends ConsumerState<ProfileCardInspector> {
  String selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredNotifs = _getFilteredNotifications();
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;

    final currentUser = FirebaseAuth.instance.currentUser;
    final userProfile = ref.watch(userProfileProvider).value;

    final displayName = userProfile?.displayName ?? currentUser?.displayName ?? 'Aero User';
    final emailId = userProfile?.emailId ?? currentUser?.email ?? 'user@helloaltr.com';
    final photoUrl = userProfile?.photoUrl.isNotEmpty == true
        ? userProfile!.photoUrl
        : currentUser?.photoURL;
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'A';
    final usernameHandle = userProfile?.userName != null && userProfile!.userName.isNotEmpty
        ? '@${userProfile.userName}'
        : (currentUser?.email != null
            ? '@${currentUser!.email!.split("@")[0]}'
            : '@aero_user');


    // Apply layout-specific centering alignment from ideation
    return Scaffold(
      appBar: isMobile
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  ref.read(activeSettingsPanelProvider.notifier).state =
                      SettingsPanelType.none;
                },
              ),
              title: Text(
                'Profile',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.only(
                top: 24.0,
                bottom: 90,
                left: 16.0,
                right: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Centered Profile Avatar card
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
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
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withAlpha(40),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: photoUrl != null
                              ? null
                              : Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          usernameHandle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions Row with even widths and even spacing
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: HugeIconsStroke.image02,
                          label: 'Change Photo',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: HugeIconsStroke.edit01,
                          label: 'Edit Info',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: HugeIconsStroke.share01,
                          label: 'Share Profile',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Details Card
                  _buildSectionHeader('Profile Details'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: HugeIconsStroke.mail01,
                          label: 'Email ID',
                          value: emailId,
                        ),
                        Divider(
                          height: 24,
                          color: theme.colorScheme.outlineVariant.withAlpha(80),
                        ),
                        _buildDetailRow(
                          icon: HugeIconsStroke.taskDone01,
                          label: 'Bio',
                          value:
                              'Building the future of agent-first real-time chat communication on HelloAltr.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Notification Panel
                  _buildSectionHeader(
                    'Notification Panel (Slack Activity Style)',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Mentions', 'mentions'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Registrations', 'registrations'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Grouped Notification Container (iOS settings style)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: filteredNotifs.isEmpty
                        ? EmptyStateWidget(
                            icon: HugeIconsStroke.notification01,
                            title: "No notifications",
                            subtitle: selectedFilter != 'all'
                                ? "No activities found in the '$selectedFilter' category."
                                : "You are all caught up! No notifications yet.",
                            onActionPressed: selectedFilter != 'all'
                                ? () {
                                    setState(() {
                                      selectedFilter = 'all';
                                    });
                                  }
                                : null,
                            actionLabel: selectedFilter != 'all'
                                ? "Show all"
                                : null,
                          )
                        : Column(
                            children: filteredNotifs.map((notif) {
                              final isLast = filteredNotifs.last == notif;
                              return Column(
                                children: [
                                  _buildNotificationCard(notif),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      indent: 16,
                                      color: theme.colorScheme.outlineVariant
                                          .withAlpha(80),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<ActivityNotification> _getFilteredNotifications() {
    if (selectedFilter == 'all') {
      return mockNotifications;
    }
    return mockNotifications
        .where((notif) => notif.category == selectedFilter)
        .toList();
  }

  Widget _buildFilterChip(String label, String value) {
    final theme = Theme.of(context);
    final isSelected = selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedFilter = value;
          });
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildNotificationCard(ActivityNotification notification) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHigh,
            ),
            child: Icon(
              notification.category == 'registrations'
                  ? HugeIconsStroke.userCircle02
                  : (notification.chatName.startsWith('#')
                        ? HugeIconsStroke.hashtag
                        : HugeIconsStroke.user),
              color: theme.colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.chatName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      notification.time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.preview,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Component 3: AppearanceSettingsPanel
class AppearanceSettingsPanel extends ConsumerWidget {
  const AppearanceSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;
    final currentThemeMode = ref.watch(themeModeProvider);
    final selectedColor = ref.watch(themeColorOptionProvider);

    Widget themeSelectionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildThemeOption(
          context,
          ref,
          mode: ThemeMode.system,
          label: 'Auto',
          isSelected: currentThemeMode == ThemeMode.system,
          selectedColor: selectedColor,
        ),
        const SizedBox(width: 16),
        _buildThemeOption(
          context,
          ref,
          mode: ThemeMode.light,
          label: 'Light',
          isSelected: currentThemeMode == ThemeMode.light,
          selectedColor: selectedColor,
        ),
        const SizedBox(width: 16),
        _buildThemeOption(
          context,
          ref,
          mode: ThemeMode.dark,
          label: 'Dark',
          isSelected: currentThemeMode == ThemeMode.dark,
          selectedColor: selectedColor,
        ),
      ],
    );

    Widget appearanceContent;
    if (isMobile) {
      appearanceContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Mode',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: themeSelectionRow),
        ],
      );
    } else {
      appearanceContent = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Theme Mode',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          themeSelectionRow,
        ],
      );
    }

    Widget colorSelectionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildColorOptionItem(context, ref, ThemeColorOption.defaultColor, const Color(0xff096b5a), "Default", selectedColor == ThemeColorOption.defaultColor),
        const SizedBox(width: 10),
        _buildColorOptionItem(context, ref, ThemeColorOption.blue, const Color(0xFF007AFF), "", selectedColor == ThemeColorOption.blue),
        const SizedBox(width: 10),
        _buildColorOptionItem(context, ref, ThemeColorOption.purple, const Color(0xFF8E44AD), "", selectedColor == ThemeColorOption.purple),
        const SizedBox(width: 10),
        _buildColorOptionItem(context, ref, ThemeColorOption.red, const Color(0xFFFF3B30), "", selectedColor == ThemeColorOption.red),
        const SizedBox(width: 10),
        _buildColorOptionItem(context, ref, ThemeColorOption.orange, const Color(0xFFFF9500), "", selectedColor == ThemeColorOption.orange),
        const SizedBox(width: 10),
        _buildColorOptionItem(context, ref, ThemeColorOption.yellow, const Color(0xFFFFCC00), "", selectedColor == ThemeColorOption.yellow),
        const SizedBox(width: 10),
        _buildColorOptionItem(context, ref, ThemeColorOption.green, const Color(0xFF34C759), "", selectedColor == ThemeColorOption.green),
      ],
    );

    Widget themeContent;
    if (isMobile) {
      themeContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: colorSelectionRow,
          ),
        ],
      );
    } else {
      themeContent = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Color',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          colorSelectionRow,
        ],
      );
    }

    Widget content = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.only(
          top: 24.0,
          bottom: 90,
          left: 16.0,
          right: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Appearance",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Customize how HelloAltr displays layout layers on your viewport workspace canvas.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  appearanceContent,
                  Divider(
                    height: 32,
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                  themeContent,
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              ref.read(activeSettingsPanelProvider.notifier).state =
                  SettingsPanelType.none;
            },
          ),
          title: Text(
            'Appearance',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(child: SingleChildScrollView(child: content)),
      );
    }

    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(child: content)),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required ThemeMode mode,
    required String label,
    required bool isSelected,
    required ThemeColorOption selectedColor,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemePreview(
            context,
            mode: mode,
            isSelected: isSelected,
            selectedColor: selectedColor,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOptionItem(
    BuildContext context,
    WidgetRef ref,
    ThemeColorOption option,
    Color color,
    String label,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        ref.read(themeColorOptionProvider.notifier).setThemeColor(option);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2.0)
                  : null,
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : (label.isEmpty ? Colors.transparent : theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreview(
    BuildContext context, {
    required ThemeMode mode,
    required bool isSelected,
    required ThemeColorOption selectedColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 120,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withAlpha(80),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: mode == ThemeMode.system
            ? Row(
                children: [
                  Expanded(child: _buildWindowContent(context, isDark: false, isSplit: true, selectedColor: selectedColor)),
                  Expanded(child: _buildWindowContent(context, isDark: true, isSplit: true, selectedColor: selectedColor)),
                ],
              )
            : _buildWindowContent(context, isDark: mode == ThemeMode.dark, isSplit: false, selectedColor: selectedColor),
      ),
    );
  }

  Widget _buildWindowContent(
    BuildContext context, {
    required bool isDark,
    required bool isSplit,
    required ThemeColorOption selectedColor,
  }) {
    final seedColor = MaterialTheme.getSeedColor(selectedColor);
    final hsl = HSLColor.fromColor(seedColor);

    final lightWallpaper = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        hsl.withLightness(0.92).withSaturation(0.85).toColor(),
        hsl.withLightness(0.72).withSaturation(0.90).toColor(),
        hsl.withLightness(0.48).withSaturation(0.90).toColor(),
      ],
    );

    final darkWallpaper = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        hsl.withLightness(0.22).withSaturation(0.45).toColor(),
        hsl.withLightness(0.12).withSaturation(0.55).toColor(),
        hsl.withLightness(0.06).withSaturation(0.65).toColor(),
      ],
    );

    final wallpaper = isDark ? darkWallpaper : lightWallpaper;
    final panelColor = isDark
        ? const Color(0xFF0F172A).withAlpha(200)
        : const Color(0xFFF1F5F9).withAlpha(200);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: wallpaper,
      ),
      child: Stack(
        children: [
          // Top Panel / Menu Bar representation
          Positioned(
            top: 4,
            left: 4,
            right: 4,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.centerLeft,
              child: Container(
                width: isSplit ? 10 : 16,
                height: 2,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          // Content Card / App Window body representation
          Positioned(
            bottom: 0,
            right: 0,
            left: isSplit ? 4 : 8,
            top: 18,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 2,
                    offset: const Offset(-1, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(left: 3, top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Red, Yellow, Green window dots
                  _buildDot(const Color(0xFFFF5F56)),
                  const SizedBox(width: 2),
                  _buildDot(const Color(0xFFFFBD2E)),
                  const SizedBox(width: 2),
                  _buildDot(const Color(0xFF27C93F)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
