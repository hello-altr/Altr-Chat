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

class DmModel {
  final String userName;
  final String lastMessage;
  final String time;
  final int unreadCount;

  const DmModel({
    required this.userName,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
  });
}

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

class DirectMessagesList extends ConsumerWidget {
  const DirectMessagesList({super.key});

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
                'Direct Messages',
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
                    hintText: 'Search chats...',
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
                  itemCount: mockDms.length,
                  itemBuilder: (context, index) {
                    final dm = mockDms[index];
                    final isSelected = activeChatId == dm.userName;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: InkWell(
                        onTap: () {
                          // Set active chat ID
                          ref.read(activeChatIdProvider.notifier).state = dm.userName;
                          ref.read(isProfileActiveInSettingsDesktopProvider.notifier).state = false;

                          if (layoutMode == LayoutMode.mobile) {
                            // On Mobile, navigate to ChatPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  chatId: dm.userName,
                                  isChannel: false,
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
                              // Circular Avatar or Capitalized Initials
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: getInitialsBgColor(dm.userName),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(10),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  dm.userName.substring(0, 1).toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Display Name and Last Message
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
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
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          dm.time,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                                          ),
                                        ),
                                      ],
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
                              // Unread Badges
                              if (dm.unreadCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${dm.unreadCount}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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

class DmsStageView extends StatelessWidget {
  const DmsStageView({super.key});

  @override
  Widget build(BuildContext context) {
    return const DirectMessagesList();
  }
}
