// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/section_header.dart';
import 'package:chat/widgets/action_button.dart';
import 'package:chat/widgets/details_row.dart';

// Providers & Layout
import 'package:chat/repositories/chat_repository.dart';
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/layout_provider.dart';
import 'package:chat/providers/auth_provider.dart';

// Models
import 'package:chat/models/user_model.dart';

// Enums
import 'package:chat/enums/layout_mode.dart';

class ProfileCardInspector extends ConsumerStatefulWidget {
  const ProfileCardInspector({super.key});

  @override
  ConsumerState<ProfileCardInspector> createState() =>
      _ProfileCardInspectorState();
}

class _ProfileCardInspectorState extends ConsumerState<ProfileCardInspector> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;

    final currentUser = FirebaseAuth.instance.currentUser;
    final targetUserId = ref.watch(profileTargetUserIdProvider);
    final isMe = targetUserId == null || targetUserId == (currentUser?.uid ?? '');

    final AltrUser? profileUser;
    if (isMe) {
      profileUser = ref.watch(userProfileProvider).value;
    } else {
      profileUser = ref.watch(userProfileByIdProvider(targetUserId)).value;
    }

    final displayName =
        profileUser?.displayName ?? (isMe ? (currentUser?.displayName ?? 'Aero User') : 'Aero User');
    final emailId =
        profileUser?.emailId ?? (isMe ? (currentUser?.email ?? 'user@helloaltr.com') : 'user@helloaltr.com');
    final photoUrl = profileUser?.photoUrl.isNotEmpty == true
        ? profileUser!.photoUrl
        : (isMe ? currentUser?.photoURL : null);
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'A';
    final usernameHandle =
        profileUser?.userName != null && profileUser!.userName.isNotEmpty
        ? '@${profileUser.userName}'
        : (isMe && currentUser?.email != null
              ? '@${currentUser!.email!.split("@")[0]}'
              : '@aero_user');



    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(activeSettingsPanelProvider.notifier).state = SettingsPanelType.none;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: isMobile
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () {
                    ref.read(activeSettingsPanelProvider.notifier).state =
                        SettingsPanelType.none;
                  },
                )
              : null,
          title: Text(
            isMe ? 'Profile' : 'User Profile',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (!isMobile)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(activeSettingsPanelProvider.notifier).state =
                      SettingsPanelType.none;
                },
              ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
                        if (isMe) ...[
                          Expanded(
                            child: ActionButton(
                              icon: HugeIconsStroke.image02,
                              label: 'Change Photo',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ActionButton(
                              icon: HugeIconsStroke.edit01,
                              label: 'Edit Info',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ActionButton(
                            icon: HugeIconsStroke.share01,
                            label: 'Share Profile',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
  
                    // Details Card
                    const SectionHeader(title: 'Profile Details', fontSize: 11.0),
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
                          DetailsRow(
                            icon: HugeIconsStroke.mail01,
                            label: 'Email ID',
                            value: emailId,
                          ),
                          Divider(
                            height: 24,
                            color: theme.colorScheme.outlineVariant.withAlpha(80),
                          ),
                          const DetailsRow(
                            icon: HugeIconsStroke.taskDone01,
                            label: 'Bio',
                            value:
                                'Building the future of agent-first real-time chat communication on HelloAltr.',
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
