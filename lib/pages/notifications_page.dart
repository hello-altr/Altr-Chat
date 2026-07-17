// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Widgets
import 'package:chat/widgets/notification_card.dart';
import 'package:chat/widgets/filter_chip.dart';
import 'package:chat/widgets/empty_state.dart';

// Providers & Layout
import 'package:chat/providers/settings_provider.dart';
import 'package:chat/providers/layout_provider.dart';

// Services
import 'package:chat/services/filter_notifications.dart';

// Enums and Values
import 'package:chat/enums/layout_mode.dart';

// Dummy Data
import 'package:chat/dummy_data.dart';

class NotificationsPanelPage extends ConsumerStatefulWidget {
  const NotificationsPanelPage({super.key});

  @override
  ConsumerState<NotificationsPanelPage> createState() => _NotificationsPanelPageState();
}

class _NotificationsPanelPageState extends ConsumerState<NotificationsPanelPage> {
  String selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ref.watch(layoutProvider) == LayoutMode.mobile;

    final filteredNotifs = getFilteredNotifications(
      mockNotifications,
      selectedFilter,
    );

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
          title: const Text(
            'Notifications',
            style: TextStyle(
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
                  top: 16.0,
                  bottom: 90,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SettingsFilterChip(
                          label: 'All',
                          isSelected: selectedFilter == 'all',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                selectedFilter = 'all';
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        SettingsFilterChip(
                          label: 'Mentions',
                          isSelected: selectedFilter == 'mentions',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                selectedFilter = 'mentions';
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        SettingsFilterChip(
                          label: 'Registrations',
                          isSelected: selectedFilter == 'registrations',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                selectedFilter = 'registrations';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

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
                                    NotificationCard(notification: notif),
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
      ),
    );
  }
}
